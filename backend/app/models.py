from datetime import datetime

from sqlalchemy import Boolean, DateTime, Float, Integer, JSON, String
from sqlalchemy.orm import Mapped, mapped_column

from .database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True)          # U-101
    username: Mapped[str] = mapped_column(String, unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String)
    name: Mapped[str] = mapped_column(String)
    designation: Mapped[str] = mapped_column(String, default="")
    range: Mapped[str] = mapped_column(String, default="")
    phone: Mapped[str] = mapped_column(String, default="")
    role: Mapped[str] = mapped_column(String, default="field")          # field | command


class Alert(Base):
    __tablename__ = "alerts"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    type: Mapped[str] = mapped_column(String, default="info")           # danger|warn|info|ok
    title: Mapped[str] = mapped_column(String, default="")
    range: Mapped[str] = mapped_column(String, default="", index=True)
    elephants: Mapped[int] = mapped_column(Integer, default=0)
    threat: Mapped[str] = mapped_column(String, default="MEDIUM")       # HIGH|MEDIUM|LOW
    officer: Mapped[str] = mapped_column(String, default="")
    gps: Mapped[str] = mapped_column(String, default="")
    damage: Mapped[str] = mapped_column(String, default="")
    sent_to: Mapped[str] = mapped_column(String, default="")
    message: Mapped[str] = mapped_column(String, default="")
    time: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    resolved: Mapped[bool] = mapped_column(Boolean, default=False)


class Report(Base):
    __tablename__ = "reports"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    range: Mapped[str] = mapped_column(String, default="", index=True)
    beat: Mapped[str] = mapped_column(String, default="")
    lat: Mapped[float] = mapped_column(Float, default=0.0)
    lon: Mapped[float] = mapped_column(Float, default=0.0)
    location_description: Mapped[str] = mapped_column(String, default="")
    date_time: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    officer: Mapped[str] = mapped_column(String, default="")
    designation: Mapped[str] = mapped_column(String, default="")
    team: Mapped[str] = mapped_column(String, default="")
    counts: Mapped[dict] = mapped_column(JSON, default=dict)            # {lm,mg,fg,fc,sf,mk}
    total: Mapped[int] = mapped_column(Integer, default=0)
    damage: Mapped[bool] = mapped_column(Boolean, default=False)
    damage_type: Mapped[str] = mapped_column(String, default="")
    damage_description: Mapped[str] = mapped_column(String, default="")
    chase_start: Mapped[str] = mapped_column(String, default="")
    chase_result: Mapped[str] = mapped_column(String, default="")
    remarks: Mapped[str] = mapped_column(String, default="")
    photos: Mapped[list] = mapped_column(JSON, default=list)


class Staff(Base):
    __tablename__ = "staff"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    name: Mapped[str] = mapped_column(String)
    assignment: Mapped[str] = mapped_column(String, default="")
    status: Mapped[str] = mapped_column(String, default="standby")      # field|hq|standby|offDuty


class ForestRange(Base):
    __tablename__ = "ranges"

    name: Mapped[str] = mapped_column(String, primary_key=True)
    today: Mapped[int] = mapped_column(Integer, default=0)
    total_elephants: Mapped[int] = mapped_column(Integer, default=0)
    total_incidents: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String, default="clear")        # alert|active|clear
    last_report: Mapped[str] = mapped_column(String, default="—")
    boundary: Mapped[list] = mapped_column(JSON, default=list)          # [[lat, lon], ...]
