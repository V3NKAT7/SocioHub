"""
routers.py
==========
GET/POST endpoints for the SocioHub Analytics API.

All business logic is delegated to sociohub.py.
This file contains ONLY route definitions and request validation.

Base prefix: /api/v1
Interactive docs: http://192.168.1.139:8000/docs
"""

from fastapi import APIRouter, Depends, Query, HTTPException, Header
from datetime import date
from typing import Optional
from sqlalchemy.orm import Session
from pydantic import BaseModel, EmailStr

from sociohub import (
    # ── Investments ───────────────────────────────────────────────────────────
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
    # ── Auth ─────────────────────────────────────────────────────────────────
    login_user,
    forgot_password,
    decode_token,
    create_tables,
    # ── Social ────────────────────────────────────────────────────────────────
    get_social_feed,
    toggle_like,
    record_share,
    get_story_templates,
    # ── Referrals ─────────────────────────────────────────────────────────────
    get_my_referral_link,
    get_referral_rewards,
)

router = APIRouter(prefix="/api/v1")


# ─── Startup ──────────────────────────────────────────────────────────────────

def on_startup():
    """Auto-create sh_users and sh_referrals tables if they don't exist."""
    create_tables()


# ─── Auth Dependency (Bearer Token) ──────────────────────────────────────────

def get_current_user(authorization: str = Header(...)) -> dict:
    """
    Extracts and validates the Bearer JWT from the Authorization header.
    Usage: current_user: dict = Depends(get_current_user)
    Returns: {"user_id": int, "email": str}
    """
    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization header format")
    token = authorization.split(" ", 1)[1]
    try:
        payload = decode_token(token)
        return {"user_id": int(payload["sub"]), "email": payload["email"]}
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid or expired token")


# ─── Request Bodies ──────────────────────────────────────────────────────────

class LoginRequest(BaseModel):
    email:    EmailStr
    password: str

class ForgotPasswordRequest(BaseModel):
    email: EmailStr

class LikeRequest(BaseModel):
    story_id: str
    action:   str = "like"

class ShareRequest(BaseModel):
    story_id: str
    platform: str


# ===========================================================================
# AUTH (/api/v1/auth)
# ===========================================================================

@router.post(
    "/auth/login",
    summary="Login",
    description="Authenticates the user and returns a JWT access token.",
)
def auth_login(body: LoginRequest, db: Session = Depends(get_db)):
    try:
        return login_user(db, body.email, body.password)
    except ValueError as e:
        raise HTTPException(status_code=401, detail=str(e))


@router.post(
    "/auth/forgot-password",
    summary="Forgot Password",
    description="Triggers a password reset flow (sends an email link in production).",
)
def auth_forgot_password(body: ForgotPasswordRequest, db: Session = Depends(get_db)):
    return forgot_password(db, body.email)


# ===========================================================================
# SOCIAL METRICS (/api/v1/social)
# ===========================================================================

@router.get(
    "/social/feed",
    summary="Social Feed",
    description="Fetches a paginated list of financial stories and user activities from MongoDB.",
)
def social_feed(
    page:     int  = Query(1,  ge=1,  description="Page number"),
    page_size:int  = Query(20, ge=1, le=100, description="Items per page"),
    current_user: dict = Depends(get_current_user),
):
    return get_social_feed(page=page, page_size=page_size)


@router.post(
    "/social/likes",
    summary="Toggle Like",
    description="Toggles a like on a specific story. Returns new like count and liked status.",
)
def social_like(body: LikeRequest, current_user: dict = Depends(get_current_user)):
    try:
        return toggle_like(body.story_id, current_user["user_id"])
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.post(
    "/social/shares",
    summary="Record Share",
    description="Records that a user shared a story externally to a platform.",
)
def social_share(body: ShareRequest, current_user: dict = Depends(get_current_user)):
    try:
        return record_share(body.story_id, body.platform, current_user["user_id"])
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get(
    "/social/templates",
    summary="Financial Story Templates",
    description="Fetches dynamic Financial Story templates for the user to generate content.",
)
def social_templates(current_user: dict = Depends(get_current_user)):
    return get_story_templates()


