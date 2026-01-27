import 'package:devtools_extensions/devtools_extensions.dart';
import 'package:flutter/material.dart';

import 'src/inspector.dart';

void main() {
  runApp(const DevToolsExtension(child: Inspector()));
}
