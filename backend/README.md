# EWS Backend (FastAPI)

Backend for the Elephant Warning System Flutter app.
JSON keys here match `frontend/ews_flutter/lib/models/*.dart` exactly — do not rename them.

## Run (Windows / VS Code terminal)

```bat
cd backend
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
copy .env.example .env
python seed.py
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

macOS / Linux: `python3 -m venv .venv && source .venv/bin/activate`, `cp .env.example .env`.

Interactive docs: http://127.0.0.1:8000/docs

Demo logins (created by `seed.py`): `murugan / ews123` (field), `vel / ews123` (command).

## Endpoints (all under `/api/v1`)

| Method | Path | Notes |
|---|---|---|
| POST | `/auth/login` | `{username, password}` -> `{access_token, user}` |
| GET | `/auth/me` | current user |
| GET | `/users` | command role only |
| GET | `/alerts` | list |
| POST | `/alerts` | create (idempotent on `id`, so the offline queue can resend) |
| PATCH | `/alerts/{id}/resolve` | marks resolved + type `ok` |
| GET/POST | `/reports` | list / create (idempotent on `id`) |
| POST | `/reports/{id}/photos` | multipart `files`, saves to `/uploads` |
| GET | `/staff` | list |
| GET | `/ranges` | live range table |
| GET/PUT | `/ranges/{name}/boundary` | PUT is command role only |
| GET | `/analytics` | aggregates real reports (replaces AnalyticsMock later) |

Every route except `/auth/login` and `/health` needs `Authorization: Bearer <token>`.

## Connecting the Flutter app

In `lib/core/constants/api_constants.dart`:

```dart
static const bool useMock = false;
static const String baseUrl = 'http://127.0.0.1:8000/api/v1';  // Chrome / web
// Android emulator: 'http://10.0.2.2:8000/api/v1'
// Physical phone:   'http://<your-PC-LAN-IP>:8000/api/v1'
```

## Moving to PostgreSQL

Set `DATABASE_URL=postgresql+psycopg://user:pass@localhost:5432/ews` in `.env`
and `pip install psycopg[binary]`. Tables are created on startup; for real
migrations add Alembic.
