"""Application configuration split across ``.env`` (secrets) and ``config.yaml``.

Secrets (the shared ``AUTH_TOKEN`` and each provider's ``*_API_KEY``) live in
``.env`` and are read through pydantic-settings. Everything else — the model
registry, server CORS, database path, image storage — lives in ``config.yaml``
and is parsed into a strongly typed :class:`AppConfig` tree by
:func:`load_config`.

The two files are separated so ``config.yaml`` can be checked into version
control while ``.env`` stays git-ignored. Each model in ``config.yaml``
references its API key by environment-variable name (the ``api_key`` field),
so the actual secret never appears in the YAML.

A single :class:`Settings` instance bundles the resolved ``auth_token`` and the
parsed :class:`AppConfig`; it is created at import time by
:func:`get_settings` and cached for the process lifetime.
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
"""The two upstream protocols supported by the provider abstraction layer."""

FamilyType = Literal["anthropic", "openai"]
"""The two provider families. Decides which logo the client renders."""


class ModelConfig(BaseModel):
    """One entry in the ``models`` list of ``config.yaml``.

    The ``api_key`` field is the *name* of an environment variable (for example
    ``OPENAI_API_KEY``), not the secret itself. :func:`load_config` validates
    that the named variable is present and non-empty at startup; adapters
    read the value through :func:`resolve_api_key` when building requests.
    """

    id: str
    """Model identifier sent to the upstream provider (e.g. ``gpt-5.6``)."""

    display_name: str
    """Human-readable name shown in the client."""

    api_key: str
    """Name of the environment variable holding the upstream API key."""

    base_url: str
    """Upstream base URL, without a trailing slash."""

    family: FamilyType
    """Provider family; decides the client-side logo."""

    protocol: ProviderType
    """Upstream protocol; decides the request wire format and the set of
    thinking-effort levels the client may choose from."""

    vision: bool
    """Whether the model accepts image input. The client hides the
    multimodal upload button when this is ``False``."""

    thinking_effort: list[str]
    """Thinking-effort levels this model accepts, in the order the client
    should offer them. The first entry is used as the default when a new
    conversation is created (see decision D05)."""

    max_tokens: int
    """Output budget (thinking + visible text) sent to the upstream as the
    hard cap on generated tokens. Not a thinking-control field."""

    @field_validator("base_url")
    @classmethod
    def _strip_trailing_slash(cls, value: str) -> str:
        """Remove a trailing slash so URL joining is predictable."""
        return value.rstrip("/")

    @field_validator("thinking_effort")
    @classmethod
    def _non_empty_efforts(cls, value: list[str]) -> list[str]:
        """A model with no effort levels gives the client nothing to pick."""
        if not value:
            raise ValueError("thinking_effort must list at least one level")
        return value

    def resolve_api_key(self) -> str:
        """Return the actual secret this model references from the environment.

        Looked up lazily so that swapping keys in ``.env`` between requests
        (rare, but possible in tests) is reflected without reloading config.
        """
        value = os.environ.get(self.api_key)
        if not value:
            raise RuntimeError(
                f"environment variable {self.api_key!r} referenced by model "
                f"{self.id!r} is not set or is empty"
            )
        return value


class ServerConfig(BaseModel):
    """Non-secret server runtime parameters."""

    cors_origins: list[str] = Field(default_factory=list)
    """Origins permitted by CORS. The Flutter web build runs on a separate
    origin, so the address users visit must be listed here."""


class DatabaseConfig(BaseModel):
    """Async SQLAlchemy URL for the SQLite database."""

    url: str = "sqlite+aiosqlite:///./data/parlo.db"


class ImagesConfig(BaseModel):
    """Image upload storage parameters."""

    upload_dir: str = "./data/images"
    """Filesystem directory used to store uploaded images."""

    max_bytes: int = 10 * 1024 * 1024
    """Maximum size of a single uploaded image, in bytes."""


class AppConfig(BaseModel):
    """The parsed ``config.yaml`` tree.

    ``default_model`` must reference the ``id`` of one of the entries in
    ``models``; this is checked by :func:`load_config` after parsing.
    """

    default_model: str
    """Model id used when a new conversation is created without an explicit
    choice. Must match one of the ``models`` ids."""

    server: ServerConfig = Field(default_factory=ServerConfig)
    database: DatabaseConfig = Field(default_factory=DatabaseConfig)
    images: ImagesConfig = Field(default_factory=ImagesConfig)
    models: list[ModelConfig]

    @model_validator(mode="after")
    def _validate_default_model(self) -> AppConfig:
        """Ensure ``default_model`` points at a real entry in ``models``."""
        ids = {m.id for m in self.models}
        if self.default_model not in ids:
            raise ValueError(
                f"default_model {self.default_model!r} is not listed in models"
            )
        return self

    def get_model(self, model_id: str) -> ModelConfig | None:
        """Return the model with the given id, or ``None`` if not found."""
        for model in self.models:
            if model.id == model_id:
                return model
        return None


class Settings(BaseSettings):
    """Process-wide settings: the shared secret from ``.env`` plus the parsed
    ``config.yaml`` tree.

    The model_config keeps ``extra="ignore"`` so an old ``.env`` that still
    carries deprecated provider keys (``PROVIDER_*``) does not crash startup;
    they are simply unused.
    """

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    auth_token: str
    """Shared bearer token that clients must send on every API request."""

    app_config: AppConfig
    """Parsed ``config.yaml`` tree, injected by :func:`get_settings`."""


def load_config(path: str | Path = "config.yaml") -> AppConfig:
    """Parse ``config.yaml`` into an :class:`AppConfig` and validate it.

    Beyond the Pydantic-level validation on :class:`AppConfig`, this function
    checks that every model's ``api_key`` environment variable is present and
    non-empty, so a misconfigured deployment fails fast at startup rather than
    on the first chat request.
    """
    config_path = Path(path)
    with config_path.open("r", encoding="utf-8") as handle:
        raw = yaml.safe_load(handle) or {}
    app_config = AppConfig.model_validate(raw)

    for model in app_config.models:
        # Touch the environment variable now so startup fails clearly if a
        # referenced secret is missing. The value is re-read at request time.
        if not os.environ.get(model.api_key):
            raise RuntimeError(
                f"environment variable {model.api_key!r} referenced by model "
                f"{model.id!r} is not set or is empty; add it to .env"
            )
    return app_config


@lru_cache
def get_settings() -> Settings:
    """Return the process-wide :class:`Settings` instance.

    The config path defaults to ``config.yaml`` in the current working
    directory but can be overridden with the ``PARLO_CONFIG_PATH`` environment
    variable, which is convenient for tests that want to point at a
    throwaway file.

    ``.env`` is loaded into ``os.environ`` explicitly before
    :func:`load_config` runs, so the startup validation that checks each
    model's ``api_key`` environment variable can see keys declared in
    ``.env`` (pydantic-settings only parses ``.env`` into the
    :class:`Settings` instance itself and does not populate ``os.environ``).

    The result is cached so that the files are parsed only once. Tests that
    need different values can call ``get_settings.cache_clear()`` after
    mutating the environment or the config file.
    """
    # Pull secrets from .env into os.environ so load_config's api_key check
    # and ModelConfig.resolve_api_key() at request time can both see them.
    from dotenv import load_dotenv

    load_dotenv()
    config_path = os.environ.get("PARLO_CONFIG_PATH", "config.yaml")
    app_config = load_config(config_path)
    return Settings(auth_token=os.environ.get("AUTH_TOKEN", ""), app_config=app_config)
