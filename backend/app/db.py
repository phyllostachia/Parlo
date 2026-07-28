"""Async database engine 和 session management。

后端将所有数据保存到一个 SQLite file，并通过 async SQLAlchemy engine 访问。SQLite 使用
WAL journal mode，使 read 和 write 不会互相阻塞；当 streaming response 写入 token 而
客户端同时读取会话历史时，这一点很重要。

此 module 提供 FastAPI dependency（:func:`get_session`），为每个 request 生成一个
:class:`AsyncSession`，并提供创建 schema 的 :func:`init_db`。application factory 也会
在启动时自动创建 schema。
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
"""绑定到已配置 SQLite database 的 process-wide async engine。"""


@event.listens_for(engine.sync_engine, "connect")
def _enable_sqlite_wal(dbapi_connection, _connection_record) -> None:
    """为每个新的 SQLite connection 启用 WAL journal mode 和合理的 foreign-key policy。

    WAL 允许 reader 与单个 writer 共存，这是 streaming 时的常见情况：SSE handler 写入
    token，而另一个 request 可能正在列出会话。启用 foreign key 可以保持 ``parent_id``
    和 ``current_leaf_id`` 关系一致。
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
"""用于创建 request-scoped async session 的 factory。

``expire_on_commit=False`` 会使已加载的 attribute 在 commit 后仍可用，这很方便，因为
handler 经常需要先 commit，再将 object 返回给客户端。"""


async def get_session() -> AsyncIterator[AsyncSession]:
    """生成 session 并在发生错误时 rollback 的 FastAPI dependency。

    使用 ``async with`` 可以保证即使 handler 抛出异常，session 也会返回连接池。
    ``except`` branch 会调用 ``rollback``，避免失败 request 留下未提交的 transaction
    并一直占用 SQLite write lock。
    """
    async with async_session_maker() as session:
        try:
            yield session
        except Exception:
            await session.rollback()
            raise


async def init_db() -> None:
    """创建 SQLModel metadata 定义的所有 table，并迁移已有 SQLite 数据库。

    这里才导入（而不是在 module top 导入），使 ``models`` 只在确实需要创建 schema 时
    加载，从而避免 ``db`` 与 ``models`` 之间的 circular import。
    """
    from . import models  # noqa: F401  (registers metadata)

    async with engine.begin() as conn:
        await conn.run_sync(models.SQLModel.metadata.create_all)
        if engine.url.get_backend_name() == "sqlite":
            columns = {
                row[1]
                for row in (
                    await conn.exec_driver_sql("PRAGMA table_info(conversation)")
                )
            }
            if "thinking_enabled" not in columns:
                await conn.exec_driver_sql(
                    "ALTER TABLE conversation "
                    "ADD COLUMN thinking_enabled BOOLEAN NOT NULL DEFAULT 0"
                )
            message_columns = {
                row[1]
                for row in (await conn.exec_driver_sql("PRAGMA table_info(message)"))
            }
            if "reasoning_duration_ms" not in message_columns:
                await conn.exec_driver_sql(
                    "ALTER TABLE message ADD COLUMN reasoning_duration_ms INTEGER"
                )
