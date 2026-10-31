# AGENTS.md — MenStyle

Repo-specific guidance for AI coding agents working in this repository.

## Project overview

Multi-app repo (no monorepo tooling; independent per-folder setups):

- `backend/` — FastAPI + SQLAlchemy/Alembic REST API. Entry point: `backend/app/main.py`. Routers: `backend/app/api/routes/<dominio>.py` (one per domain). Business logic: `backend/app/services/`. Models: `backend/app/models/`. Schemas: `backend/app/schemas/`. Cross-cutting concerns: `backend/app/core/` (DB, security, rate limiter, dependencies).
- `frontend/` — Angular 21 web app (standalone components). Pages: `frontend/src/app/pages/<feature>/<feature>.ts`. Shared UI kit: `frontend/src/app/shared/ui/` (12 components + barrel `index.ts`).
- `mobile/` — Flutter app. `mobile/lib/` (screens/services/models/core/shared).
- `docs/` — PUDS process docs + UML diagrams. Background only; code is the source of truth.

## Commands

### Backend (run from `backend/`)

- Setup: `python -m venv .venv && pip install -r requirements.txt && cp .env.example .env && alembic upgrade head`
- Dev server: `uvicorn app.main:app --reload --host 0.0.0.0 --port 8000`
- Migrations: auto-run at app startup via `app.main.ejecutar_migraciones()`. Manually: `alembic upgrade head`. After model changes: `alembic revision --autogenerate -m "<msg>"` then `alembic upgrade head` (needs live DB via `DATABASE_URL`).
- Tests: `pytest -v` (from `backend/`). Uses **SQLite in-memory** via conftest overrides (`obtener_db` + auth `obtener_db`); no Postgres needed. Fixtures: `client`, `db_session`, `admin_user`, `client_user`, `admin_headers`, `client_headers`, `seed_data`. Single test: `pytest tests/test_auth.py::test_login_exitoso`.
- Lint: `ruff check` (via venv; installed through requirements, no ruff config file → defaults).

### Frontend (from `frontend/`)

- `npm install`, `ng serve` (port 4200), `npm run build` (production default; `npm run watch` = dev watch build).
- Tests: builder `@angular/build:unit-test` (Vitest + jsdom via `@angular/build`). **No `*.spec.ts` files exist under `src/` yet** — there is nothing to run. For a one-shot run use `ng test --watch=false` (watch defaults to `true` in TTY).
- No lint script. Prettier: `printWidth: 100`, `singleQuote: true`, Angular parser for HTML. EditorConfig: 2-space indent, single quotes for TS.
- Type-check/compile: `ng build` (strict TS + `strictTemplates`; budgets: initial 1.5MB warn+error, component styles 4kB warn / 8kB error).

### Mobile (from `mobile/`)

- `flutter pub get`, `flutter test`, `flutter analyze`, `flutter run`.
- Backend URL override: `flutter run --dart-define=API_URL=http://localhost:8000/api`; media: `--dart-define=MEDIA_URL=...`; debug HTTP logs: `DEBUG_HTTP`.

## Architecture notes and gotchas

- Backend refuses to start without `ADMIN_MIGRATION_KEY` (admin router raises at import). `SECRET_KEY` is mandatory in production (random fallback in dev). Required env: `DATABASE_URL`, `SECRET_KEY`, `ADMIN_MIGRATION_KEY`; optional: `GEMINI_API_KEY`, `STRIPE_SECRET_KEY`, `STRIPE_PUBLISHABLE_KEY`, `STRIPE_WEBHOOK_SECRET`, `BREVO_API_KEY`, `SMTP_*`, `FRONTEND_URL`, `CORS_ORIGINS`, `ENVIRONMENT`, `ALLOW_DESTRUCTIVE_ENDPOINTS`.
- Rate limit: slowapi, default `200/minute` per IP (`backend/app/core/limiter.py`).
- Router prefixes are Spanish and domain-specific: `/api/auth`, `/api/categorias`, `/api/productos`, `/api/variantes`, `/api/tallas`, `/api/colores`, `/api/sucursales`, `/api/carrito`, `/api/reservas`, `/api/pedidos`, `/api/pagos`, `/api/ia`, `/api/reportes`, admin under `/api/admin`. Frontend services must mirror these prefixes.
- Auth: JWT HS256, `sub` = email, 60 min expiry, bcrypt hashes. Roles: `administrador` / `cliente`. Admin ops guarded by `X-Admin-Key` header (`ADMIN_MIGRATION_KEY`) and `ALLOW_DESTRUCTIVE_ENDPOINTS` flag (blocks `/api/admin/seed`, `/seed-demo`, `/fix-imagenes` unless enabled).
- Frontend service API bases are hardcoded to the production Render backend (`https://menstyle-api-n77g.onrender.com/api/...`) — no Angular environments files. Local dev against `localhost:8000` requires pointing them at the local API.
- Mobile defaults to the same production backend; override via `--dart-define`.

## Operational gotchas

- Python venv lives at `backend/.venv` (NOT `backend/venv`). `pyrefly.toml` still points to the stale `backend/venv/bin/python` path.
- Backend on Windows: activate via `backend\.venv\Scripts\activate`.
- Docker Compose: PostgreSQL exposed on host port **5433** (moved from 5432 to avoid conflicts).
- `.env` is gitignored; copy from `backend/.env.example`. Migrations require `DATABASE_URL` (see `backend/app/migrations/env.py`).

## References

- `README.md` — setup, endpoints, troubleshooting.
- `backend/.env.example`, `backend/alembic.ini`, `backend/requirements.txt`.
- `frontend/package.json`, `frontend/angular.json`, `frontend/.prettierrc`, `frontend/.editorconfig`.
- `mobile/pubspec.yaml`, `mobile/analysis_options.yaml`, `mobile/lib/core/config.dart`.
- `docs/` — process docs (PUDS/UML), treat as background only.

## Suggested verification order

- Backend change: `ruff check` → `pytest -v` (migrations via `alembic upgrade head` when schema changes).
- Frontend change: `ng build` (type-checks) → `ng test --watch=false`.
- Mobile change: `flutter analyze` → `flutter test`.
