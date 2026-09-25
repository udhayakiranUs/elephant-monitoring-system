"""Seed the database with the same demo data the Flutter mock uses.

    python seed.py
"""

from datetime import datetime, timedelta

from app.database import Base, SessionLocal, engine
from app.models import Alert, ForestRange, Staff, User
from app.security import hash_password


RANGES = [
    ("Periyanaickenpalayam", 4, 4588, 1600, "active", "08:40"),
    ("Mettupalayam", 16, 3964, 2289, "alert", "09:15"),
    ("Madukkarai", 0, 828, 449, "clear", "—"),
    ("Sirumugai", 3, 2590, 1565, "active", "07:55"),
    ("Karamadai", 0, 1279, 659, "clear", "—"),
    ("Coimbatore", 6, 4654, 2012, "active", "08:05"),
    ("Bolampatty", 0, 2170, 1349, "clear", "—"),
]


STAFF = [
    ("S-01", "RFO Murugan", "Mettupalayam", "field"),
    ("S-02", "Vel Kumar", "HQ Command", "hq"),
    ("S-03", "Arun Prakash", "Coimbatore", "field"),
    ("S-04", "Lakshmi R", "Sirumugai", "standby"),
    ("S-05", "Karthik S", "Madukkarai", "offDuty"),
]


def run() -> None:
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # Demo users
    demo_users = [
        User(
            id="U-101",
            username="kiran",
            password_hash=hash_password("uk123"),
            name="Kiran",
            designation="Range Forest Officer",
            range="Mettupalayam",
            phone="+91 98765 43210",
            role="field",
        ),
        User(
            id="U-201",
            username="vel",
            password_hash=hash_password("ews123"),
            name="Vel Kumar",
            designation="HQ Command Officer",
            range="Division HQ",
            phone="+91 98765 01234",
            role="command",
        ),
    ]

    for demo in demo_users:
        existing = db.query(User).filter(
            User.username == demo.username
        ).first()

        if existing:
            existing.password_hash = demo.password_hash
            existing.name = demo.name
            existing.designation = demo.designation
            existing.range = demo.range
            existing.phone = demo.phone
            existing.role = demo.role
        else:
            db.add(demo)

    # Forest ranges
    if db.query(ForestRange).count() == 0:
        for name, today, te, ti, status, last in RANGES:
            db.add(
                ForestRange(
                    name=name,
                    today=today,
                    total_elephants=te,
                    total_incidents=ti,
                    status=status,
                    last_report=last,
                )
            )

    # Staff
    if db.query(Staff).count() == 0:
        for sid, name, assignment, status in STAFF:
            db.add(
                Staff(
                    id=sid,
                    name=name,
                    assignment=assignment,
                    status=status,
                )
            )

    # Alerts
    if db.query(Alert).count() == 0:
        now = datetime.now()

        db.add(
            Alert(
                id="AL-001",
                type="danger",
                title="EMERGENCY — Mettupalayam Range",
                range="Mettupalayam",
                elephants=16,
                threat="HIGH",
                officer="RFO Murugan",
                gps="11.0168°N 76.9558°E",
                damage="Crop damage reported",
                sent_to="All 24 staff · HQ activated · Control room",
                message="Herd of 16 near village boundary",
                time=now - timedelta(hours=1),
            )
        )

    db.commit()
    db.close()

    print("Seeded successfully.")
    print("Field login: kiran / uk123")
    print("Command login: vel / ews123")


if __name__ == "__main__":
    run()