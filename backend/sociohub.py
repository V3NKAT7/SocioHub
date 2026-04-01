"""
sociohub.py
===========
Core business logic for SocioHub Investment Analytics.

All database query functions live here. Each function accepts a SQLAlchemy
Session and the relevant filters, and returns plain Python dicts / lists.
The router file imports these functions and calls them inside GET endpoints.

Tables used (from the existing Postgres schema — NOT imported here):
  broker_credentials    → deposited_funds, available_balance, utilized_margin
  user_margins          → available_margin
  broker_pnl_snapshots  → realized_pnl, unrealized_pnl, total_pnl (per broker per day)
  daily_pnl_summary     → aggregated daily totals, monthly rollup
  position_tracker      → open/active trades
  trade_metrics         → risk_percentage, kelly_percentage, expected_value
  live_feed_data        → ltp (current market price for open positions)
"""

import os
from datetime import date, timedelta
from typing import Optional

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session

# ─── Database setup ───────────────────────────────────────────────────────────

DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://postgres:password@localhost:5432/your_db_name",
)
engine       = create_engine(DATABASE_URL, pool_pre_ping=True)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def get_db():
    """FastAPI dependency — yields a DB session and closes it after the request."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


# ─── Helpers ──────────────────────────────────────────────────────────────────

MONTH_LABELS = {
    1: "Jan", 2: "Feb",  3: "Mar", 4: "Apr",
    5: "May", 6: "Jun",  7: "Jul", 8: "Aug",
    9: "Sep", 10: "Oct", 11: "Nov", 12: "Dec",
}


def _normalise(values: list[float]) -> list[float]:
    """Normalise a list to [0, 1] for sparkline charts."""
    if not values:
        return []
    mn, mx = min(values), max(values)
    if mx == mn:
        return [0.5] * len(values)
    return [round((v - mn) / (mx - mn), 4) for v in values]


def _risk_label(pct: Optional[float]) -> str:
    """Convert a raw risk % into a LOW / MEDIUM / HIGH label."""
    if pct is None:
        return "UNKNOWN"
    if pct < 1.5:
        return "LOW"
    if pct < 3.5:
        return "MEDIUM"
    return "HIGH"


def _date_range(period: str, start_date=None, end_date=None):
    """Return (from_date, to_date) based on the period string."""
    today = date.today()
    if period == "last_7d":
        return today - timedelta(days=6), today
    if period == "last_month":
        return today - timedelta(days=29), today
    if period == "custom" and start_date and end_date:
        return start_date, end_date
    return today - timedelta(days=6), today  # default fallback


def _pad(lst: list, length: int = 7, fill: float = 0.0) -> list:
    """Left-pad a list with `fill` until it reaches `length`."""
    while len(lst) < length:
        lst.insert(0, fill)
    return lst


# ─── 1. Invested Capital ──────────────────────────────────────────────────────

def get_invested_capital(db: Session, user_id: int) -> dict:
    """
    Total capital deployed across all active broker accounts.

    Source: broker_credentials
      - deposited_funds   → total capital deposited by the user
      - available_balance → cash not currently in any position
      - utilized_margin   → margin currently consumed by open positions

    Source: user_margins
      - available_margin  → live margin available from broker APIs
    """
    cap = db.execute(text("""
        SELECT
            COALESCE(SUM(deposited_funds),   0) AS total_invested_capital,
            COALESCE(SUM(available_balance), 0) AS current_available,
            COALESCE(SUM(utilized_margin),   0) AS utilized_margin,
            COUNT(*)                            AS broker_account_count
        FROM broker_credentials
        WHERE user_id  = :uid
          AND is_active = true
          AND enabled   = true
    """), {"uid": user_id}).fetchone()

    mgn = db.execute(text("""
        SELECT COALESCE(SUM(available_margin), 0) AS available_margin
        FROM user_margins
        WHERE user_id = :uid
    """), {"uid": user_id}).fetchone()

    return {
        "total_invested_capital": round(float(cap.total_invested_capital), 2),
        "current_available":      round(float(cap.current_available),      2),
        "utilized_margin":        round(float(cap.utilized_margin),        2),
        "available_margin":       round(float(mgn.available_margin),       2),
        "broker_account_count":   int(cap.broker_account_count),
    }


# ─── 2. Realised P&L ─────────────────────────────────────────────────────────

def get_realised_pnl(db: Session, user_id: int, target_date: date = None) -> dict:
    """
    Realised profit/loss for a given day (default: today).

    Source: broker_pnl_snapshots
      - realized_pnl   → P&L from positions that were fully closed
      - closed_positions → number of trades squared off

    Source: daily_pnl_summary (cross-check / commission info)
      - commission_due → commission owed based on realized P&L
    """
    query_date = target_date or date.today()

    snap = db.execute(text("""
        SELECT
            COALESCE(SUM(realized_pnl),    0) AS realized_pnl,
            COALESCE(SUM(closed_positions),0) AS closed_positions,
            COALESCE(SUM(trading_funds),   0) AS trading_funds
        FROM broker_pnl_snapshots
        WHERE user_id = :uid
          AND date    = :d
    """), {"uid": user_id, "d": query_date}).fetchone()

    daily = db.execute(text("""
        SELECT
            COALESCE(commission_due,  0) AS commission_due,
            COALESCE(commission_paid, 0) AS commission_paid
        FROM daily_pnl_summary
        WHERE user_id = :uid
          AND date    = :d
        LIMIT 1
    """), {"uid": user_id, "d": query_date}).fetchone()

    return {
        "date":              str(query_date),
        "realized_pnl":      round(float(snap.realized_pnl),    2),
        "closed_positions":  int(snap.closed_positions),
        "trading_funds":     round(float(snap.trading_funds),   2),
        "commission_due":    round(float(daily.commission_due  if daily else 0), 2),
        "commission_paid":   round(float(daily.commission_paid if daily else 0), 2),
    }


# ─── 3. Unrealised P&L ───────────────────────────────────────────────────────

def get_unrealised_pnl(db: Session, user_id: int) -> dict:
    """
    Unrealised P&L from all currently open positions.

    Source: broker_pnl_snapshots (latest snapshot today)
      - unrealized_pnl  → mark-to-market loss/gain on open positions
      - open_positions  → count of trades still live

    Cross-referenced with position_tracker for live LTP from live_feed_data.
    """
    today = date.today()

    snap = db.execute(text("""
        SELECT
            COALESCE(SUM(unrealized_pnl), 0) AS unrealized_pnl,
            COALESCE(SUM(open_positions), 0) AS open_positions
        FROM broker_pnl_snapshots
        WHERE user_id = :uid
          AND date    = :d
    """), {"uid": user_id, "d": today}).fetchone()

    # Per-position live unrealized P&L using LTP from live_feed_data
    positions = db.execute(text("""
        SELECT
            pt.symbol,
            pt.exchange_symbol,
            pt.quantity,
            pt.entry_price,
            pt.pnl                AS snapshot_pnl,
            lfd.ltp               AS current_price,
            pt.strategy_tag,
            pt.broker_user_id
        FROM position_tracker pt
        LEFT JOIN live_feed_data lfd
               ON lfd.symbol = pt.exchange_symbol
        WHERE pt.user_id  = :uid
          AND pt.is_active = true
    """), {"uid": user_id}).fetchall()

    live_breakdown = []
    for p in positions:
        ltp      = float(p.current_price or 0)
        ep       = float(p.entry_price   or 0)
        qty      = float(p.quantity      or 0)
        live_pnl = (ltp - ep) * qty if ltp and ep else float(p.snapshot_pnl or 0)
        live_breakdown.append({
            "symbol":         p.symbol,
            "exchange_symbol": p.exchange_symbol,
            "strategy_tag":   p.strategy_tag,
            "broker_user_id": p.broker_user_id,
            "quantity":       qty,
            "entry_price":    round(ep,       2),
            "current_price":  round(ltp,      2),
            "unrealized_pnl": round(live_pnl, 2),
        })

    return {
        "total_unrealized_pnl": round(float(snap.unrealized_pnl), 2),
        "open_positions":        int(snap.open_positions),
        "live_breakdown":        live_breakdown,
    }


# ─── 4. Total Profit ─────────────────────────────────────────────────────────

def get_total_profit(db: Session, user_id: int) -> dict:
    """
    Combined realized + unrealized P&L, with ROI calculation.

    Source: broker_pnl_snapshots (today's latest)
    Derived:
      roi_percent = total_profit / total_invested_capital × 100
    """
    today = date.today()

    pnl = db.execute(text("""
        SELECT
            COALESCE(SUM(realized_pnl),   0) AS realized_pnl,
            COALESCE(SUM(unrealized_pnl), 0) AS unrealized_pnl,
            COALESCE(SUM(total_pnl),      0) AS total_pnl
        FROM broker_pnl_snapshots
        WHERE user_id = :uid
          AND date    = :d
    """), {"uid": user_id, "d": today}).fetchone()

    cap = db.execute(text("""
        SELECT COALESCE(SUM(deposited_funds), 0) AS invested
        FROM broker_credentials
        WHERE user_id  = :uid
          AND is_active = true
          AND enabled   = true
    """), {"uid": user_id}).fetchone()

    invested     = float(cap.invested or 0)
    total_profit = float(pnl.total_pnl or 0)
    roi_pct      = (total_profit / invested * 100) if invested > 0 else 0.0

    return {
        "realized_pnl":   round(float(pnl.realized_pnl),   2),
        "unrealized_pnl": round(float(pnl.unrealized_pnl), 2),
        "total_profit":   round(total_profit,               2),
        "invested":       round(invested,                   2),
        "roi_percent":    round(roi_pct,                    2),
    }


# ─── 5. Active Trades ────────────────────────────────────────────────────────

def get_active_trades(db: Session, user_id: int) -> dict:
    """
    All currently open positions with live LTP from live_feed_data.

    Source: position_tracker (is_active = true)
    Joined: live_feed_data for current market price
    """
    rows = db.execute(text("""
        SELECT
            pt.id,
            pt.broker_user_id,
            pt.symbol,
            pt.exchange_symbol,
            pt.option_type,
            pt.quantity,
            pt.entry_price,
            pt.pnl              AS snapshot_pnl,
            pt.strategy_tag,
            pt.entry_time::text AS entry_time,
            lfd.ltp             AS current_price
        FROM position_tracker pt
        LEFT JOIN live_feed_data lfd
               ON lfd.symbol = pt.exchange_symbol
        WHERE pt.user_id  = :uid
          AND pt.is_active = true
        ORDER BY pt.entry_time DESC
    """), {"uid": user_id}).fetchall()

    trades = []
    for r in rows:
        ep    = float(r.entry_price   or 0)
        ltp   = float(r.current_price or 0)
        qty   = float(r.quantity      or 0)
        live_pnl = (ltp - ep) * qty if ltp and ep else float(r.snapshot_pnl or 0)
        trades.append({
            "id":              r.id,
            "broker_user_id":  r.broker_user_id,
            "symbol":          r.symbol,
            "exchange_symbol": r.exchange_symbol,
            "option_type":     r.option_type,
            "quantity":        qty,
            "entry_price":     round(ep, 2),
            "current_price":   round(ltp, 2),
            "unrealized_pnl":  round(live_pnl, 2),
            "strategy_tag":    r.strategy_tag,
            "entry_time":      r.entry_time,
        })

    return {
        "active_count": len(trades),
        "trades":       trades,
    }


# ─── 6. Total Risk Level ─────────────────────────────────────────────────────

def get_risk_summary(db: Session, user_id: int) -> dict:
    """
    Aggregated risk metrics from trade_metrics table.

    Source: trade_metrics
      - risk_percentage         → position risk as % of capital
      - total_risk_amount       → absolute ₹ at risk
      - kelly_percentage        → optimal position sizing (Kelly Criterion)
      - expected_value          → EV per trade
      - risk_adjusted_return    → return per unit of risk (Sharpe-like)
      - max_adverse_excursion   → worst intra-trade drawdown
      - max_favorable_excursion → best intra-trade move
    """
    row = db.execute(text("""
        SELECT
            AVG(risk_percentage)         AS avg_risk_pct,
            SUM(total_risk_amount)       AS total_risk_amount,
            AVG(kelly_percentage)        AS avg_kelly,
            AVG(expected_value)          AS avg_ev,
            AVG(risk_adjusted_return)    AS avg_rar,
            AVG(max_adverse_excursion)   AS avg_mae,
            AVG(max_favorable_excursion) AS avg_mfe,
            COUNT(*)                     AS record_count
        FROM trade_metrics
        WHERE user_id  = :uid
          AND is_active = true
    """), {"uid": user_id}).fetchone()

    if not row or not row.record_count:
        return {"risk_level": "UNKNOWN", "detail": "No active trade metrics found"}

    risk_pct = float(row.avg_risk_pct or 0)
    return {
        "risk_level":            _risk_label(risk_pct),
        "risk_percentage":       round(risk_pct,                        2),
        "total_risk_amount":     round(float(row.total_risk_amount or 0),2),
        "kelly_percentage":      round(float(row.avg_kelly or 0),       2),
        "expected_value":        round(float(row.avg_ev or 0),          2),
        "risk_adjusted_return":  round(float(row.avg_rar or 0),         2),
        "max_adverse_excursion": round(float(row.avg_mae or 0),         2),
        "max_favorable_excursion": round(float(row.avg_mfe or 0),       2),
    }


# ─── 7. Monthly Performance ──────────────────────────────────────────────────

def get_monthly_performance(db: Session, user_id: int, months: int = 12) -> dict:
    """
    Month-by-month P&L breakdown for the trailing N months.

    Source: daily_pnl_summary (GROUP BY year, month)
      - total_realized_pnl   → cumulative realized P&L in that month
      - total_unrealized_pnl → end-of-month unrealized P&L
      - total_open_positions / total_closed_positions

    Also returns:
      - best_month / worst_month labels
      - total_realized / total_unrealized across all months
    """
    rows = db.execute(text("""
        SELECT
            EXTRACT(YEAR  FROM date)::int  AS yr,
            EXTRACT(MONTH FROM date)::int  AS mo,
            SUM(total_realized_pnl)        AS realized_pnl,
            SUM(total_unrealized_pnl)      AS unrealized_pnl,
            SUM(total_pnl)                 AS total_pnl,
            SUM(total_closed_positions)    AS closed_positions,
            MAX(total_open_positions)      AS open_positions,
            SUM(commission_due)            AS commission_due
        FROM daily_pnl_summary
        WHERE user_id = :uid
          AND date   >= (CURRENT_DATE - (:months * INTERVAL '1 month'))
        GROUP BY yr, mo
        ORDER BY yr ASC, mo ASC
    """), {"uid": user_id, "months": months}).fetchall()

    data = [
        {
            "month":            MONTH_LABELS.get(r.mo, str(r.mo)),
            "year":             r.yr,
            "realized_pnl":     round(float(r.realized_pnl   or 0), 2),
            "unrealized_pnl":   round(float(r.unrealized_pnl or 0), 2),
            "total_pnl":        round(float(r.total_pnl       or 0), 2),
            "closed_positions": int(r.closed_positions or 0),
            "open_positions":   int(r.open_positions   or 0),
            "commission_due":   round(float(r.commission_due  or 0), 2),
        }
        for r in rows
    ]

    if not data:
        return {"data": [], "total_realized": 0.0, "total_unrealized": 0.0,
                "best_month": None, "worst_month": None}

    total_realized   = sum(d["realized_pnl"]   for d in data)
    total_unrealized = sum(d["unrealized_pnl"] for d in data)
    best  = max(data, key=lambda d: d["total_pnl"])
    worst = min(data, key=lambda d: d["total_pnl"])

    return {
        "data":             data,
        "total_realized":   round(total_realized,   2),
        "total_unrealized": round(total_unrealized, 2),
        "best_month":       f"{best['month']}  {best['year']}",
        "worst_month":      f"{worst['month']} {worst['year']}",
    }


# ─── 8. P&L History (Sparkline) ──────────────────────────────────────────────

def get_pnl_history(
    db: Session,
    user_id: int,
    period: str = "last_7d",
    start_date: Optional[date] = None,
    end_date:   Optional[date] = None,
) -> dict:
    """
    Daily P&L series for a given period — used to build sparkline charts
    (ROI line and Realised P&L line on the Investments screen).

    Source: broker_pnl_snapshots aggregated by date.
    Normalised roi_line and pnl_line are 0–1 arrays for Flutter charts.
    """
    from_date, to_date = _date_range(period, start_date, end_date)

    rows = db.execute(text("""
        SELECT
            date,
            SUM(realized_pnl)   AS realized_pnl,
            SUM(unrealized_pnl) AS unrealized_pnl,
            SUM(total_pnl)      AS total_pnl,
            SUM(available_margin) AS available_margin,
            SUM(utilized_margin)  AS utilized_margin
        FROM broker_pnl_snapshots
        WHERE user_id = :uid
          AND date BETWEEN :fd AND :td
        GROUP BY date
        ORDER BY date ASC
    """), {"uid": user_id, "fd": from_date, "td": to_date}).fetchall()

    data = [
        {
            "date":             str(r.date),
            "realized_pnl":     round(float(r.realized_pnl   or 0), 2),
            "unrealized_pnl":   round(float(r.unrealized_pnl or 0), 2),
            "total_pnl":        round(float(r.total_pnl       or 0), 2),
            "available_margin": round(float(r.available_margin or 0),2),
            "utilized_margin":  round(float(r.utilized_margin  or 0),2),
        }
        for r in rows
    ]

    roi_raw = _pad([d["total_pnl"]     for d in data])
    pnl_raw = _pad([d["realized_pnl"]  for d in data])

    return {
        "period":   period,
        "data":     data,
        "roi_line": _normalise(roi_raw),
        "pnl_line": _normalise(pnl_raw),
    }


# ─── 9. Investment Tracking (Full Dashboard Bundle) ──────────────────────────

def get_investment_tracking(
    db: Session,
    user_id: int,
    period: str = "last_7d",
    start_date: Optional[date] = None,
    end_date:   Optional[date] = None,
) -> dict:
    """
    Single composite function that bundles all 8 data points into one response.
    Called by GET /dashboard/summary to minimise Flutter round-trips.

    Returns:
      1. total_invested_capital   ← broker_credentials.deposited_funds
      2. current_available        ← broker_credentials.available_balance
      3. total_profit             ← realized_pnl + unrealized_pnl
      4. active_trades            ← position_tracker (is_active=True)
      5. total_risk_level         ← trade_metrics.risk_percentage → label
      6. realized_pnl             ← broker_pnl_snapshots (today)
      7. unrealized_pnl           ← broker_pnl_snapshots (today)
      8. monthly_performance      ← daily_pnl_summary (12 months)

    Plus derived:
      roi_percent, roi_line, pnl_line (sparklines), margin details
    """
    today = date.today()
    from_date, to_date = _date_range(period, start_date, end_date)

    # Capital
    cap = db.execute(text("""
        SELECT
            COALESCE(SUM(deposited_funds),   0) AS invested,
            COALESCE(SUM(available_balance), 0) AS available,
            COALESCE(SUM(utilized_margin),   0) AS utilized_margin
        FROM broker_credentials
        WHERE user_id = :uid AND is_active = true AND enabled = true
    """), {"uid": user_id}).fetchone()

    mgn = db.execute(text("""
        SELECT COALESCE(SUM(available_margin), 0) AS available_margin
        FROM user_margins WHERE user_id = :uid
    """), {"uid": user_id}).fetchone()

    # Today's P&L snapshot
    pnl = db.execute(text("""
        SELECT
            COALESCE(SUM(realized_pnl),   0) AS realized_pnl,
            COALESCE(SUM(unrealized_pnl), 0) AS unrealized_pnl,
            COALESCE(SUM(total_pnl),      0) AS total_pnl,
            COALESCE(SUM(open_positions), 0) AS open_positions,
            COALESCE(SUM(closed_positions),0) AS closed_positions
        FROM broker_pnl_snapshots
        WHERE user_id = :uid AND date = :d
    """), {"uid": user_id, "d": today}).fetchone()

    # Active trades
    at = db.execute(text("""
        SELECT COUNT(*) AS cnt FROM position_tracker
        WHERE user_id = :uid AND is_active = true
    """), {"uid": user_id}).fetchone()

    # Risk
    risk = db.execute(text("""
        SELECT
            AVG(risk_percentage)      AS avg_risk,
            AVG(kelly_percentage)     AS avg_kelly,
            AVG(expected_value)       AS avg_ev,
            AVG(risk_adjusted_return) AS avg_rar
        FROM trade_metrics
        WHERE user_id = :uid AND is_active = true
    """), {"uid": user_id}).fetchone()

    # Monthly performance (last 12 months)
    monthly_rows = db.execute(text("""
        SELECT
            EXTRACT(YEAR  FROM date)::int AS yr,
            EXTRACT(MONTH FROM date)::int AS mo,
            SUM(total_realized_pnl)       AS realized_pnl,
            SUM(total_unrealized_pnl)     AS unrealized_pnl,
            SUM(total_pnl)                AS total_pnl,
            SUM(total_closed_positions)   AS closed_positions,
            MAX(total_open_positions)     AS open_positions
        FROM daily_pnl_summary
        WHERE user_id = :uid
          AND date   >= (CURRENT_DATE - INTERVAL '12 months')
        GROUP BY yr, mo ORDER BY yr, mo
    """), {"uid": user_id}).fetchall()

    monthly_performance = [
        {
            "month":            MONTH_LABELS.get(r.mo, str(r.mo)),
            "year":             r.yr,
            "realized_pnl":     round(float(r.realized_pnl   or 0), 2),
            "unrealized_pnl":   round(float(r.unrealized_pnl or 0), 2),
            "total_pnl":        round(float(r.total_pnl       or 0), 2),
            "open_positions":   int(r.open_positions   or 0),
            "closed_positions": int(r.closed_positions or 0),
        }
        for r in monthly_rows
    ]

    # Sparkline (period-based)
    spark_rows = db.execute(text("""
        SELECT date,
               SUM(total_realized_pnl)    AS realized_pnl,
               SUM(total_pnl)             AS total_pnl
        FROM daily_pnl_summary
        WHERE user_id = :uid AND date BETWEEN :fd AND :td
        GROUP BY date ORDER BY date
    """), {"uid": user_id, "fd": from_date, "td": to_date}).fetchall()

    roi_raw = _pad([float(r.total_pnl    or 0) for r in spark_rows])
    pnl_raw = _pad([float(r.realized_pnl or 0) for r in spark_rows])

    invested     = float(cap.invested or 0)
    total_profit = float(pnl.total_pnl or 0)
    risk_pct     = float(risk.avg_risk or 0)

    return {
        # ── Core 8 data points ────────────────────────────────────────────────
        "total_invested_capital":  round(invested,                     2),
        "current_available":       round(float(cap.available),         2),
        "total_profit":            round(total_profit,                  2),
        "active_trades":           int(at.cnt or 0),
        "total_risk_level":        _risk_label(risk_pct),
        "realized_pnl":            round(float(pnl.realized_pnl),      2),
        "unrealized_pnl":          round(float(pnl.unrealized_pnl),    2),
        "monthly_performance":     monthly_performance,

        # ── Derived metrics ────────────────────────────────────────────────────
        "roi_percent":             round((total_profit / invested * 100) if invested else 0, 2),
        "utilized_margin":         round(float(cap.utilized_margin),    2),
        "available_margin":        round(float(mgn.available_margin),   2),
        "open_positions_today":    int(pnl.open_positions),
        "closed_positions_today":  int(pnl.closed_positions),
        "risk_percentage":         round(risk_pct,                      2),
        "kelly_percentage":        round(float(risk.avg_kelly or 0),    2),
        "expected_value":          round(float(risk.avg_ev    or 0),    2),
        "risk_adjusted_return":    round(float(risk.avg_rar   or 0),    2),
        "period":                  period,

        # ── Sparklines (0–1 normalised arrays for Flutter line charts) ─────────
        "roi_line": _normalise(roi_raw),
        "pnl_line": _normalise(pnl_raw),
    }
