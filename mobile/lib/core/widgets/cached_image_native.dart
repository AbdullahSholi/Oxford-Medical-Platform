import 'package:flutter/material.dart';

/// Stub for native platforms — never called because kIsWeb is checked first.
Widget buildWebImage({
  required String url,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  required Widget placeholder,
}) {
  return placeholder;
}
