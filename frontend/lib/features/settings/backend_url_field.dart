/// A shared input for the backend address, split into a domain field and a
/// port field.
///
/// The backend URL is a required value — on every platform the user must tell
/// Parlo which host to talk to. There is no same-origin fallback. To make the
/// input forgiving the scheme is auto-detected: a domain that contains
/// `localhost`, `127.0.0.1`, or `0.0.0.0` gets `http://`; anything else gets
/// `https://`. If the user already typed a scheme it is kept as-is.
///
/// The parent widget owns both [TextEditingController]s and calls
/// [BackendUrlField.buildUrl] to validate and assemble the final string when
/// it saves. The field shows inline error text for malformed values so the
/// user gets feedback before pressing Save.
library;

import 'package:flutter/material.dart';

/// Parses a stored base URL into a domain and a port.
///
/// Returns `null` when [url] is empty or does not carry an explicit port. The
/// port is required, so a stored value like `https://parlo.example.com`
/// (without a port) is treated as unparsable and the fields start empty.
({String domain, String port})? parseBackendUrl(String url) {
  if (url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  final host = uri.host;
  // `Uri.port` is 0 when the URL does not specify one. Since the port is
  // required, treat 0 as "not present".
  final port = uri.port;
  if (host.isEmpty || port == 0) return null;
  return (domain: host, port: port.toString());
}

/// Validates the domain and port fields and assembles the final base URL.
///
/// Returns `null` when the inputs are invalid. The caller uses this to decide
/// whether the Save button is enabled.
///
/// The returned URL never has a trailing slash and always carries an explicit
/// port, e.g. `https://parlo.example.com:8000`.
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

/// Adds a scheme when the user did not type one.
///
/// Localhost-style hosts get `http://` because they are usually a local dev
/// server; everything else gets `https://` because that is the safe default.
/// When the user already typed a scheme it is kept unchanged.
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

/// A row of two [TextField]s — domain on the left, port on the right.
///
/// The parent owns the controllers and is expected to pre-fill them (typically
/// by calling [parseBackendUrl] on the current store value in `initState`).
/// The field calls [onChanged] whenever the user edits either text, so the
/// parent can re-evaluate its Save button.
///
/// Inline error text appears only for malformed non-empty values; an empty
/// field stays quiet because the disabled Save button already signals that
/// something is missing.
class BackendUrlField extends StatefulWidget {
  /// Creates the field.
  const BackendUrlField({
    required this.domainController,
    required this.portController,
    this.fieldGap = 8,
    this.onChanged,
    this.portWidth = 96,
    super.key,
  });

  /// The controller for the domain text.
  final TextEditingController domainController;

  /// The controller for the port text.
  final TextEditingController portController;

  /// The horizontal space between the domain and port fields.
  final double fieldGap;

  /// Called whenever either text changes. The parent uses this to re-evaluate
  /// its Save button.
  final VoidCallback? onChanged;

  /// The width of the port field.
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
    // An empty domain is "missing", not "malformed" — the disabled Save
    // button is enough feedback, so no error text here.
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
