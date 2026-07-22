# 开发计划

- 更新 frontend\design.pen `Chat - Token Auth Modal` `Chat - Settings Panel`
- 按照 frontend\design.pen 优化 UI
- 前端工程化、容器化
- 后端容器化
- 优化 `frontend/README.md` `backend/README.md`
- 前端构建目标迁移到 WASM
- 完善 `README.md`

# 开发者如何部署本项目

以下命令属于 Windows 平台。如果您使用 macOS 或 Linux 平台，请自行使用对应指令。

```bash
# 启动前端
cd .\frontend
flutter run
```

```bash
# 配置 config.yaml 和 .env
cp .\backend\config.yaml.example .\backend\config.yaml
cp .\backend\.env.example .\backend\.env
```

```bash
# 启动后端
cd .\backend
python -m venv .venv
python install -e ".[dev]"
.\.venv\Scripts\activate.ps1
uvicorn app.main:app --host 0.0.0.0 --port 8000
```
