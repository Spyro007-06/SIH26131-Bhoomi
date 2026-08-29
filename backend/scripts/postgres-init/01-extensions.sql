-- Runs once, on first initialisation of the postgres data volume.
--
-- The postgis/postgis image ships PostGIS but not pgvector, so pgvector is
-- installed in the Dockerfile alongside this file. Both extensions are created
-- here AND asserted by the first Alembic migration: this script only runs on a
-- fresh volume, so the migration is what guarantees them on an existing one.

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS vector;
