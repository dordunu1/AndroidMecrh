import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

class CachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Duration cacheDuration;
  final int? maxHeight;

  static final customCacheManager = CacheManager(
    Config(
      'customCacheKey',
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: 'imageCache'),
      fileService: HttpFileService(),
    ),
  );

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.cacheDuration = const Duration(days: 7),
    this.maxHeight,
  });

  String _processImageUrl(String url) {
    // Add cache-busting parameter to force reload when needed
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}t=$timestamp';
  }

  Future<String> _getImageWithCORS(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Origin, Content-Type, X-Auth-Token',
        },
      );
      
      if (response.statusCode == 200) {
        return url;
      } else {
        throw Exception('Failed to load image');
      }
    } catch (e) {
      print('Error pre-fetching image $url: $e');
      return url;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: FutureBuilder<String>(
        future: _getImageWithCORS(_processImageUrl(imageUrl!)),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget();
          }

          return CachedNetworkImage(
            imageUrl: snapshot.data ?? imageUrl!,
            width: width,
            height: height,
            fit: fit,
            cacheManager: customCacheManager,
            placeholder: (context, url) => _buildPlaceholder(),
            errorWidget: (context, url, error) {
              print('Error loading image $url: $error');
              return _buildErrorWidget();
            },
            fadeInDuration: const Duration(milliseconds: 300),
            fadeOutDuration: const Duration(milliseconds: 300),
            imageBuilder: (context, imageProvider) => Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: imageProvider,
                  fit: fit,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    return placeholder ?? Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return errorWidget ?? Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.grey,
          ),
          if (imageUrl != null && imageUrl!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                'Failed to load image',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
} 