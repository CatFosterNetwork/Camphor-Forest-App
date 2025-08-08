import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/cache/app_cache_manager.dart';

/// 渐变切换背景图组件，配合 [AppBackground] 使用。
/// 先将图片 **预加载到内存**，加载完成后再平滑显示。
class FadeBackground extends StatefulWidget {
  final String imageUrl;
  const FadeBackground(this.imageUrl, {super.key});

  @override
  State<FadeBackground> createState() => _FadeBackgroundState();
}

class _FadeBackgroundState extends State<FadeBackground> {
  late final ImageProvider _provider;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _provider = CachedNetworkImageProvider(
      widget.imageUrl,
      cacheManager: AppCacheManager.instance,
    );
    _precache();
  }

  @override
  void didUpdateWidget(covariant FadeBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _ready = false;
      _provider = CachedNetworkImageProvider(
        widget.imageUrl,
        cacheManager: AppCacheManager.instance,
      );
      _precache();
    }
  }

  Future<void> _precache() async {
    try {
      await precacheImage(_provider, context);
    } catch (_) {
      // ignore errors; will fallback to CachedNetworkImage later
    }
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_ready) {
      content = Image(
        key: ValueKey(widget.imageUrl),
        image: _provider,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else {
      content = const SizedBox.expand(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: content,
    );
  }
}
