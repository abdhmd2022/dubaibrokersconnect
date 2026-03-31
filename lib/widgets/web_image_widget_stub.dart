import 'package:flutter/material.dart';

Widget buildWebImage({
  required String imageUrl,
  required double width,
  required double height,
  required Widget fallback,
  BoxFit fit = BoxFit.contain,

}) {

  return Image.network(
    imageUrl,
    width: width,
    height: height,
    fit: fit,

    errorBuilder: (context, error, stackTrace) => fallback,
  );
}

