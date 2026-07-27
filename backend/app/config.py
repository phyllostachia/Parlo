"""将应用配置拆分到 ``.env``（密钥）和 ``config.yaml``。

密钥（共享 ``AUTH_TOKEN`` 和每个 provider 的 ``*_API_KEY``）存放在 ``.env``，并通过
pydantic-settings 读取。其他配置（model registry、server CORS、database path、image
storage）位于 ``config.yaml``，由 :func:`load_config` 解析为强类型的 :class:`AppConfig`
tree。

拆分这两个文件后，``config.yaml`` 可以提交到 version control，而 ``.env`` 保持
git-ignored。``config.yaml`` 中的每个 model 都通过 environment-variable name
（``api_key`` field）引用自己的 API key，因此实际密钥不会出现在 YAML 中。

单个 :class:`Settings` instance 会组合解析后的 ``auth_token`` 和 :class:`AppConfig`；
它由 :func:`get_settings` 在 import time 创建，并在 process lifetime 内缓存。
"""

from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path
from typing import Literal

import yaml
from pydantic import BaseModel, Field, field_validator, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


ProviderType = Literal["openai-response", "anthropic-message"]
"""provider abstraction layer 支持的两种上游 protocol。"""

FamilyType = Literal["anthropic", "openai"]
"""两种 provider family，决定客户端渲染哪个 logo。"""


class ModelConfig(BaseModel):
    """``config.yaml`` 的 ``models`` list 中的一个 entry。

    ``api_key`` field 是 environment variable 的 *name*（例如 ``OPENAI_API_KEY``），而
    不是 secret 本身。:func:`load_config` 会在启动时校验该变量存在且非空；adapter 构建
    request 时通过 :func:`resolve_api_key` 读取它的 value。
    """

    id: str
    """发送给上游 provider 的 model identifier（例如 ``gpt-5.6``）。"""

    display_name: str
    """客户端显示的可读名称。"""

    api_key: str
    """保存上游 API key 的 environment variable name。"""

    base_url: str
    """上游 base URL，不带 trailing slash。"""

    family: FamilyType
    """provider family，决定客户端的 logo。"""

    protocol: ProviderType
    """上游 protocol，决定 request wire format 和客户端可选择的 thinking-effort level 集合。"""

    vision: bool
    """model 是否接受 image input。当值为 ``False`` 时，客户端隐藏 multimodal upload button。"""

    thinking_effort: list[str]
    """model 接受的 thinking-effort level，按客户端应提供的顺序排列。创建新 conversation
    时使用第一个 entry 作为默认值（参见决策 D05）。"""

    max_tokens: int
    """发送给上游的 output budget（thinking + visible text），作为 generated token 的硬上限。
    它不是 thinking-control field。"""

    @field_validator("base_url")
    @classmethod
    def _strip_trailing_slash(cls, value: str) -> str:
        """移除 trailing slash，使 URL joining 结果可预测。"""
        return value.rstrip("/")

    @field_validator("thinking_effort")
    @classmethod
    def _non_empty_efforts(cls, value: list[str]) -> list[str]:
        """没有 effort level 的 model 无法为客户端提供可选项。"""
        if not value:
            raise ValueError("thinking_effort must list at least one level")
        return value

    def resolve_api_key(self) -> str:
        """从 environment 返回该 model 引用的实际 secret。

        采用 lazy lookup，因此在 request 之间替换 ``.env`` 中的 key（虽然少见，但测试
        中可能发生）后，不需要重新加载 config 就能生效。
        """
        value = os.environ.get(self.api_key)
        if not value:
            raise RuntimeError(
                f"environment variable {self.api_key!r} referenced by model "
                f"{self.id!r} is not set or is empty"
            )
        return value


class ServerConfig(BaseModel):
    """不包含 secret 的 server runtime parameter。"""

    cors_origins: list[str] = Field(default_factory=list)
    """CORS 允许的 origin。Flutter Web build 运行在独立 origin，因此必须在这里列出用户
    访问的 address。"""


class DatabaseConfig(BaseModel):
    """SQLite database 使用的 async SQLAlchemy URL。"""

    # 保留旧数据库文件名，避免改名后默认创建一份空数据库。
    url: str = "sqlite+aiosqlite:///./data/parlo.db"


