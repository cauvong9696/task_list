# Task List

A Rails 8.1 + PostgreSQL application.

## Requirements

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose (bundled with Docker Desktop).

No need to install Ruby, PostgreSQL, etc. directly on your machine — everything runs in containers.

## Running the development environment (Docker)

```bash
# Build the image and start web + database
docker compose up --build
```

The first run automatically installs gems, then creates and migrates the database.
Once it's up, open the app at: http://localhost:3000

Other common commands:

```bash
# Start in the background
docker compose up -d

# Follow logs
docker compose logs -f web

# Stop (keep database data)
docker compose down

# Stop and REMOVE database data
docker compose down -v
```

### Running commands inside the container

```bash
# Open a shell in the web container
docker compose exec web bash

# Run rails/rake commands
docker compose exec web bin/rails console
docker compose exec web bin/rails db:migrate

# Run the test suite
docker compose exec web bin/rails test

# Install new gems after editing the Gemfile
docker compose exec web bundle install
# or rebuild the image:
docker compose build web

# Run ci tests (lint, typecheck, test)
docker compose exec web bin/ci
```

## Docker file overview

| File                 | Purpose                                                              |
| -------------------- | ------------------------------------------------------------------- |
| `Dockerfile`         | **Production** image, used by Kamal for deployment.                 |
| `Dockerfile.dev`     | **Development** image (installs dev/test gems, supports live reload).|
| `docker-compose.yml` | Defines the `web` + `db` services for the development environment.  |

- The source code is mounted into the container, so code changes are reflected
  immediately without rebuilding the image.
- Gems and PostgreSQL data are stored in Docker volumes (`bundle`, `postgres_data`),
  so they persist across restarts.

### Database connection

Connection settings are passed via environment variables in `docker-compose.yml`
(`DB_HOST`, `DB_USERNAME`, `DB_PASSWORD`) and read in `config/database.yml`.
When running Rails directly on your machine (not through Docker) without these
variables set, the app falls back to the default PostgreSQL configuration as before.

## Deployment

Deploy with [Kamal](https://kamal-deploy.org) using the `Dockerfile` (production)
and `config/deploy.yml`.
