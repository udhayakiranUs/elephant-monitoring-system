import os
import uuid
from datetime import date, datetime, time, timedelta

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..config import settings
from ..database import get_db
from ..models import Report
from ..schemas import ReportIn, ReportOut
from ..security import current_user

router = APIRouter(prefix="/reports", tags=["reports"])


# ---------------------------------------------------------
# ALL REPORTS
#
# Optional:
#   ?report_date=2026-09-25
#
# This allows old/past reports to be searched by date.
# ---------------------------------------------------------
@router.get("", response_model=list[ReportOut])
def list_reports(
    report_date: date | None = Query(
        default=None,
        description="Filter reports by date: YYYY-MM-DD",
    ),
    db: Session = Depends(get_db),
    _=Depends(current_user),
):
    query = select(Report)

    if report_date is not None:
        start_datetime = datetime.combine(
            report_date,
            time.min,
        )

        end_datetime = start_datetime + timedelta(days=1)

        query = query.where(
            Report.date_time >= start_datetime,
            Report.date_time < end_datetime,
        )

    query = query.order_by(
        Report.date_time.desc()
    )

    return db.scalars(query).all()


# ---------------------------------------------------------
# MY REPORTS
# ---------------------------------------------------------
@router.get("/mine", response_model=list[ReportOut])
def list_my_reports(
    db: Session = Depends(get_db),
    user=Depends(current_user),
):
    return db.scalars(
        select(Report)
        .where(Report.officer == user.name)
        .order_by(Report.date_time.desc())
    ).all()


# ---------------------------------------------------------
# CREATE REPORT
# ---------------------------------------------------------
@router.post(
    "",
    response_model=ReportOut,
    status_code=status.HTTP_201_CREATED,
)
def create_report(
    body: ReportIn,
    db: Session = Depends(get_db),
    user=Depends(current_user),
):
    existing = db.get(Report, body.id)

    if existing:
        return existing

    report_data = body.model_dump()

    # Always use logged-in user's name.
    report_data["officer"] = user.name

    report = Report(**report_data)

    db.add(report)
    db.commit()
    db.refresh(report)

    return report


# ---------------------------------------------------------
# UPLOAD REPORT PHOTOS
# ---------------------------------------------------------
@router.post(
    "/{report_id}/photos",
    response_model=ReportOut,
)
async def upload_photos(
    report_id: str,
    files: list[UploadFile] = File(...),
    db: Session = Depends(get_db),
    _=Depends(current_user),
):
    report = db.get(Report, report_id)

    if report is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Report not found",
        )

    os.makedirs(
        settings.upload_dir,
        exist_ok=True,
    )

    saved = list(report.photos or [])

    for file in files:
        extension = os.path.splitext(
            file.filename or ""
        )[1] or ".jpg"

        filename = (
            f"{report_id}-"
            f"{uuid.uuid4().hex[:8]}"
            f"{extension}"
        )

        filepath = os.path.join(
            settings.upload_dir,
            filename,
        )

        with open(filepath, "wb") as output:
            output.write(await file.read())

        saved.append(
            f"/uploads/{filename}"
        )

    report.photos = saved

    db.commit()
    db.refresh(report)

    return report