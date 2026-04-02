"""
main.py — FastAPI application entry point.
Run with: uvicorn main:app --reload --host 0.0.0.0 --port 8000
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import router, on_startup

app = FastAPI(
    title="SocioHub Analytics API",
    version="1.0.0",
    description="Investment analytics backend for SocioHub Flutter app",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],      # Tighten this to your production domain before going live
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


@app.on_event("startup")
def startup():
    """Auto-create DB tables (sh_users, sh_referrals) on server boot."""
    on_startup()


@app.get("/health")
def health():
    return {"status": "ok"}
