# Tan 后端

Tan 的自托管、单用户后端。
它负责管理 SQLite 数据库，并将流式聊天请求代理到两种上游 model-provider protocol 之一。

## 配置

配置分为两个文件：

- `.env` 仅保存密钥（`AUTH_TOKEN` 和 `*_API_KEY`）
- `config.yaml` 保存其他配置

每个会话只绑定一个模型；深度思考开关会按会话保存。
每次请求时，后端根据该开关从模型配置中选择 `thinking_off_effort` 或 `thinking_on_effort`，并将对应 effort 转发给上游。

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

## 运行

```bash
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

API 位于 `/api` 路径下。上传的图片位于 `/images` 路径下。

## API 概览

| Method | Path                                                      | Description                             |
| ------ | --------------------------------------------------------- | --------------------------------------- |
| GET    | `/api/health`                                             | 存活探针（无需鉴权）                    |
| GET    | `/api/models`                                             | 列出可用模型和默认模型（决定客户端 UI） |
| GET    | `/api/profiles`                                           | 列出 profile                            |
| POST   | `/api/profiles`                                           | 创建 profile                            |
| PATCH  | `/api/profiles/{id}`                                      | 重命名 profile                          |
| DELETE | `/api/profiles/{id}`                                      | 删除 profile                            |
| GET    | `/api/profiles/{id}/conversations`                        | 列出会话                                |
| POST   | `/api/profiles/{id}/conversations`                        | 创建会话（绑定模型）                    |
| GET    | `/api/conversations/{id}`                                 | 获取会话                                |
| PATCH  | `/api/conversations/{id}`                                 | 更新 title / thinking_enabled           |
| DELETE | `/api/conversations/{id}`                                 | 删除会话                                |
| GET    | `/api/conversations/{id}/messages`                        | 获取可见消息路径                        |
| POST   | `/api/conversations/{id}/messages`                        | 创建 user 消息和 assistant 占位消息     |
| POST   | `/api/conversations/{id}/messages/{parent_id}/regenerate` | 创建新的 assistant 占位消息             |
| POST   | `/api/conversations/{id}/messages/{leaf_id}/switch`       | 切换可见分支                            |
| DELETE | `/api/conversations/{id}/messages/{id}`                   | 删除消息子树                            |
| GET    | `/api/chat/stream?message_id=...`                         | SSE token 流                            |

除 `/api/health` 外，所有 endpoint 都要求提供 `Authorization: Bearer <token>`。SSE endpoint 也可以使用 `?token=<token>`，因为浏览器的 `EventSource` 无法设置 header。

## 测试

```bash
pytest
```
