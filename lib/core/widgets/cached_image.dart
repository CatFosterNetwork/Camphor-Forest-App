// lib/core/widgets/cached_image.dart

import 'package:flutter/material.dart';
import '../services/image_cache_service.dart';

/// 缓存感知的图片组件
/// 自动处理网络图片缓存，提供加载状态和错误处理
class CachedImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  State<CachedImage> createState() => _CachedImageState();
}

class _CachedImageState extends State<CachedImage> {
  ImageProvider? _imageProvider;
  bool _isLoading = true;
  bool _hasError = false;
  final ImageCacheService _cacheService = ImageCacheService();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CachedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 只有当URL发生变化时才重新加载
    if (widget.imageUrl != oldWidget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final provider = await _cacheService.getCachedImageProvider(widget.imageUrl);
      
      if (mounted) {
        setState(() {
          _imageProvider = provider;
          _isLoading = false;
          _hasError = provider == null;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading cached image: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_isLoading) {
      // 加载状态
      content = widget.placeholder ?? _buildDefaultPlaceholder();
    } else if (_hasError || _imageProvider == null) {
      // 错误状态
      content = widget.errorWidget ?? _buildDefaultErrorWidget();
    } else {
      // 成功加载状态
      content = Image(
        image: _imageProvider!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('❌ Image render error: $error');
          return widget.errorWidget ?? _buildDefaultErrorWidget();
        },
      );
    }

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        color: widget.backgroundColor,
      ),
      child: widget.borderRadius != null
          ? ClipRRect(
              borderRadius: widget.borderRadius!,
              child: content,
            )
          : content,
    );
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade200,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey.shade300,
      child: Icon(
        Icons.broken_image,
        size: 32,
        color: Colors.grey.shade600,
      ),
    );
  }
}

/// 缓存感知的头像组件
class CachedAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Widget? placeholder;
  final Widget? child;
  final Color? backgroundColor;

  const CachedAvatar({
    super.key,
    this.imageUrl,
    required this.radius,
    this.placeholder,
    this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey.shade300,
        child: child ?? Icon(
          Icons.person,
          size: radius,
          color: Colors.grey.shade600,
        ),
      );
    }

    return CachedImage(
      imageUrl: imageUrl!,
      width: radius * 2,
      height: radius * 2,
      fit: BoxFit.cover,
      borderRadius: BorderRadius.circular(radius),
      backgroundColor: backgroundColor ?? Colors.grey.shade300,
      placeholder: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey.shade300,
        child: SizedBox(
          width: radius * 0.4,
          height: radius * 0.4,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor ?? Colors.grey.shade300,
        child: child ?? Icon(
          Icons.person,
          size: radius,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }
}