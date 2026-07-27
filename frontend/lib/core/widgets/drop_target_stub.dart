import 'package:flutter/widgets.dart';

import 'drop_target_types.dart';

/// Non-Web fallback for the file drop zone.
///
/// Mobile platforms use the file picker instead of browser drag-and-drop. This
/// implementation intentionally keeps the widget as a transparent wrapper so
/// the shared chat UI remains available on every target.
class TanDropTarget extends StatelessWidget {
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
  Widget build(BuildContext context) => child;
}
