import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports
import 'web_image_widget_stub.dart'
    if (dart.library.html) 'web_image_widget_web.dart' as web_image;

/// Web-compatible image widget that bypasses CORS issues
class WebCompatibleImage extends StatelessWidget {
  final String imageUrl;
  final double width;
  final double height;
  final Widget fallback;
  final BoxFit fit; // ⭐ ADD THIS

  const WebCompatibleImage({
    super.key,
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.fallback,
    this.fit = BoxFit.contain, // ⭐ CHANGE DEFAULT
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return web_image.buildWebImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fallback: fallback,
        fit: fit, // ✅ add this

      );
    } else {
      return Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: fit, // ⭐ IMPORTANT

        errorBuilder: (context, error, stackTrace) => fallback,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    }
  }
}

