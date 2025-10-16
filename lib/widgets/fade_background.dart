import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/cache/app_cache_manager.dart';

/// 渐变切换背景图组件，配合 [AppBackground] 使用。
/// 先将图片 **预加载到内存**，加载完成后再平滑显示。
/// 支持本地文件和网络图片
class FadeBackground extends StatefulWidget {
  final String imageUrl;
  const FadeBackground(this.imageUrl, {super.key});

  /// 判断是否为本地文件路径
  ///
  /// 本地路径的特征：
  /// - 不以 http:// 或 https:// 开头
  /// - 以 / 开头 (绝对路径)
  /// - 以 file:// 开头
  /// - 包含 /data/ (Android 应用数据目录)
  /// - 包含 /storage/ (Android 存储目录)
  static bool isLocalPath(String path) {
    return !path.startsWith('http://') &&
        !path.startsWith('https://') &&
        (path.startsWith('/') ||
            path.startsWith('file://') ||
            path.contains('/data/') ||
            path.contains('/storage/'));
  }

  @override
  State<FadeBackground> createState() => _FadeBackgroundState();
}

class _FadeBackgroundState extends State<FadeBackground> {
  late ImageProvider _provider;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _provider = _createImageProvider(widget.imageUrl);
    _precache();
  }

  @override
  void didUpdateWidget(covariant FadeBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _ready = false;
      _provider = _createImageProvider(widget.imageUrl);
      _precache();
    }
  }

  /// 根据路径类型创建合适的 ImageProvider
  ImageProvider _createImageProvider(String path) {
    // 检测是否为本地文件路径
    if (FadeBackground.isLocalPath(path)) {
      return FileImage(File(path));
    }
    // 网络图片使用缓存
    return CachedNetworkImageProvider(
      path,
      cacheManager: AppCacheManager.instance,
    );
  }

  Future<void> _precache() async {
    // 本地文件读取速度快，直接标记为就绪
    if (FadeBackground.isLocalPath(widget.imageUrl)) {
      if (mounted) setState(() => _ready = true);
      return;
    }

    // 网络图片需要预加载到内存缓存
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
