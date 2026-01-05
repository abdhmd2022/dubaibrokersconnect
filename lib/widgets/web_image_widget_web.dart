import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

Widget buildWebImage({
  required String imageUrl,
  required double width,
  required double height,
  required Widget fallback,
}) {
  // Use HTML img element for web to bypass CORS
  final String viewId = 'img_${imageUrl.hashCode}_${DateTime.now().millisecondsSinceEpoch}';
  
  // Create and configure the image element
  html.ImageElement imgElement = html.ImageElement()
    ..src = imageUrl
    ..style.width = '${width}px'
    ..style.height = '${height}px'
    ..style.objectFit = 'cover'
    ..style.borderRadius = '50%';
  
  // Register the platform view
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

