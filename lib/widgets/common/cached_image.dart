import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class CachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool useOldImageOnUrlChange;
  final Duration placeholderFadeInDuration;
  final Duration fadeInDuration;
  final Alignment? alignment;

  const CachedImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.useOldImageOnUrlChange = true,
    this.placeholderFadeInDuration = const Duration(milliseconds: 500),
    this.fadeInDuration = const Duration(milliseconds: 1000),
    this.alignment,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      alignment: alignment ?? Alignment.center,
      placeholder: (context, url) => placeholder ?? 
        Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      errorWidget: (context, url, error) => errorWidget ??
        Container(
          color: Colors.grey[200],
          child: const Icon(Icons.error),
        ),
      useOldImageOnUrlChange: useOldImageOnUrlChange,
      placeholderFadeInDuration: placeholderFadeInDuration,
      fadeInDuration: fadeInDuration,
    );
  }
} 