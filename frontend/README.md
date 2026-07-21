# Parlo — Flutter Frontend

Parlo 的 Flutter 客户端。Parlo 是一款自托管、单用户的 BYOK（自带密钥）AI 聊天应用。当前优先支持 Web 平台，移动端（Android 与 iOS）的入口与平台差异已在第 8 阶段落地，但尚未在真机上验证构建。

本应用的产品文档位于
[`../.codeflicker/discuss/2026-07-16/parlo-frontend-web/product.md`](../.codeflicker/discuss/2026-07-16/parlo-frontend-web/product.md)，
架构设计位于
[`../.codeflicker/discuss/2026-07-17/parlo-flutter-architecture/architecture.md`](../.codeflicker/discuss/2026-07-17/parlo-flutter-architecture/architecture.md)。

## 当前状态

开发计划的第 0 至第 8 阶段已经完成。应用在 Web 上编译运行，`flutter analyze` 无任何警告，25 个单元测试与 widget 测试全部通过。第 9 阶段（深色主题）被有意推迟，原因见下文。

| 阶段 | 完成的内容 |
|------|-----------|
| 0 — 项目骨架 | `flutter create` 创建的 Web 项目、依赖声明、`build.yaml`、严格的 `analysis_options.yaml`、自托管的 Source Serif 4 与 Inter 字体、`main.dart` 和 `app.dart` |
| 1 — 核心层 | Freezed 数据模型、`AuthStore`、带鉴权拦截器的 `dio` 实例、SSE 字节流解析器、`PlatformCapabilities` 抽象及其 Web 实现、暖纸色浅色主题、带鉴权重定向的 `go_router` ShellRoute |
| 2 — 侧栏 | Profile 文件夹树（展开与折叠、悬停显示的「...」菜单、行内重命名、带确认的删除）、每个 profile 下的对话列表、设置入口 |
| 3 — 聊天基础 | 空状态页面（模型选择器 + 居中大输入框）、聊天页面（顶栏 + 消息列表 + 输入框）、消息气泡、`CurrentConversationNotifier` 的完整状态机以及 `stop()` |
| 4 — 聊天进阶 | 思考小条（可折叠，流式时显示脉冲指示器）、`< n/m >` 分支切换器、悬停操作条（复制 + 重新生成）、断流/停止后的「连接中断，重试」按钮、`regenerate()` 与 `switchBranch()` 状态机动作 |
| 5 — 鉴权与多模态 | 首次使用/401 专用 token 弹窗（同时询问后端地址）、`BaseUrlStore`（持久化后端地址）、图片附件（点击选择 + 拖拽，base64 data URL 转换，非 vision 模型禁用入口）、移动端平台能力与入口 |
| 6 — 错误边界与响应式 | 统一的 `ErrorBanner`（带重试按钮）替换会话与模型加载的裸文本错误、窄屏侧栏改为带遮罩的浮层抽屉（汉堡按钮切换） |
| 7 — 测试 | 在原有 12 个测试基础上新增 11 个：`regenerate`、`switchBranch` 状态机测试，`imageDataUrlFromBytes` 的 MIME 检测测试，token 弹窗的首用、保存关闭、已有 token 不弹出测试 |
| 8 — 移动端 | `MobilePlatformCapabilities`（`canDragImage=false`、`messageActions=always`）与 `main_mobile.dart` 入口。响应式侧栏抽屉复用第 6 阶段的实现。后端地址入口在所有平台一致，由 token 弹窗与设置面板统一收集 |

### 第 9 阶段（深色主题）的推迟原因

架构文档第 9 节明确写道：「v1 只做浅色，深色后补」、「深色主题等设计师补充 `design.md` 深色令牌后跟进」。当前 `design.md` 只包含浅色令牌，没有给出深色配色。在没有设计依据的情况下自行编造深色色值，会违背项目「可信任的」价值取向，也会违反架构文档对该阶段的明确约束。

为了在设计师补齐深色令牌后能低成本接入，相关基础设施已经就位：
- `ParloColors` 是一个 `ThemeExtension`，新增一个 `ParloColors.dark` 常量并实现 `lerp` 即可。
- `buildAppTheme()` 当前固定返回浅色 `ThemeData`，后续可改为根据主题选择返回浅色或深色。
- 设置面板中「Dark」与「Follow system」两个选项已经渲染，但被禁用并标注「Coming soon」，不会对用户谎称可用。

