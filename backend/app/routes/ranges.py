from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import ForestRange
from ..schemas import BoundaryIn, RangeOut
from ..security import command_only, current_user

router = APIRouter(prefix="/ranges", tags=["ranges"])


@router.get("", response_model=list[RangeOut])
def list_ranges(db: Session = Depends(get_db), _=Depends(current_user)):
    return db.scalars(select(ForestRange).order_by(ForestRange.name)).all()


@router.get("/{name}/boundary")
def get_boundary(name: str, db: Session = Depends(get_db), _=Depends(current_user)):
    rng = db.get(ForestRange, name)
    if rng is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Range not found")
    return {"points": rng.boundary or []}


@router.put("/{name}/boundary")
def put_boundary(
    name: str,
    body: BoundaryIn,
    db: Session = Depends(get_db),
    _=Depends(command_only),           # only HQ may redraw borders
):
    rng = db.get(ForestRange, name)
    if rng is None:
        raise HTTPException(status.HTTP_404_NOT_FOUND, "Range not found")
    rng.boundary = body.points
    db.commit()
    return {"ok": True, "points": rng.boundary}
