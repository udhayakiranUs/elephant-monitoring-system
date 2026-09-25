from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Alert, ForestRange
from ..schemas import AlertIn, AlertOut
from ..security import current_user

router = APIRouter(prefix="/alerts", tags=["alerts"])


@router.get("", response_model=list[AlertOut])
def list_alerts(db: Session = Depends(get_db), _=Depends(current_user)):
    return db.scalars(select(Alert).order_by(Alert.time.desc())).all()


@router.post("", response_model=AlertOut, status_code=status.HTTP_201_CREATED)
def create_alert(body: AlertIn, db: Session = Depends(get_db), _=Depends(current_user)):
    existing = db.get(Alert, body.id)
    if existing:                       # offline queue may resend the same id
        return existing
    alert = Alert(**body.model_dump())
    db.add(alert)

    rng = db.get(ForestRange, body.range)
    if rng:
        rng.today += body.elephants
        rng.total_elephants += body.elephants
        rng.total_incidents += 1
        rng.status = "alert" if body.threat.upper() == "HIGH" else "active"
        rng.last_report = body.time.strftime("%H:%M")

    db.commit()
    db.refresh(alert)
    return alert


@router.patch("/{alert_id}/resolve", response_model=AlertOut)
def resolve_alert(alert_id: str, db: Session = Depends(get_db), _=Depends(current_user)):
    alert = db.get(Alert, alert_id)
    if alert is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Alert not found")
    alert.resolved = True
    alert.type = "ok"
    db.commit()
    db.refresh(alert)
    return alert
