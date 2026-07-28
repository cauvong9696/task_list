# Task List

A Rails 8.1 + PostgreSQL application.

## Requirements

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose (bundled with Docker Desktop).

No need to install Ruby, PostgreSQL, etc. directly on your machine — everything runs in containers.

## Running the development environment (Docker)

A `Makefile` wraps the common Docker/Rails commands. Run `make help` to see all
available targets. (The raw `docker compose ...` equivalents still work if you
prefer them.)

```bash
# Build the image and start web + database
make build
make up
```

The first run automatically installs gems, then creates and migrates the database.
Once it's up, open the app at: http://localhost:3000

Other common commands:

```bash
# Start in the background
make upd

# Follow logs
make logs

# Stop (keep database data)
make down

# Stop and REMOVE database data
make clean
```

### Running commands inside the container

```bash
# Open a shell in the web container
make shell

# Open a Rails console
make console

# Run pending migrations
make migrate

# Run the test suite (prepares the test DB first)
make test

# Install new gems after editing the Gemfile: rebuild the image
make build

# Run the full CI suite (lint, security, test)
make ci
```

> Prefer plain Docker? The same actions are, e.g., `docker compose up --build`,
> `docker compose exec web bin/rails console`, and `docker compose exec web bin/ci`.

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
