# Parlo Backend

Self-hosted, single-user backend for the Parlo BYOK AI Chatbot.
It owns the SQLite database and proxies streaming chat requests to one of two upstream model-provider protocols.

## Configuration

Configuration is split across two files:

- **`.env`** — secrets only: `AUTH_TOKEN` and each provider's `*_API_KEY`. This file is git-ignored and never committed.
- **`config.yaml`** — everything else: the model registry, CORS origins, database path, image storage.

Each model in `config.yaml` declares:

- `id`
- `display_name`
- `api_key`, the variable name in env
- `base_url`
- `family`
- `protocol`, 'openai-response' or 'claude-message'
- `vision`
- the list of supported `thinking_effort` levels
- `max_tokens`

Conversations are bound to a single model; the selected thinking-effort level is stored per conversation and forwarded to the upstream.

## Supported providers

Two protocols:

- `openai-response` — OpenAI Responses API (`/v1/responses`)
- `anthropic-message` — Anthropic Messages API (`/v1/messages`)

Thinking control uses the current effort-based APIs on both sides:

- `reasoning.effort` for OpenAI
- `thinking.type: "adaptive"` with `thinking.effort` for Anthropic.

## Setup

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
cp config.yaml.example config.yaml   # edit models/origins as needed
cp .env.example .env                 # fill in AUTH_TOKEN and *_API_KEY
```

The config file path defaults to `config.yaml` in the current working directory; override it with the `PARLO_CONFIG_PATH` environment variable.

## Run

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

The API is served under `/api`. Uploaded images are served under `/images`.

## API overview

| Method | Path                                                      | Description                                         |
| ------ | --------------------------------------------------------- | --------------------------------------------------- |
| GET    | `/api/health`                                             | Liveness probe (no auth)                            |
| GET    | `/api/models`                                             | List available models + default (decides client UI) |
| GET    | `/api/profiles`                                           | List profiles                                       |
| POST   | `/api/profiles`                                           | Create profile                                      |
| PATCH  | `/api/profiles/{id}`                                      | Rename profile                                      |
| DELETE | `/api/profiles/{id}`                                      | Delete profile                                      |
| GET    | `/api/profiles/{id}/conversations`                        | List conversations                                  |
| POST   | `/api/profiles/{id}/conversations`                        | Create conversation (binds a model)                 |
| GET    | `/api/conversations/{id}`                                 | Get conversation                                    |
| PATCH  | `/api/conversations/{id}`                                 | Update title / thinking_effort                      |
| DELETE | `/api/conversations/{id}`                                 | Delete conversation                                 |
| GET    | `/api/conversations/{id}/messages`                        | Get visible message path                            |
| POST   | `/api/conversations/{id}/messages`                        | Create user message + assistant placeholder         |
| POST   | `/api/conversations/{id}/messages/{parent_id}/regenerate` | New assistant placeholder                           |
| POST   | `/api/conversations/{id}/messages/{leaf_id}/switch`       | Switch visible branch                               |
| DELETE | `/api/conversations/{id}/messages/{id}`                   | Delete message subtree                              |
| GET    | `/api/chat/stream?message_id=...`                         | SSE token stream                                    |

All endpoints except `/api/health` require `Authorization: Bearer <token>` (or `?token=<token>` for the SSE endpoint, since browser `EventSource` cannot set headers).

## Message tree

Messages form a tree within a conversation.
Each conversation tracks `current_leaf_id`; the visible path is reconstructed by walking `parent_id` from the leaf to the root.
Sibling messages under the same parent are alternative replies; switching between them is done by moving the conversation's `current_leaf_id`.

## Tests

```bash
pytest
```
