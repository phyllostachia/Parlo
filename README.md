# 开发计划

- 前端构建目标迁移到 WASM
- 客户端

# 开发者如何部署本项目

以下命令属于 Windows 平台。如果您使用 macOS 或 Linux 平台，请自行使用对应指令。

```bash
# 启动前端
Set-Location .\frontend
flutter run
```

```bash
# 配置 config.yaml 和 .env
Copy-Item .\backend\config.yaml.example .\backend\config.yaml
Copy-Item .\backend\.env.example .\backend\.env
```

```bash
# 启动后端
Set-Location .\backend
python -m venv .venv
.\.venv\Scripts\activate.ps1
python -m pip install -e ".[dev]"
uvicorn app.main:app --host 0.0.0.0 --port 8000
```
