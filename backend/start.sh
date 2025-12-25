#!/bin/bash
set -e

echo "Starting Railway deployment..."
echo "PORT=${PORT}"
echo "DATABASE_URL is set: $([ -n "$DATABASE_URL" ] && echo 'yes' || echo 'no')"

cd /app/backend
exec uvicorn enhanced_main:app --host 0.0.0.0 --port ${PORT:-8000}