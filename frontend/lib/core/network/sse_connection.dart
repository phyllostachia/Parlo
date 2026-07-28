/// SSE 字节流 transport 的跨平台入口。
///
/// Dio 的 Web adapter 基于 XMLHttpRequest；它会等到响应结束才交付
/// `ResponseBody`。Web 目标必须改用 Fetch 的 `ReadableStream`，才能在每个
/// SSE chunk 到达时立即更新 UI。原生目标仍复用 Dio 的 stream support。
library;

export 'sse_connection_io.dart'
    if (dart.library.js_interop) 'sse_connection_web.dart';
