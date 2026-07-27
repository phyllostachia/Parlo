"""Tan 后端应用包。

此包实现 Tan BYOK AI Chatbot 的自托管、单用户后端。它提供 FastAPI 应用，负责
SQLite 数据库，将流式聊天请求代理到两种受支持的 model provider protocol（OpenAI
Response API 或 Anthropic Message API），并将上传的图片提供给 Flutter 客户端。
"""
