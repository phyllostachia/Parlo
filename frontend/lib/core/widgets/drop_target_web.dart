import 'dart:js_interop';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

import 'drop_target_types.dart';

/// Web file drop zone implemented with package:web.
///
/// `desktop_drop` 0.4.x imports `dart:html`, which cannot be compiled by
/// dart2wasm. The DOM bindings in package:web work in both JavaScript and
/// WebAssembly builds and expose the same browser drag-and-drop events.
class TanDropTarget extends StatefulWidget {
  const TanDropTarget({
    required this.child,
    this.onDrop,
    this.onDragEntered,
    this.onDragExited,
    super.key,
  });

  final Widget child;
  final DropFilesCallback? onDrop;
  final DropHoverCallback? onDragEntered;
  final DropHoverCallback? onDragExited;

  @override
  State<TanDropTarget> createState() => _TanDropTargetState();
}

class _TanDropTargetState extends State<TanDropTarget> {
  late final JSFunction _dropListener;
  late final JSFunction _dragEnterListener;
  late final JSFunction _dragOverListener;
  late final JSFunction _dragLeaveListener;

  @override
  void initState() {
    super.initState();
    _dropListener = ((web.Event event) => _handleDrop(event)).toJS;
    _dragEnterListener = ((web.Event event) {
      event.preventDefault();
      widget.onDragEntered?.call();
    }).toJS;
    _dragOverListener = ((web.Event event) => event.preventDefault()).toJS;
    _dragLeaveListener = ((web.Event event) {
      event.preventDefault();
      widget.onDragExited?.call();
    }).toJS;

    web.window.addEventListener('drop', _dropListener);
    web.window.addEventListener('dragenter', _dragEnterListener);
    web.window.addEventListener('dragover', _dragOverListener);
    web.window.addEventListener('dragleave', _dragLeaveListener);
  }

  void _handleDrop(web.Event event) {
    event.preventDefault();
    widget.onDragExited?.call();

    final dataTransfer = (event as web.DragEvent).dataTransfer;
    if (dataTransfer == null) return;

    final droppedFiles = <XFile>[];
    final files = dataTransfer.files;
    for (var index = 0; index < files.length; index++) {
      final file = files.item(index);
      if (file == null) continue;

      droppedFiles.add(
        XFile(
          web.URL.createObjectURL(file),
          mimeType: file.type,
          name: file.name,
          length: file.size,
          lastModified: DateTime.fromMillisecondsSinceEpoch(file.lastModified),
        ),
      );
    }

    if (droppedFiles.isNotEmpty) {
      widget.onDrop?.call(droppedFiles);
    }
  }

  @override
  void dispose() {
    web.window.removeEventListener('drop', _dropListener);
    web.window.removeEventListener('dragenter', _dragEnterListener);
    web.window.removeEventListener('dragover', _dragOverListener);
    web.window.removeEventListener('dragleave', _dragLeaveListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
