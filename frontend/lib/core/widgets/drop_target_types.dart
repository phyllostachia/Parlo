import 'dart:async';

import 'package:cross_file/cross_file.dart';

typedef DropFilesCallback = FutureOr<void> Function(List<XFile> files);
typedef DropHoverCallback = void Function();
