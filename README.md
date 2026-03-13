# Airflow on Aiven App Runtime

This repository contains a Docker-based deployment configuration for [Apache Airflow](https://airflow.apache.org/) designed to run on Aiven's App Runtime platform.

## Overview

Apache Airflow is a platform to programmatically author, schedule, and monitor workflows. This project provides a containerized setup that:

- Extends the official Apache Airflow Docker image
- Runs webserver, scheduler, and triggerer in a single container (`airflow standalone`)
- Uses LocalExecutor (no Redis/Celery required)
- Automatically runs database migrations on startup
- Configures the application for Aiven App Runtime deployment

## Prerequisites

- Aiven account with App Runtime access
- PostgreSQL database service in Aiven (for Airflow's metadata storage)
- Git repository access (this repo)

## Required Environment Variables

A database connection **must** be configured. You can use either:

### Option 1: Aiven Service Integration (Recommended)

When you **connect a PostgreSQL service** in Aiven App Runtime's "Connect services" step, Aiven automatically injects `DATABASE_URL`. The entrypoint detects this and configures Airflow accordingly—no extra setup needed.

### Option 2: Manual Configuration

- `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` - PostgreSQL connection string for Airflow metadata

Example format:

```
postgresql+psycopg2://username:password@hostname:port/database
```

Get the connection string from your Aiven PostgreSQL service. Ensure the database user has sufficient permissions to create tables and run migrations.

### First-Run Configuration (Optional)

For the first deployment, you may want to create an admin user. **Use these Aiven-compatible names** (Aiven rejects variable keys starting with `_`):

- `AIRFLOW_WWW_USER_CREATE` - Set to `true` to create an admin user
- `AIRFLOW_WWW_USER_PASSWORD` - Admin password (required when creating user)

Migrations run automatically on startup (no variable needed). To disable, set `AIRFLOW_DB_MIGRATE=false`.

Example for first run:

```
AIRFLOW_WWW_USER_CREATE=true
AIRFLOW_WWW_USER_PASSWORD=your-secure-password
```

### Other Configuration (Optional)

- `AIRFLOW_UID` - User ID for file permissions (default: 50000)
- `PORT` - If Aiven injects a `PORT` environment variable, the webserver will automatically listen on it

## Deployment to Aiven App Runtime

1. **Create a PostgreSQL Service** in Aiven (if you don't have one)
   - This will store Airflow's metadata (DAGs, task history, connections, etc.)

2. **Create an App Runtime Application**
   - Source: Point to this GitHub repository (`https://github.com/StanDmitrievAiven/airflow.git`)
   - Branch: `main`

3. **Configure Environment Variables**
   - Add `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` with your PostgreSQL connection string from Aiven
   - For first run, add `AIRFLOW_WWW_USER_CREATE=true` and `AIRFLOW_WWW_USER_PASSWORD=<password>`

4. **Configure Port**
   - Open port **8080** in your App Runtime configuration (or the port Aiven assigns via `PORT` env var)
   - Airflow's web UI will be accessible on this port

5. **Deploy**
   - Aiven will automatically build and deploy your application
   - Check the logs to verify successful startup and migration

## Accessing the UI

Once deployed, access the Airflow web UI at:

```
https://<your-app-hostname>:8080/
```

Or, if Aiven uses a different port via the `PORT` environment variable:

```
https://<your-app-hostname>:<PORT>/
```

Default login (if you created a user): `admin` / your configured password.

## Project Structure

```
.
├── Dockerfile          # Extends official Airflow image
├── entrypoint.sh       # Startup script: validates env, runs migrations, starts Airflow
├── dags/               # Add your DAG files here (embedded in image)
├── .gitattributes      # Git configuration for line endings
└── README.md           # This file
```

## How It Works

1. **Build**: Extends `apache/airflow:3.1.8` with:
   - LocalExecutor configuration (no Redis needed)
   - Custom entrypoint for validation and migrations
   - DAGs from the `dags/` directory

2. **Runtime**: The entrypoint script:
   - Validates that `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` is set
   - Runs database migrations automatically
   - Starts Airflow in standalone mode (webserver + scheduler + triggerer in one process)

## Adding DAGs

Add your DAG files to the `dags/` directory in this repository. They will be copied into the image at build time. After pushing changes, trigger a new deployment in Aiven to pick up the new DAGs.

## Customization

### Using a Different Airflow Version

To use a different Airflow image version, set the build argument:

```dockerfile
ARG AIRFLOW_IMAGE=apache/airflow:3.0.0
```

### Adding Providers

To add Airflow providers (e.g. for PostgreSQL, HTTP, etc.), create a `requirements.txt`:

```
apache-airflow-providers-postgres
apache-airflow-providers-http
```

Then add to the Dockerfile before the CMD:

```dockerfile
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt
```

## Limitations

- **Stateless**: Logs are ephemeral. For persistent logs, configure external logging (e.g. Aiven for OpenSearch).
- **LocalExecutor only**: No Celery worker support. For parallel task execution, use a Kubernetes deployment instead.
- **Single instance**: Suitable for development and moderate workloads. For high availability, use the [Airflow Helm Chart](https://airflow.apache.org/docs/helm-chart/stable/index.html) on Kubernetes.

## Troubleshooting

### Database Connection Issues

- Verify your PostgreSQL connection string is correct
- Ensure the database is accessible from App Runtime (check VPC/network configuration)
- Check that the database user has necessary permissions (CREATE, ALTER, etc.)

### Migration Failures

- Check the application logs for specific migration errors
- Ensure the database is empty or compatible with Airflow's schema
- Verify the connection string uses `postgresql+psycopg2://` (not `postgresql://`)

### Port Configuration

- Ensure port 8080 (or `PORT` if set) is opened in your App Runtime configuration
- If Aiven injects a `PORT` variable, the entrypoint automatically configures Airflow to use it

## Security Considerations

- Use a strong password for `AIRFLOW_WWW_USER_PASSWORD`
- Consider configuring [Airflow authentication](https://airflow.apache.org/docs/apache-airflow/stable/security/webserver.html) (OAuth, LDAP, etc.) for production
- Restrict network access to the application as appropriate
- Do not commit secrets to the repository; use Aiven's environment variable configuration

## Resources

- [Apache Airflow Documentation](https://airflow.apache.org/docs/)
- [Airflow Docker Image](https://airflow.apache.org/docs/docker-stack/)
- [Aiven App Runtime Documentation](https://docs.aiven.io/docs/products/app-runtime)

## License

This deployment configuration is provided as-is. Apache Airflow is licensed under the Apache License 2.0.
