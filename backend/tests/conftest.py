"""共享测试 fixture 和 environment setup。

在 import application 之前设置 environment variable 和临时 ``config.yaml``，使
:mod:`app.db` 中的 module-level database engine 绑定到临时 SQLite file。每个 test 通过
``_clean_db`` autouse fixture 从干净 database 开始，``client`` fixture 提供连接到 ASGI app
的已鉴权 async HTTP client。

这里需要 config file 而不只是 env var，因为 model definition 现在位于 ``config.yaml``；
测试将 ``TAN_CONFIG_PATH`` 指向 temp file，因此 test process 不会触碰 operator 的真实
``config.yaml``。
"""

from __future__ import annotations

import os
import tempfile

_tmp_dir = tempfile.mkdtemp(prefix="tan-test-")
os.environ.setdefault("AUTH_TOKEN", "test-token")
os.environ.setdefault("OPENAI_API_KEY", "sk-test")
os.environ.setdefault("ANTHROPIC_API_KEY", "sk-ant-test")

# 为 test process 写入临时 config.yaml。两个 model 覆盖两种 protocol，使 provider 和 API
# test 可以分别测试两种 family。
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
os.environ.setdefault("TAN_CONFIG_PATH", _config_path)

# 确保缓存的 Settings 使用测试 environment。
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
    """在每个 test 前重置所有 table，以保证隔离。

    清空期间关闭 foreign key，因此删除顺序无关紧要；下一个 connection 会由
    :mod:`app.db` 中的 ``connect`` event listener 重新启用它们。
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
    """连接到 ASGI app 的已鉴权 async HTTP client。"""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as c:
        c.headers["Authorization"] = "Bearer test-token"
        yield c


@pytest_asyncio.fixture
async def client_unauth() -> AsyncIterator[AsyncClient]:
    """用于测试 auth rejection 的未鉴权 client。"""
    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as c:
        yield c
