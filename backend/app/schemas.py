from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field

# NOTE: every field name below must match the JSON keys in the Flutter
# models (lib/models/*.dart). Do not rename them casually.


class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    name: str
    designation: str = ""
    range: str = ""
    phone: str = ""
    role: str = "field"


class LoginIn(BaseModel):
    username: str
    password: str


class LoginOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut


class AlertIn(BaseModel):
    id: str
    type: str = "info"
    title: str = ""
    range: str = ""
    elephants: int = 0
    threat: str = "MEDIUM"
    officer: str = ""
    gps: str = ""
    damage: str = ""
    sent_to: str = ""
    message: str = ""
    time: datetime
    resolved: bool = False


class AlertOut(AlertIn):
    model_config = ConfigDict(from_attributes=True)


class ReportIn(BaseModel):
    id: str
    range: str = ""
    beat: str = ""
    lat: float = 0
    lon: float = 0
    location_description: str = ""
    date_time: datetime
    officer: str = ""
    designation: str = ""
    team: str = ""
    counts: dict[str, int] = Field(default_factory=dict)
    total: int = 0
    damage: bool = False
    damage_type: str = ""
    damage_description: str = ""
    chase_start: str = ""
    chase_result: str = ""
    remarks: str = ""
    photos: list[str] = Field(default_factory=list)


class ReportOut(ReportIn):
    model_config = ConfigDict(from_attributes=True)


class StaffOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: str
    name: str
    assignment: str = ""
    status: str = "standby"


class RangeOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    name: str
    today: int = 0
    total_elephants: int = 0
    total_incidents: int = 0
    status: str = "clear"
    last_report: str = "—"


class BoundaryIn(BaseModel):
    points: list[list[float]]


class AnalyticsOut(BaseModel):
    months: list[str]
    monthly_elephants: list[int]
    monthly_incidents: list[int]
    range_stats: list[dict[str, Any]]
    total_records: int
    all_time_recorded: int
    total_incidents: int
