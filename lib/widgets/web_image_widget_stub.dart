import 'package:flutter/material.dart';

Widget buildWebImage({
  required String imageUrl,
  required double width,
  required double height,
  required Widget fallback,
}) {
  // Stub for non-web platforms
  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => fallback,
  );
}