## 架构概要

应用的所有页面由 `riverpod` provider 驱动。侧栏读取 `profilesProvider` 和一个 `conversationsForProfileProvider` family；聊天页面读取 `currentConversationProvider`（一个 `autoDispose` family `AsyncNotifier`，以 conversation id 为参数）。

SSE 流式是 `send()` 操作的副作用，而非独立的状态源。调用 `POST /api/conversations/{id}/messages` 后，后端返回用户消息与一个空的 assistant 占位消息。Notifier 将这两条消息同时追加到本地消息路径中，然后打开 `GET /api/chat/stream?message_id=…`，在收到每一个 SSE 事件时更新路径末尾的 assistant 节点。

当用户在空状态页面发送第一条消息时，尚未创建对话。`ChatActionsNotifier.sendFirstMessage()` 负责创建对话并发送消息，随后将占位消息的 id 写入 `pendingStreamProvider`。导航到 `/c/{id}` 后，聊天页面的 notifier 在其 `build` 方法中检测到 pending 中有匹配的 id，立即启动 SSE 流式传输。

`regenerate()` 与 `switchBranch()` 是第 4 阶段新增的两个状态机动作。`regenerate` 调用 `POST .../messages/{parent_id}/regenerate`，在本地用新占位消息替换路径末尾的 assistant 节点、把新 id 追加到 siblings 列表，并打开 SSE。`switchBranch` 调用 `POST .../messages/{leaf_id}/switch`，用后端返回的完整路径直接替换本地状态，不打开 SSE。

## 运行方式

在生产环境中，应用可以与 Parlo 后端同域部署，也可以跨域部署——用户在应用内指定后端地址即可。本地开发时：

```bash
cd frontend
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # 重新生成 *.freezed.dart / *.g.dart
flutter run -d chrome
```

首次启动时，应用会弹出弹窗要求输入 bearer token 和后端地址（域名 + 端口）。token 需要与后端 `.env` 文件中的 `AUTH_TOKEN` 一致；后端地址是 Parlo 后端的访问入口，例如 `localhost:8000`（本地开发）或 `parlo.example.com:443`（生产部署）。两个值都持久化在 `shared_preferences` 中，后续可以在侧栏齿轮的设置面板里随时修改。

跨域部署时，后端需要开放 CORS（允许前端的来源域）。这是后端的配置，前端无法绕过。

在移动端运行（需要连接设备或模拟器，本次会话未在真机验证）：

```bash
flutter run -t lib/main_mobile.dart -d <device>
```

`main_mobile.dart` 用 `MobilePlatformCapabilities` 覆写 `platformCapabilitiesProvider`，隐藏拖拽区、让消息操作条常驻显示。后端地址入口在所有平台一致，由 token 弹窗与设置面板统一收集；`BaseUrlStore` 持久化到 `shared_preferences`，`dioProvider` 会据此重建 dio 实例。

## 测试

```bash
flutter test
```

25 个测试覆盖以下场景：
- 应用启动后正确渲染空状态页面标题（1 个 widget 测试）
- 侧栏渲染文件夹列表与空状态提示（2 个 widget 测试）
- SSE 解析器正确拆分事件、处理跨块边界的情况、解析所有事件类型、忽略未知事件（6 个单元测试）
- 聊天 notifier 的 send → stream → done、stop、error、regenerate、switchBranch 状态机（5 个单元测试，使用 mock 的 dio 实例）
- `imageDataUrlFromBytes` 对 PNG/JPEG/GIF/WebP 的 MIME 检测、空输入与未知签名拒绝（6 个单元测试）
- token 弹窗的首用弹出、保存后关闭、两值齐备不弹出、仅有 token 时弹出后端地址弹窗、Save 按钮禁用逻辑（5 个 widget 测试）

## 字体

Source Serif 4 与 Inter 字体从 `github.com/google/fonts` 一次性下载，并通过 `fonttools` 实例化为静态粗细的 TTF 文件。生成的字体文件存放在 `assets/fonts/` 目录中，并在 `pubspec.yaml` 中声明。应用在运行时不会发起任何网络请求来获取字体。

