"""Parlo backend application package.

This package implements the self-hosted, single-user backend for the Parlo
BYOK AI Chatbot. It exposes a FastAPI application that owns the SQLite
database, proxies streaming chat requests to one of two supported model
provider protocols (OpenAI Response API or Anthropic Message API), and serves
uploaded images back to the Flutter client.
"""
