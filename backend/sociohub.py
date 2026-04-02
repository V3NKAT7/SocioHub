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


# =============================================================================
# AUTH MODULE
# =============================================================================
import uuid
import secrets
from datetime import datetime, timedelta

from sqlalchemy import Column, String, Integer, DateTime, Boolean, Float
from sqlalchemy.orm import declarative_base
from passlib.context import CryptContext
from jose import JWTError, jwt

Base = declarative_base()

# ─── JWT / Password config ────────────────────────────────────────────────────
JWT_SECRET          = os.getenv("JWT_SECRET", "change-me")
JWT_ALGORITHM       = os.getenv("JWT_ALGORITHM", "HS256")
JWT_EXPIRE_MINUTES  = int(os.getenv("JWT_EXPIRE_MINUTES", 1440))

pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


# ─── ORM Models (auto-created by create_all on startup) ──────────────────────

class User(Base):
    __tablename__ = "sh_users"
    id             = Column(Integer, primary_key=True, index=True)
    email          = Column(String, unique=True, nullable=False, index=True)
    hashed_password= Column(String, nullable=False)
    referral_code  = Column(String, unique=True, nullable=False)
    is_active      = Column(Boolean, default=True)
    created_at     = Column(DateTime, default=datetime.utcnow)


class Referral(Base):
    __tablename__ = "sh_referrals"
    id             = Column(Integer, primary_key=True, index=True)
    referrer_id    = Column(Integer, nullable=False)       # FK → sh_users.id
    referred_email = Column(String, nullable=False)
    signed_up_at   = Column(DateTime, nullable=True)
    reward_amount  = Column(Float, default=0.0)
    is_paid        = Column(Boolean, default=False)


def create_tables():
    """Call this once on startup to create sh_users and sh_referrals tables."""
    Base.metadata.create_all(bind=engine)


# ─── Auth Helpers ─────────────────────────────────────────────────────────────

def _hash_password(plain: str) -> str:
    return pwd_ctx.hash(plain)


def _verify_password(plain: str, hashed: str) -> bool:
    return pwd_ctx.verify(plain, hashed)


def _make_token(user_id: int, email: str) -> str:
    expire = datetime.utcnow() + timedelta(minutes=JWT_EXPIRE_MINUTES)
    payload = {"sub": str(user_id), "email": email, "exp": expire}
    return jwt.encode(payload, JWT_SECRET, algorithm=JWT_ALGORITHM)


def decode_token(token: str) -> dict:
    """Raises JWTError on invalid/expired token."""
    return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])


# ─── Auth Business Logic ──────────────────────────────────────────────────────

def login_user(db: Session, email: str, password: str) -> dict:
    """
    POST /auth/login
    Verifies credentials and returns a JWT access token.
    Raises ValueError on bad credentials.
    """
    row = db.execute(
        text("SELECT id, email, hashed_password FROM sh_users WHERE email = :e AND is_active = true"),
        {"e": email},
    ).fetchone()

    if not row or not _verify_password(password, row.hashed_password):
        raise ValueError("Invalid email or password")

    token = _make_token(row.id, row.email)
    return {
        "access_token": token,
        "token_type":   "bearer",
        "user_id":      row.id,
        "email":        row.email,
    }


def forgot_password(db: Session, email: str) -> dict:
    """
    POST /auth/forgot-password
    Generates a password-reset token and (in production) would email it.
    Returns the token directly for now — wire to an email service later.
    """
    row = db.execute(
        text("SELECT id FROM sh_users WHERE email = :e"),
        {"e": email},
    ).fetchone()

    # Always return success to prevent email enumeration attacks
    if not row:
        return {"message": "If that email exists, a reset link has been sent."}

    reset_token = secrets.token_urlsafe(32)
    # TODO: Store reset_token in DB with expiry + send via email (SendGrid / SES)
    return {
        "message":     "If that email exists, a reset link has been sent.",
        "debug_token": reset_token,   # Remove this line in production!
    }


# =============================================================================
# SOCIAL MODULE  (MongoDB)
# =============================================================================
from pymongo import MongoClient, DESCENDING

MONGO_URI     = os.getenv("MONGO_URI",     "mongodb://localhost:27017")
MONGO_DB_NAME = os.getenv("MONGO_DB_NAME", "sociohub_social")

_mongo_client: MongoClient | None = None


def get_mongo_db():
    """Returns the MongoDB database instance (singleton client)."""
    global _mongo_client
    if _mongo_client is None:
        _mongo_client = MongoClient(MONGO_URI)
    return _mongo_client[MONGO_DB_NAME]


def _seed_templates_if_empty(db):
    """Seeds default financial story templates if the collection is empty."""
    if db["templates"].count_documents({}) == 0:
        db["templates"].insert_many([
            {
                "id": "tmpl_1",
                "title": "Portfolio Milestone",
                "description": "Share when your portfolio hits a new high.",
                "icon": "trending_up",
                "color": "#10B981",
                "fields": ["milestone_amount", "percentage_gain"],
            },
            {
                "id": "tmpl_2",
                "title": "Trade of the Day",
                "description": "Highlight your best trade from today.",
                "icon": "bolt",
                "color": "#F59E0B",
                "fields": ["symbol", "entry_price", "exit_price", "pnl"],
            },
            {
                "id": "tmpl_3",
                "title": "Market Insight",
                "description": "Share your view on a market sector.",
                "icon": "insights",
                "color": "#6366F1",
                "fields": ["sector", "sentiment", "reasoning"],
            },
        ])


