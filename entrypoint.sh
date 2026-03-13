#!/bin/sh
set -e

# --- Environment Variable Check ---
# Ensure the database connection string is set (required for production)
if [ -z "$AIRFLOW__DATABASE__SQL_ALCHEMY_CONN" ]; then
    echo "ERROR: AIRFLOW__DATABASE__SQL_ALCHEMY_CONN must be set."
    echo "Example: postgresql+psycopg2://user:password@host:port/database"
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