# ===========================================================================
# REFERRALS (/api/v1/referrals)
# ===========================================================================

@router.get(
    "/referrals/my-link",
    summary="My Referral Link",
    description="Retrieves the authenticated user's unique referral link and share message.",
)
def referrals_my_link(
    current_user: dict = Depends(get_current_user),
    db: Session        = Depends(get_db),
):
    try:
        return get_my_referral_link(db, current_user["user_id"])
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.get(
    "/referrals/rewards",
    summary="Referral Rewards",
    description="Fetches the user's earned rewards, pending referral count, and recent referral list.",
)
def referrals_rewards(
    current_user: dict = Depends(get_current_user),
    db: Session        = Depends(get_db),
):
    return get_referral_rewards(db, current_user["user_id"])


# ===========================================================================
# INVESTMENTS (/api/v1/investments  &  /api/v1/analytics  &  /api/v1/dashboard)
# ===========================================================================

@router.get(
    "/investments/capital",
    summary="Invested Capital",
    description="Returns total capital deployed across all active broker accounts.",
)
def invested_capital(
    user_id: int = Query(..., description="Portfolio Owner user_id"),
    db: Session  = Depends(get_db),
):
    return get_invested_capital(db, user_id)


@router.get(
    "/investments/realised-pnl",
    summary="Realised P&L",
    description="Realised profit/loss and closed position count for a given date.",
)
def realised_pnl(
    user_id:     int            = Query(...),
    target_date: Optional[date] = Query(None, description="Date (YYYY-MM-DD). Defaults to today"),
    db: Session                 = Depends(get_db),
):
    return get_realised_pnl(db, user_id, target_date)


@router.get(
    "/investments/unrealised-pnl",
    summary="Unrealised P&L",
    description="Mark-to-market P&L on all currently open positions.",
)
def unrealised_pnl(
    user_id: int = Query(...),
    db: Session  = Depends(get_db),
):
    return get_unrealised_pnl(db, user_id)


@router.get(
    "/investments/total-profit",
    summary="Total Profit",
    description="Combined realized + unrealized P&L with ROI %.",
)
def total_profit(
    user_id: int = Query(...),
    db: Session  = Depends(get_db),
):
    return get_total_profit(db, user_id)


@router.get(
    "/investments/active-trades",
    summary="Active Trades",
    description="All currently open positions with live prices and P&L.",
)
def active_trades(
    user_id: int = Query(...),
    db: Session  = Depends(get_db),
):
    return get_active_trades(db, user_id)


@router.get(
    "/investments/risk",
    summary="Total Risk Level",
    description="Aggregated risk metrics: risk level, Kelly %, expected value, MAE, MFE.",
)
def risk_summary(
    user_id: int = Query(...),
    db: Session  = Depends(get_db),
):
    return get_risk_summary(db, user_id)


@router.get(
    "/analytics/monthly-performance",
    summary="Monthly Performance",
    description="Month-by-month P&L breakdown for the trailing N months.",
)
def monthly_performance(
    user_id: int = Query(...),
    months:  int = Query(12, ge=1, le=24),
    db: Session  = Depends(get_db),
):
    return get_monthly_performance(db, user_id, months)


@router.get(
    "/analytics/pnl-history",
    summary="P&L History",
    description="Daily P&L series. Returns raw data plus normalised roi_line and pnl_line for Flutter sparklines.",
)
def pnl_history(
    user_id:    int            = Query(...),
    period:     str            = Query("last_7d", description="last_7d | last_month | custom"),
    start_date: Optional[date] = Query(None),
    end_date:   Optional[date] = Query(None),
    db: Session                = Depends(get_db),
):
    return get_pnl_history(db, user_id, period, start_date, end_date)


@router.get(
    "/dashboard/summary",
    summary="Full Investment Dashboard",
    description="Single endpoint returning all 8 core data points in one call to minimise Flutter round-trips.",
)
def dashboard_summary(
    user_id:    int            = Query(...),
    period:     str            = Query("last_7d"),
    start_date: Optional[date] = Query(None),
    end_date:   Optional[date] = Query(None),
    db: Session                = Depends(get_db),
):
    return get_investment_tracking(db, user_id, period, start_date, end_date)
