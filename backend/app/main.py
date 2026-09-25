from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from .config import settings
from .database import Base, engine
from .routes import alerts, analytics, auth, ranges, reports, staff, users

app = FastAPI(title="EWS API", version="1.0.0")

# Flutter web (flutter run -d chrome) uses a random port, so allow all in dev.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

Base.metadata.create_all(bind=engine)
os.makedirs(settings.upload_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=settings.upload_dir), name="uploads")

API = "/api/v1"
for r in (auth, users, alerts, reports, staff, ranges, analytics):
    app.include_router(r.router, prefix=API)


@app.get("/health")
def health():
    return {"status": "ok"}