# ─── Social Business Logic ────────────────────────────────────────────────────

def get_social_feed(page: int = 1, page_size: int = 20) -> dict:
    """
    GET /social/feed
    Fetches a paginated list of financial stories from MongoDB.
    """
    mdb   = get_mongo_db()
    skip  = (page - 1) * page_size
    total = mdb["feed"].count_documents({})
    posts = list(
        mdb["feed"]
        .find({}, {"_id": 0})
        .sort("created_at", DESCENDING)
        .skip(skip)
        .limit(page_size)
    )
    return {
        "page":       page,
        "page_size":  page_size,
        "total":      total,
        "has_more":   (skip + page_size) < total,
        "posts":      posts,
    }


def toggle_like(story_id: str, user_id: int) -> dict:
    """
    POST /social/likes
    Toggles a like atomically. Returns new like count and liked status.
    """
    mdb  = get_mongo_db()
    post = mdb["feed"].find_one({"story_id": story_id}, {"_id": 0, "liked_by": 1, "likes": 1})

    if not post:
        raise ValueError(f"Story {story_id} not found")

    liked_by: list = post.get("liked_by", [])
    if user_id in liked_by:
        # Unlike
        mdb["feed"].update_one(
            {"story_id": story_id},
            {"$pull": {"liked_by": user_id}, "$inc": {"likes": -1}},
        )
        return {"story_id": story_id, "liked": False, "likes": max(0, post.get("likes", 1) - 1)}
    else:
        # Like
        mdb["feed"].update_one(
            {"story_id": story_id},
            {"$addToSet": {"liked_by": user_id}, "$inc": {"likes": 1}},
        )
        return {"story_id": story_id, "liked": True, "likes": post.get("likes", 0) + 1}


def record_share(story_id: str, platform: str, user_id: int) -> dict:
    """
    POST /social/shares
    Increments the share count and logs which platform the story was shared to.
    """
    mdb = get_mongo_db()
    result = mdb["feed"].update_one(
        {"story_id": story_id},
        {
            "$inc": {"shares": 1},
            "$push": {
                "share_log": {
                    "user_id":  user_id,
                    "platform": platform,
                    "shared_at": datetime.utcnow().isoformat(),
                }
            },
        },
    )
    if result.matched_count == 0:
        raise ValueError(f"Story {story_id} not found")
    return {"story_id": story_id, "platform": platform, "recorded": True}


def get_story_templates() -> dict:
    """
    GET /social/templates
    Returns all financial story templates. Seeds defaults if empty.
    """
    mdb = get_mongo_db()
    _seed_templates_if_empty(mdb)
    templates = list(mdb["templates"].find({}, {"_id": 0}))
    return {"templates": templates}


# =============================================================================
# REFERRAL MODULE  (PostgreSQL)
# =============================================================================

def get_my_referral_link(db: Session, user_id: int) -> dict:
    """
    GET /referrals/my-link
    Returns the authenticated user's unique referral link.
    """
    row = db.execute(
        text("SELECT referral_code, email FROM sh_users WHERE id = :uid"),
        {"uid": user_id},
    ).fetchone()

    if not row:
        raise ValueError("User not found")

    base_url = os.getenv("BACKEND_URL", "http://192.168.1.139:8000")
    return {
        "referral_code": row.referral_code,
        "referral_link": f"{base_url}/join?ref={row.referral_code}",
        "share_message": f"Join me on SocioHub and grow your financial footprint! Use my link: {base_url}/join?ref={row.referral_code}",
    }


def get_referral_rewards(db: Session, user_id: int) -> dict:
    """
    GET /referrals/rewards
    Fetches the user's earned rewards and pending referral status.
    """
    rows = db.execute(
        text("""
            SELECT
                COUNT(*)                                     AS total_referrals,
                COUNT(*) FILTER (WHERE signed_up_at IS NOT NULL) AS successful_referrals,
                COUNT(*) FILTER (WHERE signed_up_at IS NULL)     AS pending_referrals,
                COALESCE(SUM(reward_amount) FILTER (WHERE is_paid = true),  0) AS total_earned,
                COALESCE(SUM(reward_amount) FILTER (WHERE is_paid = false AND signed_up_at IS NOT NULL), 0) AS pending_payout
            FROM sh_referrals
            WHERE referrer_id = :uid
        """),
        {"uid": user_id},
    ).fetchone()

    recent = db.execute(
        text("""
            SELECT referred_email, signed_up_at, reward_amount, is_paid
            FROM sh_referrals
            WHERE referrer_id = :uid
            ORDER BY id DESC
            LIMIT 10
        """),
        {"uid": user_id},
    ).fetchall()

    return {
        "total_referrals":      int(rows.total_referrals or 0),
        "successful_referrals": int(rows.successful_referrals or 0),
        "pending_referrals":    int(rows.pending_referrals or 0),
        "total_earned":         round(float(rows.total_earned or 0),   2),
        "pending_payout":       round(float(rows.pending_payout or 0), 2),
        "recent_referrals": [
            {
                "email":        r.referred_email,
                "signed_up":    str(r.signed_up_at) if r.signed_up_at else None,
                "reward":       float(r.reward_amount or 0),
                "is_paid":      r.is_paid,
            }
            for r in recent
        ],
    }

