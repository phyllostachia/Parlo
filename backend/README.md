# Tan 后端

Tan BYOK AI Chatbot 的自托管、单用户后端。
它负责管理 SQLite 数据库，并将流式聊天请求代理到两种上游 model-provider protocol 之一。

## 配置

配置分为两个文件：

- **`.env`** — 仅保存密钥：`AUTH_TOKEN` 和各 provider 的 `*_API_KEY`。此文件被 git-ignored，永远不会提交。
- **`config.yaml`** — 保存其他所有配置：模型注册表、CORS 来源、数据库路径和图片存储位置。

`config.yaml` 中的每个模型都会声明：

- `id`
- `display_name`
- `api_key`，环境变量中的名称
- `base_url`
- `family`
- `protocol`，`openai-response` 或 `claude-message`
- `vision`
- 支持的 `thinking_effort` 级别列表
- `max_tokens`

每个会话只绑定一个模型；选定的 thinking-effort 级别会按会话保存，并转发给上游。

## 支持的 provider

支持两种 protocol：

- `openai-response` — OpenAI Responses API（`/v1/responses`）
- `anthropic-message` — Anthropic Messages API（`/v1/messages`）

两种 protocol 都使用当前基于 effort 的 API 控制 thinking：

- OpenAI 使用 `reasoning.effort`
- Anthropic 使用 `thinking.type: "adaptive"` 和 `thinking.effort`。

## 设置

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -e ".[dev]"
cp config.yaml.example config.yaml   # 按需编辑模型和来源
cp .env.example .env                 # 填写 AUTH_TOKEN 和 *_API_KEY
```

配置文件路径默认为当前工作目录中的 `config.yaml`；可以通过 `TAN_CONFIG_PATH` 环境变量覆盖。
为兼容旧部署，如果未设置该变量，也会读取 `PARLO_CONFIG_PATH`。

## 运行

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

API 位于 `/api` 路径下。上传的图片位于 `/images` 路径下。

## API 概览

| Method | Path                                                      | Description                                         |
| ------ | --------------------------------------------------------- | --------------------------------------------------- |
| GET    | `/api/health`                                             | 存活探针（无需鉴权）                                |
| GET    | `/api/models`                                             | 列出可用模型和默认模型（决定客户端 UI）             |
| GET    | `/api/profiles`                                           | 列出 profile                                       |
| POST   | `/api/profiles`                                           | 创建 profile                                       |
| PATCH  | `/api/profiles/{id}`                                      | 重命名 profile                                     |
| DELETE | `/api/profiles/{id}`                                      | 删除 profile                                       |
| GET    | `/api/profiles/{id}/conversations`                        | 列出会话                                           |
| POST   | `/api/profiles/{id}/conversations`                        | 创建会话（绑定模型）                                |
| GET    | `/api/conversations/{id}`                                 | 获取会话                                           |
| PATCH  | `/api/conversations/{id}`                                 | 更新 title / thinking_effort                       |
| DELETE | `/api/conversations/{id}`                                 | 删除会话                                           |
| GET    | `/api/conversations/{id}/messages`                        | 获取可见消息路径                                    |
| POST   | `/api/conversations/{id}/messages`                        | 创建 user 消息和 assistant 占位消息                 |
| POST   | `/api/conversations/{id}/messages/{parent_id}/regenerate` | 创建新的 assistant 占位消息                         |
| POST   | `/api/conversations/{id}/messages/{leaf_id}/switch`       | 切换可见分支                                        |
| DELETE | `/api/conversations/{id}/messages/{id}`                   | 删除消息子树                                        |
| GET    | `/api/chat/stream?message_id=...`                         | SSE token 流                                       |

除 `/api/health` 外，所有 endpoint 都要求提供 `Authorization: Bearer <token>`。SSE endpoint 也可以使用 `?token=<token>`，因为浏览器的 `EventSource` 无法设置 header。

## 消息树

消息会在一个会话中组成一棵树。
每个会话都会记录 `current_leaf_id`；可见路径通过从叶节点沿 `parent_id` 向根节点回溯来重建。
同一 parent 下的 sibling 消息是不同的回复版本；在它们之间切换，就是移动会话的 `current_leaf_id`。

## 测试

```bash
pytest
```
