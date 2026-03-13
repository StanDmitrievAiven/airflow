#!/bin/sh
set -e

# --- Environment Variable Check ---
# Support both AIRFLOW__DATABASE__SQL_ALCHEMY_CONN and DATABASE_URL (Aiven service integration)
if [ -n "$AIRFLOW__DATABASE__SQL_ALCHEMY_CONN" ]; then
    echo "Using AIRFLOW__DATABASE__SQL_ALCHEMY_CONN for database connection."
elif [ -n "$DATABASE_URL" ]; then
    # Aiven exposes PostgreSQL as DATABASE_URL; convert to Airflow's expected format
    # postgres:// -> postgresql+psycopg2:// for SQLAlchemy/psycopg2
    AIRFLOW__DATABASE__SQL_ALCHEMY_CONN=$(echo "$DATABASE_URL" | sed 's|^postgres://|postgresql+psycopg2://|;s|^postgresql://|postgresql+psycopg2://|')
    export AIRFLOW__DATABASE__SQL_ALCHEMY_CONN
    echo "Using DATABASE_URL (Aiven service integration) for database connection."
else
    echo "ERROR: Database connection required. Set either:"
    echo "  - AIRFLOW__DATABASE__SQL_ALCHEMY_CONN (postgresql+psycopg2://user:pass@host:port/db)"
    echo "  - DATABASE_URL (auto-set when connecting PostgreSQL in Aiven)"
    exit 1
fi
echo "Database configuration found. Proceeding with application startup."
echo "---"

# --- Port configuration (Aiven App Runtime may inject PORT) ---
if [ -n "$PORT" ]; then
    export AIRFLOW__WEBSERVER__WEB_SERVER_PORT="$PORT"
fi

# --- Run migrations on startup (idempotent) ---
# Airflow's entrypoint supports _AIRFLOW_DB_MIGRATE to run migrations automatically
export _AIRFLOW_DB_MIGRATE="${_AIRFLOW_DB_MIGRATE:-true}"

# --- Exec into Airflow's entrypoint ---
# Pass through all arguments (default: standalone)
exec /entrypoint "$@"
