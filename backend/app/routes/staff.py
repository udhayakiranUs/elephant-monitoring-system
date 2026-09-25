from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Staff
from ..schemas import StaffOut
from ..security import current_user

router = APIRouter(prefix="/staff", tags=["staff"])


@router.get("", response_model=list[StaffOut])
def list_staff(db: Session = Depends(get_db), _=Depends(current_user)):
    return db.scalars(select(Staff).order_by(Staff.name)).all()
