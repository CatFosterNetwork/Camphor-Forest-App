// lib/core/utils/file_utils.dart

/// 文件工具类
/// 提供文件相关的通用工具方法
class FileUtils {
  /// 获取文件扩展名（不带点）
  ///
  /// 例如：
  /// - `/path/to/image.jpg` → `jpg`
  /// - `/path/to/photo.PNG` → `png`
  /// - `noextension` → `jpg` (默认)
  static String getFileExtension(String filePath) {
    final parts = filePath.split('.');
    if (parts.length > 1) {
      return parts.last.toLowerCase();
    }
    return 'jpg'; // 默认
  }

  /// 获取文件扩展名（带点）
  ///
  /// 例如：
  /// - `/path/to/image.jpg` → `.jpg`
  /// - `/path/to/photo.PNG` → `.png`
  static String getFileExtensionWithDot(String filePath) {
    return '.${getFileExtension(filePath)}';
  }

  /// 从 URL 获取文件扩展名（带点）
  ///
  /// 适用于网络图片URL，能正确解析查询参数
  ///
  /// 例如：
  /// - `https://example.com/image.png?v=1` → `.png`
  /// - `https://example.com/photo.jpg` → `.jpg`
  static String getFileExtensionFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return '.jpg';

    final path = uri.path.toLowerCase();
    if (path.endsWith('.png')) return '.png';
    if (path.endsWith('.gif')) return '.gif';
    if (path.endsWith('.webp')) return '.webp';
    if (path.endsWith('.svg')) return '.svg';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return '.jpg';

    return '.jpg'; // 默认
  }

  /// 生成临时文件路径
  ///
  /// [directory] 目录路径
  /// [prefix] 文件名前缀
  /// [extension] 文件扩展名（带点）
  static String generateTempFilePath(
    String directory,
    String prefix,
    String extension,
  ) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '$directory/${prefix}_$timestamp$extension';
  }
}
