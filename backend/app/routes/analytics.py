from collections import defaultdict

from fastapi import APIRouter, Depends
from sqlalchemy import select
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Report
from ..security import current_user

router = APIRouter(prefix="/analytics", tags=["analytics"])

TYPES = ["lm", "mg", "fg", "fc", "sf", "ug", "mk"]


@router.get("")
def analytics(db: Session = Depends(get_db), _=Depends(current_user)):
    """Aggregates real reports into the shape AnalyticsMock exposes.

    Once this returns enough history, replace AnalyticsMock in the Flutter
    app with a call to this endpoint.
    """
    reports = db.scalars(select(Report)).all()

    monthly_e: dict[str, int] = defaultdict(int)
    monthly_i: dict[str, int] = defaultdict(int)
    per_range: dict[str, dict] = defaultdict(
        lambda: {t: 0 for t in TYPES} | {"elephants": 0, "incidents": 0}
    )

    for r in reports:
        key = r.date_time.strftime("%b-%Y")
        monthly_e[key] += r.total
        monthly_i[key] += 1
        row = per_range[r.range]
        for t in TYPES:
            row[t] += int((r.counts or {}).get(t, 0))
        row["elephants"] += r.total
        row["incidents"] += 1

    months = sorted(monthly_e, key=lambda m: (m.split("-")[1], m.split("-")[0]))
    return {
        "months": months,
        "monthly_elephants": [monthly_e[m] for m in months],
        "monthly_incidents": [monthly_i[m] for m in months],
        "range_stats": [{"range": k, **v} for k, v in sorted(per_range.items())],
        "total_records": len(reports),
        "all_time_recorded": sum(r.total for r in reports),
        "total_incidents": len(reports),
    }
