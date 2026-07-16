"""Async database engine and session management.

The backend stores all data in a single SQLite file accessed through an async
SQLAlchemy engine. SQLite is configured with WAL journal mode so that reads
and writes do not block each other, which matters while a streaming response
writes tokens and the client simultaneously reads conversation history.

The module exposes a FastAPI dependency (:func:`get_session`) that yields an
:class:`AsyncSession` for each request, and :func:`init_db` which creates the
schema. The schema is also created automatically on startup by the
application factory.
"""

from __future__ import annotations

from collections.abc import AsyncIterator

from sqlalchemy import event
from sqlalchemy.ext.asyncio import AsyncEngine, AsyncSession, async_sessionmaker, create_async_engine

from .config import get_settings


engine: AsyncEngine = create_async_engine(
    get_settings().app_config.database.url,
    echo=False,
    future=True,
)
"""Process-wide async engine bound to the configured SQLite database."""


@event.listens_for(engine.sync_engine, "connect")
def _enable_sqlite_wal(dbapi_connection, _connection_record) -> None:
    """Enable WAL journal mode and a sane foreign-key policy on every new
    SQLite connection.

    WAL allows readers and a single writer to coexist, which is the common
    case during streaming: the SSE handler writes tokens while another
    request may list conversations. Foreign keys are turned on so that the
    ``parent_id`` and ``current_leaf_id`` relationships stay consistent.
    """
    cursor = dbapi_connection.cursor()
    cursor.execute("PRAGMA journal_mode=WAL")
    cursor.execute("PRAGMA foreign_keys=ON")
    cursor.close()


async_session_maker: async_sessionmaker[AsyncSession] = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
)
"""Factory for request-scoped async sessions.

``expire_on_commit=False`` keeps loaded attributes usable after commit,
which is convenient because handlers often commit and then return the
object to the client."""


async def get_session() -> AsyncIterator[AsyncSession]:
    """FastAPI dependency that yields a session and rolls back on error.

    Using ``async with`` ensures the session is returned to the pool even if
    the handler raises. ``rollback`` is called in the ``except`` branch so a
    failed request does not leave an uncommitted transaction pinning the
    SQLite write lock.
    """
    async with async_session_maker() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise


async def init_db() -> None:
    """Create all tables defined by the SQLModel metadata.

    Imported here (not at module top) so that ``models`` is only loaded when
    the schema actually needs to be created, avoiding a circular import
    between ``db`` and ``models``.
    """
    from . import models  # noqa: F401  (registers metadata)

    async with engine.begin() as conn:
        await conn.run_sync(models.SQLModel.metadata.create_all)