重新生成字体文件的命令：

```bash
python3 -m venv /tmp/fontenv && /tmp/fontenv/bin/pip install fonttools
# 具体的字体生成脚本请参考第 0 阶段的构建步骤，该脚本通过 varLib instancer
# 生成 SourceSerif4-Regular.ttf 和 Inter-{Regular,Medium,W580}.ttf
```

## 已知限制

以下是本次交付中已知的、有意不做或推迟的项，列出以便后续工作跟进：

- **图片粘贴**：第 5 阶段实现了点击选择与拖拽两种图片来源。产品文档列出的第三种方式——键盘粘贴图片——尚未实现。跨平台粘贴图片需要读取剪贴板中的二进制数据，在 Web 上需要 `dart:html` 的剪贴板互操作，在移动端则不是标准交互。为了避免交付一个无法可靠测试且可能在某些平台失效的实现，粘贴暂缓，仅保留点击选择与拖拽。
- **移动端真机构建验证**：第 8 阶段交付了 `MobilePlatformCapabilities` 与 `main_mobile.dart` 入口，代码通过 `flutter analyze` 静态检查。但 Android APK 与 iOS IPA 的真机构建与运行验证需要连接设备或模拟器，本次会话未执行。响应式侧栏抽屉（第 6 阶段）已经在窄屏布局上覆盖了移动端的侧栏交互需求。
- **深色主题**：见上节「第 9 阶段的推迟原因」。需要等待设计师在 `design.md` 中补充深色令牌后落地。

## 实现说明

以下内容记录了当前实现与原始架构文档之间的差异，以及每项差异的原因。这些差异已在 2026-07-19 的架构更新中被采纳为正式设计（见 D13 决策）。

- **Riverpod 风格**：架构文档指定了 `riverpod_generator` codegen 风格。当前实现使用手动 Riverpod API，以保持构建流程简单。数据模型仍然使用 Freezed + `json_serializable` 代码生成。
- **`AuthStore` 继承 `ChangeNotifier`**：架构文档将 `AuthStore` 描述为普通类。本实现使其继承 `ChangeNotifier`，以便 go_router 的 `refreshListenable` 在 token 写入或收到 401 响应时自动重新求值 `redirect` 规则。`AuthStore` 的方法签名与字段与架构文档完全一致。
- **`conversationsForProfileProvider` 使用 family 模式**：架构文档的表格暗示了「按 `selectedProfileId` 过滤单一列表」的方案。本实现使用以 profile id 为键的 family，因为文件夹树的交互设计支持同时展开多个 profile。
- **`gpt_markdown` 使用 1.x 版本**：架构文档的依赖声明中写的是 `^0.1.7`。本项目使用 `^1.1.8`，因为 1.x 以 `GptMarkdown` 作为公开的 widget 名称，并且对流式渲染的支持更好。
- **`currentConversationProvider` 使用 `autoDispose.family`**：架构文档描述为单例 `currentConversationProvider`，切换 `/c/{id}` 时 reset 重新加载。本实现使用 `autoDispose.family`，让 Riverpod 自动管理生命周期，离开页面时自动取消 SSE 订阅，无需手写 reset 逻辑。`pendingStreamProvider` 用于跨路由传递空状态首条消息的流式启动信息。
- **`SendMessageResponse` 模型**：架构文档的模型清单未覆盖，但 `POST /api/conversations/{id}/messages` 的响应体确实同时返回用户消息与 assistant 占位消息，前端需要将其反序列化。
- **`ChatActionsNotifier` + `pendingStreamProvider`**：架构未提及，但空状态首条消息需要先创建对话再发送消息，然后跨路由传递流式启动信息。这两个抽象实现了必要的跨路由协调。
- **`BaseUrlStore`**：架构文档将 `baseUrlProvider` 描述为 Web 端返回空字符串、移动端覆写。本实现新增了 `BaseUrlStore`（`ChangeNotifier`，通过 `shared_preferences` 持久化），让 `baseUrlProvider` 在所有平台上都从该 store 读取。后端地址在所有平台都是必填项——首次启动的 token 弹窗与设置面板都会收集该值（域名 + 端口分框，scheme 智能补齐），没有同源回退。这降低了入口的复杂度，也让后端地址变更能驱动 dio 重建。
