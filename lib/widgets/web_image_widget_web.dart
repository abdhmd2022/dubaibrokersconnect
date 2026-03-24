import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

Widget buildWebImage({
  required String imageUrl,
  required double width,
  required double height,
  required Widget fallback,
  BoxFit fit = BoxFit.contain,
}) {
  final String viewId =
      'img_${imageUrl.hashCode}_${DateTime.now().millisecondsSinceEpoch}';

  final imgElement = html.ImageElement()
    ..src = imageUrl
    ..style.width = '${width}px'
    ..style.height = '${height}px'
    ..style.objectFit = fit == BoxFit.cover ? 'cover' : 'contain'
    ..style.borderRadius = '0'
    ..style.display = 'block'
    ..style.backgroundColor = 'transparent';

  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
        (int viewId) => imgElement,
  );

  return SizedBox(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewId),
  );
}