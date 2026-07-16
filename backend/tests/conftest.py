"""Shared test fixtures and environment setup.

Environment variables and a throwaway ``config.yaml`` are set up before the
application is imported so the module-level database engine in :mod:`app.db`
binds to a throwaway SQLite file. Each test starts with a clean database via
the ``_clean_db`` autouse fixture, and the ``client`` fixture provides an
authenticated async HTTP client wired to the ASGI app.

The config file (not just env vars) is needed because model definitions now
live in ``config.yaml``; the tests point ``PARLO_CONFIG_PATH`` at a temp file
so the test process never touches the operator's real ``config.yaml``.
"""

from __future__ import annotations

import os
import tempfile

_tmp_dir = tempfile.mkdtemp(prefix="parlo-test-")
os.environ.setdefault("AUTH_TOKEN", "test-token")
os.environ.setdefault("OPENAI_API_KEY", "sk-test")
os.environ.setdefault("ANTHROPIC_API_KEY", "sk-ant-test")

# Write a throwaway config.yaml for the test process. Two models cover both
# protocols so the provider and API tests can exercise either family.
_config_path = os.path.join(_tmp_dir, "config.yaml")
with open(_config_path, "w", encoding="utf-8") as _handle:
    _handle.write(
        "default_model: test-openai\n"
        "server:\n"
        "  cors_origins:\n"
        "    - http://localhost:8080\n"
        f"database:\n  url: sqlite+aiosqlite:///{_tmp_dir}/test.db\n"
        f"images:\n  upload_dir: {_tmp_dir}/images\n  max_bytes: 10485760\n"
        "models:\n"
        "  - id: test-openai\n"
        "    display_name: Test OpenAI\n"
        "    api_key: OPENAI_API_KEY\n"
        "    base_url: https://api.openai.com/v1\n"
        "    family: openai\n"
        "    protocol: openai-response\n"
        "    vision: true\n"
        "    thinking_effort: [medium, low, high, xhigh]\n"
        "    max_tokens: 32768\n"
        "  - id: test-anthropic\n"
        "    display_name: Test Anthropic\n"
        "    api_key: ANTHROPIC_API_KEY\n"
        "    base_url: https://api.anthropic.com\n"
        "    family: anthropic\n"
        "    protocol: anthropic-message\n"
        "    vision: true\n"
        "    thinking_effort: [high, medium, low, xhigh, max]\n"
        "    max_tokens: 16384\n"
    )
os.environ.setdefault("PARLO_CONFIG_PATH", _config_path)

# Ensure the cached Settings pick up the test environment.
from app.config import get_settings  # noqa: E402

get_settings.cache_clear()

import pytest  # noqa: E402
import pytest_asyncio  # noqa: E402
from collections.abc import AsyncIterator  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402
from sqlmodel import text  # noqa: E402

from app.db import async_session_maker, init_db  # noqa: E402
from app.main import app  # noqa: E402


@pytest.fixture(autouse=True)
async def _clean_db():
    """Reset all tables before each test for isolation.

    Foreign keys are turned off during truncation so the order of deletes
    does not matter; they are re-enabled on the next connection by the
    ``connect`` event listener in :mod:`app.db`.
    """
    await init_db()
    async with async_session_maker() as session:
        await session.execute(text("PRAGMA foreign_keys=OFF"))
        await session.execute(text("DELETE FROM message"))
        await session.execute(text("DELETE FROM conversation"))
        await session.execute(text("DELETE FROM profile"))
        await session.execute(text("PRAGMA foreign_keys=ON"))
        await session.commit()
    yield


@pytest_asyncio.fixture
async def client() -> AsyncIterator[AsyncClient]:
    """An authenticated async HTTP client wired to the ASGI app."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as c:
        c.headers["Authorization"] = "Bearer test-token"
        yield c


@pytest_asyncio.fixture
async def client_unauth() -> AsyncIterator[AsyncClient]:
    """An unauthenticated client used to test auth rejection."""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c
