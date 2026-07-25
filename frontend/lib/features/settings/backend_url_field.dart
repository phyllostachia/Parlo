/// Backend address 的共享 input，拆分为 domain field 和 port field。
///
/// Backend URL 是 required value；每个平台都要求 user 告诉 Parlo 要通信的 host。没有
/// same-origin fallback。为使 input 更宽容，会自动检测 scheme：包含 `localhost`、
/// `127.0.0.1` 或 `0.0.0.0` 的 domain 使用 `http://`，其他 domain 使用 `https://`。如果
/// user 已经输入 scheme，则保持原样。
///
/// Parent widget 拥有两个 [TextEditingController]，并在保存时调用 [BackendUrlField.buildUrl]
/// 校验并组装最终 string。Field 会为 malformed value 显示 inline error text，使 user 在
/// 点击 Save 前得到反馈。
library;

import 'package:flutter/material.dart';

/// 将已存储的 base URL 解析为 domain 和 port。
///
/// 当 [url] 为空或不包含 explicit port 时返回 `null`。Port 是 required，因此像
/// `https://parlo.example.com` 这样不带 port 的 stored value 会被视为无法解析，field 从空值开始。
({String domain, String port})? parseBackendUrl(String url) {
  if (url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final host = uri.host;
  // URL 未指定 port 时 `Uri.port` 为 0。由于 port 是 required，将 0 视为“not present”。
  final port = uri.port;
  if (host.isEmpty || port == 0) return null;
  return (domain: host, port: port.toString());
}

/// 校验 domain 和 port field，并组装最终 base URL。
///
/// 输入无效时返回 `null`。调用方使用它决定 Save button 是否启用。
///
/// 返回 URL 从不带 trailing slash，并且始终携带 explicit port，例如
/// `https://parlo.example.com:8000`。
String? buildBackendUrl(String domainRaw, String portRaw) {
  final domain = domainRaw.trim();
  final port = portRaw.trim();
  if (domain.isEmpty || port.isEmpty) return null;

  final portNum = int.tryParse(port);
  if (portNum == null || portNum < 1 || portNum > 65535) return null;

  final withScheme = _ensureScheme(domain);
  final cleaned = withScheme.replaceAll(RegExp(r'/+$'), '');
  return '$cleaned:$portNum';
}

/// User 未输入 scheme 时添加 scheme。
///
/// Localhost-style host 使用 `http://`，因为它们通常是 local dev server；其他 host 使用
/// `https://`，因为这是安全 default。User 已输入 scheme 时保持不变。
String _ensureScheme(String domain) {
  if (domain.startsWith('http://') || domain.startsWith('https://')) {
    return domain;
  }
  final isLocal =
      domain == 'localhost' ||
      domain.startsWith('127.0.0.1') ||
      domain.startsWith('0.0.0.0');
  return isLocal ? 'http://$domain' : 'https://$domain';
}

/// 一行两个 [TextField]：左侧 domain，右侧 port。
///
/// Parent 拥有 controller，并应预填它们（通常在 `initState` 中对 current store value 调用
/// [parseBackendUrl]）。User 编辑任一 text 时 field 调用 [onChanged]，使 parent 可以重新
/// 计算 Save button。
///
/// Inline error text 只在非空且 malformed value 时出现；空 field 保持安静，因为 disabled
/// Save button 已经表示有内容缺失。
class BackendUrlField extends StatefulWidget {
  /// 创建此 field。
  const BackendUrlField({
    required this.domainController,
    required this.portController,
    this.fieldGap = 8,
    this.onChanged,
    this.portWidth = 96,
    super.key,
  });

  /// Domain text 使用的 controller。
  final TextEditingController domainController;

  /// Port text 使用的 controller。
  final TextEditingController portController;

  /// Domain field 与 port field 之间的水平间距。
  final double fieldGap;

  /// 任一 text 变化时调用。Parent 使用它重新计算 Save button。
  final VoidCallback? onChanged;

  /// Port field 的宽度。
  final double portWidth;

  @override
  State<BackendUrlField> createState() => _BackendUrlFieldState();
}

class _BackendUrlFieldState extends State<BackendUrlField> {
  @override
  void initState() {
    super.initState();
    widget.domainController.addListener(_handleChanged);
    widget.portController.addListener(_handleChanged);
  }

  @override
  void dispose() {
    widget.domainController.removeListener(_handleChanged);
    widget.portController.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() {
    if (!mounted) return;
    setState(() {});
    widget.onChanged?.call();
  }

  String? get _domainError {
    final text = widget.domainController.text.trim();
    // Empty domain 是“missing”而非“malformed”；disabled Save button 已足够提供反馈，因此
    // 这里不显示 error text。
    if (text.isEmpty) return null;
    return null;
  }

  String? get _portError {
    final text = widget.portController.text.trim();
    if (text.isEmpty) return null;
    final port = int.tryParse(text);
    if (port == null) return 'Numbers only';
    if (port < 1 || port > 65535) return '1–65535';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextField(
            controller: widget.domainController,
            decoration: InputDecoration(
              labelText: 'Backend domain',
              hintText: 'parlo.example.com',
              errorText: _domainError,
            ),
            keyboardType: TextInputType.url,
            autocorrect: false,
            enableSuggestions: false,
          ),
        ),
        SizedBox(width: widget.fieldGap),
        SizedBox(
          width: widget.portWidth,
          child: TextField(
            controller: widget.portController,
            decoration: InputDecoration(
              labelText: 'Port',
              hintText: '8000',
              errorText: _portError,
            ),
            keyboardType: TextInputType.number,
            autocorrect: false,
            enableSuggestions: false,
          ),
        ),
      ],
    );
  }
}
