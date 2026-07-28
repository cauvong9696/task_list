# Shortcuts for the Docker-based development workflow.
# Run `make help` to list the available targets.

COMPOSE := docker compose
# Run one-off commands in the web container. Uses a running container if there
# is one (fast), otherwise spins up a throwaway one.
EXEC := $(COMPOSE) exec web
RUN  := $(COMPOSE) run --rm web

.DEFAULT_GOAL := help

.PHONY: help build up upd down clean logs shell console \
        migrate rollback prepare seed reset \
        test lint lint-fix security ci routes restart

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
		| sort \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

## --- Container lifecycle ---

build: ## Build (or rebuild) the images
	$(COMPOSE) build

up: ## Start web + db in the foreground
	$(COMPOSE) up

upd: ## Start web + db in the background
	$(COMPOSE) up -d

down: ## Stop containers (keep database data)
	$(COMPOSE) down

clean: ## Stop containers AND remove database data
	$(COMPOSE) down -v

restart: ## Restart the web container
	$(COMPOSE) restart web

logs: ## Follow the web logs
	$(COMPOSE) logs -f web

## --- Shells & consoles ---

shell: ## Open a bash shell in the web container
	$(EXEC) bash

console: ## Open a Rails console
	$(EXEC) bin/rails console

## --- Database ---

migrate: ## Run pending migrations
	$(EXEC) bin/rails db:migrate

rollback: ## Roll back the last migration
	$(EXEC) bin/rails db:rollback

prepare: ## Create + migrate the database (idempotent)
	$(EXEC) bin/rails db:prepare

seed: ## Load db/seeds.rb
	$(EXEC) bin/rails db:seed

reset: ## Drop, recreate, and migrate the database
	$(EXEC) bin/rails db:reset

## --- Quality ---

test: ## Run the test suite (prepares the test DB first)
	$(EXEC) bin/rails db:test:prepare test

lint: ## Run RuboCop
	$(EXEC) bin/rubocop

lint-fix: ## Run RuboCop with autocorrect
	$(EXEC) bin/rubocop -A

security: ## Run Brakeman
	$(EXEC) bin/brakeman

ci: ## Run the full CI suite (lint, security, test)
	$(EXEC) bin/ci

routes: ## List all routes
	$(EXEC) bin/rails routes
