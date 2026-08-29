# scripts/

- `postgres-init/` — mounted into the postgres container's
  `docker-entrypoint-initdb.d`. Runs **only** on a fresh data volume, which is
  why `alembic/versions/0001_extensions.py` also creates the extensions.

Operational scripts (seed loaders, demo reset) land here as later phases need them.
