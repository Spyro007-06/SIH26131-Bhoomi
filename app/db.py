"""Async engine, session factory and the FastAPI session dependency.

Owner: Shreekumar. Spec: docs/DESIGN.md §1 (one database, three jobs).

Postgres carries relational rows, farm geometry for the PostGIS radius query and
the RAG vectors. There is one engine and one session dependency; no module opens
its own connection. `intelligence/` never touches this file at all — docs/
DESIGN.md §3: "intelligence/ never queries the DB directly; core/ hands it what
it needs."
"""

from __future__ import annotations

from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)
from sqlalchemy.orm import DeclarativeBase

from app.config import settings


class Base(DeclarativeBase):
    """Declarative base for every ORM model. Phase 1 fills app/core/models.py."""


engine: AsyncEngine = create_async_engine(
    settings.database_url,
    echo=settings.db_echo,
    pool_pre_ping=True,
)

SessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI dependency. One session per request, rolled back on exception."""
    async with SessionLocal() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise


async def dispose_engine() -> None:
    """Close the pool on shutdown."""
    await engine.dispose()
