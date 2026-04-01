"""
routers.py
==========
GET endpoints for the SocioHub Analytics API.

All business logic is delegated to sociohub.py.
This file contains ONLY route definitions and request validation.

Base prefix: /api/v1
Interactive docs: http://localhost:8000/docs
"""

from fastapi import APIRouter, Depends, Query
from datetime import date
from typing import Optional
from sqlalchemy.orm import Session

from sociohub import (
    get_db,
    get_invested_capital,
    get_realised_pnl,
    get_unrealised_pnl,
    get_total_profit,
    get_active_trades,
    get_risk_summary,
    get_monthly_performance,
    get_pnl_history,
    get_investment_tracking,
)

router = APIRouter(prefix="/api/v1")


# ─── Invested Capital ─────────────────────────────────────────────────────────

@router.get(
    "/investments/capital",
    summary="Invested Capital",
    description=(
        "Returns total capital deployed across all active broker accounts. "
        "Source: `broker_credentials.deposited_funds` + `user_margins.available_margin`."
    ),
)
def invested_capital(
    user_id: int = Query(..., description="Portfolio Owner user_id"),
    db: Session  = Depends(get_db),
):
    return get_invested_capital(db, user_id)


# ─── Realised P&L ─────────────────────────────────────────────────────────────

@router.get(
    "/investments/realised-pnl",
    summary="Realised P&L",
    description=(
        "Realised profit/loss and closed position count for a given date. "
        "Source: `broker_pnl_snapshots.realized_pnl` + `daily_pnl_summary.commission_due`."
    ),
)
def realised_pnl(
    user_id:     int           = Query(..., description="Portfolio Owner user_id"),
    target_date: Optional[date]= Query(None, description="Date (YYYY-MM-DD). Defaults to today"),
    db: Session                = Depends(get_db),
):
    return get_realised_pnl(db, user_id, target_date)


# ─── Unrealised P&L ──────────────────────────────────────────────────────────

@router.get(
    "/investments/unrealised-pnl",
    summary="Unrealised P&L",
    description=(
        "Mark-to-market P&L on all currently open positions. "
        "Source: `broker_pnl_snapshots.unrealized_pnl` cross-referenced "
        "with live LTP from `live_feed_data`."
    ),
)
def unrealised_pnl(
    user_id: int = Query(..., description="Portfolio Owner user_id"),
    db: Session  = Depends(get_db),
):
    return get_unrealised_pnl(db, user_id)


# ─── Total Profit ─────────────────────────────────────────────────────────────

@router.get(
    "/investments/total-profit",
    summary="Total Profit",
    description=(
        "Combined realized + unrealized P&L with ROI %. "
        "Source: `broker_pnl_snapshots` today + `broker_credentials.deposited_funds`."
    ),
)
def total_profit(
    user_id: int = Query(..., description="Portfolio Owner user_id"),
    db: Session  = Depends(get_db),
):
    return get_total_profit(db, user_id)


# ─── Active Trades ────────────────────────────────────────────────────────────

@router.get(
    "/investments/active-trades",
    summary="Active Trades",
    description=(
        "All currently open positions with live prices and P&L. "
        "Source: `position_tracker` (is_active=true) joined with `live_feed_data`."
    ),
)
def active_trades(
    user_id: int = Query(..., description="Portfolio Owner user_id"),
    db: Session  = Depends(get_db),
):
    return get_active_trades(db, user_id)


# ─── Risk Summary ────────────────────────────────────────────────────────────

@router.get(
    "/investments/risk",
    summary="Total Risk Level",
    description=(
        "Aggregated risk metrics: risk level (LOW/MEDIUM/HIGH), Kelly %, expected value, "
        "risk-adjusted return, MAE, MFE. Source: `trade_metrics`."
    ),
)
def risk_summary(
    user_id: int = Query(..., description="Portfolio Owner user_id"),
    db: Session  = Depends(get_db),
):
    return get_risk_summary(db, user_id)


# ─── Monthly Performance ──────────────────────────────────────────────────────

@router.get(
    "/analytics/monthly-performance",
    summary="Monthly Performance",
    description=(
        "Month-by-month P&L breakdown for the trailing N months. "
        "Source: `daily_pnl_summary` grouped by calendar month. "
        "Includes best/worst month labels and totals."
    ),
)
def monthly_performance(
    user_id: int = Query(..., description="Portfolio Owner user_id"),
    months:  int = Query(12, ge=1, le=24, description="How many past months to include"),
    db: Session  = Depends(get_db),
):
    return get_monthly_performance(db, user_id, months)


# ─── P&L History / Sparkline ─────────────────────────────────────────────────

@router.get(
    "/analytics/pnl-history",
    summary="P&L History",
    description=(
        "Daily P&L series for a given period. Returns raw data plus "
        "normalised `roi_line` and `pnl_line` arrays (0–1) for Flutter sparkline charts. "
        "Source: `broker_pnl_snapshots` aggregated by date."
    ),
)
def pnl_history(
    user_id:    int            = Query(...),
    period:     str            = Query("last_7d", description="last_7d | last_month | custom"),
    start_date: Optional[date] = Query(None, description="Required when period=custom"),
    end_date:   Optional[date] = Query(None, description="Required when period=custom"),
    db: Session                = Depends(get_db),
):
    return get_pnl_history(db, user_id, period, start_date, end_date)


# ─── Dashboard — All-in-One ───────────────────────────────────────────────────

@router.get(
    "/dashboard/summary",
    summary="Full Investment Dashboard",
    description=(
        "Single endpoint that returns all 8 core data points in one call. "
        "Minimises Flutter round-trips on screen load. "
        "Includes sparklines, monthly performance, risk, and all P&L metrics."
    ),
)
def dashboard_summary(
    user_id:    int            = Query(..., description="Portfolio Owner user_id"),
    period:     str            = Query("last_7d", description="last_7d | last_month | custom"),
    start_date: Optional[date] = Query(None),
    end_date:   Optional[date] = Query(None),
    db: Session                = Depends(get_db),
):
    return get_investment_tracking(db, user_id, period, start_date, end_date)
