#!/bin/bash
set -e
echo "=== Running alembic upgrade head ==="
alembic upgrade head
echo "=== Alembic upgrade done ==="
echo "=== Starting uvicorn ==="
uvicorn app.main:app --host 0.0.0.0 --port $PORT