class ImagesConfig(BaseModel):
    """Image upload storage parameter。"""

    upload_dir: str = "./data/images"
    """存储上传图片的 filesystem directory。"""

    max_bytes: int = 10 * 1024 * 1024
    """单张上传图片的最大 size，单位为 bytes。"""


class AppConfig(BaseModel):
    """解析后的 ``config.yaml`` tree。

    ``default_model`` 必须引用 ``models`` 中某个 entry 的 ``id``；解析后由
    :func:`load_config` 检查这一点。
    """

    default_model: str
    """创建新 conversation 且没有明确选择时使用的 model id。必须匹配某个 ``models`` id。"""

    server: ServerConfig = Field(default_factory=ServerConfig)
    database: DatabaseConfig = Field(default_factory=DatabaseConfig)
    images: ImagesConfig = Field(default_factory=ImagesConfig)
    models: list[ModelConfig]

    @model_validator(mode="after")
    def _validate_default_model(self) -> AppConfig:
        """确保 ``default_model`` 指向 ``models`` 中真实存在的 entry。"""
        ids = {m.id for m in self.models}
        if self.default_model not in ids:
            raise ValueError(
                f"default_model {self.default_model!r} is not listed in models"
            )
        return self

    def get_model(self, model_id: str) -> ModelConfig | None:
        """返回给定 id 对应的 model；找不到时返回 ``None``。"""
        for model in self.models:
            if model.id == model_id:
                return model
        return None


class Settings(BaseSettings):
    """Process-wide settings：``.env`` 中的 shared secret 加上解析后的 ``config.yaml`` tree。

    model_config 保持 ``extra="ignore"``，因此仍包含已弃用 provider key（``PROVIDER_*``）
    的旧 ``.env`` 不会导致启动失败；这些 key 会被直接忽略。
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    auth_token: str
    """客户端每次 API request 都必须发送的 shared bearer token。"""

    app_config: AppConfig
    """由 :func:`get_settings` 注入的已解析 ``config.yaml`` tree。"""


def load_config(path: str | Path = "config.yaml") -> AppConfig:
    """将 ``config.yaml`` 解析为 :class:`AppConfig` 并进行校验。

    除了 :class:`AppConfig` 的 Pydantic-level validation，此函数还会检查每个 model 的
    ``api_key`` environment variable 存在且非空，使配置错误的 deployment 在启动时快速
    失败，而不是等到第一次 chat request 才失败。
    """
    config_path = Path(path)
    with config_path.open("r", encoding="utf-8") as handle:
        raw = yaml.safe_load(handle) or {}
    app_config = AppConfig.model_validate(raw)

    for model in app_config.models:
        # 现在读取 environment variable，使引用的 secret 缺失时能够明确地在启动失败。
        # 该 value 会在 request time 重新读取。
        if not os.environ.get(model.api_key):
            raise RuntimeError(
                f"environment variable {model.api_key!r} referenced by model "
                f"{model.id!r} is not set or is empty; add it to .env"
            )
    return app_config


@lru_cache
def get_settings() -> Settings:
    """返回 process-wide :class:`Settings` instance。

    config path 默认为当前 working directory 中的 ``config.yaml``，优先通过
    ``TAN_CONFIG_PATH`` environment variable 覆盖；未设置时兼容读取旧的
    ``PARLO_CONFIG_PATH``，这方便测试指向临时文件。

    在运行 :func:`load_config` 前，``.env`` 会被显式加载到 ``os.environ``，因此检查每个
    model 的 ``api_key`` environment variable 的 startup validation 可以看到 ``.env``
    中声明的 key（pydantic-settings 只将 ``.env`` 解析到 :class:`Settings` instance，
    不会填充 ``os.environ``）。

    结果会被缓存，使文件只解析一次。需要不同值的测试可以修改 environment 或 config
    file 后调用 ``get_settings.cache_clear()``。
    """
    # 将 .env 中的 secret 放入 os.environ，使 load_config 的 api_key check 和 request
    # time 的 ModelConfig.resolve_api_key() 都能读取它们。
    from dotenv import load_dotenv

    load_dotenv()
    config_path = os.environ.get("TAN_CONFIG_PATH") or os.environ.get(
        "PARLO_CONFIG_PATH", "config.yaml"
    )
    app_config = load_config(config_path)
    return Settings(auth_token=os.environ.get("AUTH_TOKEN", ""), app_config=app_config)
