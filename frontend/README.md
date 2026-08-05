# Tan 前端

用 Flutter 构建的跨平台前端，支持 Web、Android。

## 运行

```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 重新生成 *.freezed.dart / *.g.dart
flutter run -d chrome
```

```bash
flutter build web --release /
```

## 测试

```bash
flutter test
```
