"""
main.py — FastAPI application entry point.
Run with: uvicorn main:app --reload --port 8000
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from routers import router

app = FastAPI(
    title="SocioHub Analytics API",
    version="1.0.0",
    description="Investment analytics backend for SocioHub Flutter app",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:8080", "https://sociohub.app"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(router)


@app.get("/health")
def health():
    return {"status": "ok"}
