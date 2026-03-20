import 'dart:math';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

/// Builds an image widget using an HTML <img> element on web.
/// This bypasses CanvasKit's XHR-based image loading which has CORS issues.
Widget buildWebImage({
  required String url,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  required Widget placeholder,
}) {
  final viewType = 'cached-img-${url.hashCode}-${Random().nextInt(999999)}';

  ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
    final img = web.HTMLImageElement()
      ..src = url
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = _boxFitToCss(fit)
      ..style.display = 'block';
    return img;
  });

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}

String _boxFitToCss(BoxFit fit) {
  switch (fit) {
    case BoxFit.cover:
      return 'cover';
    case BoxFit.contain:
      return 'contain';
    case BoxFit.fill:
      return 'fill';
    case BoxFit.fitWidth:
      return 'cover';
    case BoxFit.fitHeight:
      return 'cover';
    case BoxFit.none:
      return 'none';
    case BoxFit.scaleDown:
      return 'scale-down';
  }
}
