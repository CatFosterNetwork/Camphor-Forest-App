// lib/core/services/image_service.dart

import 'dart:io';

import '../../core/utils/app_logger.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'image_crop_service.dart';

class ImageService {
  static const int maxImageSize = 800;
  static const int imageQuality = 80;

  /// 选择并处理图片
  Future<File?> pickAndProcessAvatar({required ImageSource source}) async {
    try {
      // 1. 选择图片
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile == null) return null;

      // 2. 用户手动裁剪为正方形 (1:1比例)
      final croppedFile = await ImageCropService.cropImageInteractively(
        pickedFile.path,
      );
      if (croppedFile == null) {
        AppLogger.debug('用户取消了裁剪操作');
        return null; // 用户取消裁剪，返回null
      }

      // 3. 验证裁剪结果
      final isValid = await ImageCropService.isCroppedImageValid(croppedFile);
      if (!isValid) {
        AppLogger.debug('裁剪后的图片无效');
        return null;
      }

      // 4. 压缩图
      final compressedFile = await _compressImage(croppedFile.path);

      return compressedFile;
    } catch (e) {
      AppLogger.debug('选择和处理图片失败: $e');
      return null;
    }
  }

  /// 压缩图片
  Future<File> _compressImage(String imagePath) async {
    try {
      // 读取图片文件
      final originalFile = File(imagePath);
      final originalBytes = await originalFile.readAsBytes();

      // 解码图片
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) {
        throw Exception('无法解码图片');
      }

      // 计算新尺寸，保持长宽比，最大尺寸不超过maxImageSize
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (newWidth > maxImageSize || newHeight > maxImageSize) {
        final ratio =
            maxImageSize / (newWidth > newHeight ? newWidth : newHeight);
        newWidth = (newWidth * ratio).round();
        newHeight = (newHeight * ratio).round();
      }

      // 调整图片大小
      final resizedImage = img.copyResize(
        originalImage,
        width: newWidth,
        height: newHeight,
        interpolation: img.Interpolation.linear,
      );

      // 压缩为JPEG格式，质量为80%
      final compressedBytes = img.encodeJpg(
        resizedImage,
        quality: imageQuality,
      );

      // 保存压缩后的图片
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final compressedFile = File(
        '${tempDir.path}/compressed_avatar_$timestamp.jpg',
      );
      await compressedFile.writeAsBytes(compressedBytes);

      AppLogger.debug(
        '图片压缩完成: 原大小 ${originalBytes.length} -> 压缩后 ${compressedBytes.length}',
      );
      return compressedFile;
    } catch (e) {
      AppLogger.debug('图片压缩失败: $e');
      // 如果压缩失败，返回原文件
      return File(imagePath);
    }
  }
}
