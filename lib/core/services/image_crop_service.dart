// lib/core/services/image_crop_service.dart

import 'dart:io';
import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';
import 'package:image_cropper/image_cropper.dart';

class ImageCropService {
  /// 用户手动裁剪图片为正方形 (1:1比例)
  static Future<File?> cropImageInteractively(String imagePath) async {
    try {
      final croppedFile = await ImageCropper.platform.cropImage(
        sourcePath: imagePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1), // 强制1:1比例
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '裁剪头像',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            statusBarColor: Colors.blue,
            backgroundColor: Colors.black,
            cropGridColor: Colors.blue,
            cropFrameColor: Colors.blue,
            activeControlsWidgetColor: Colors.blue,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true, // 锁定为正方形比例
            hideBottomControls: false,
            cropStyle: CropStyle.rectangle,

            // UI优化配置 - 大幅增加可点击性
            showCropGrid: true,
            dimmedLayerColor: Colors.black54,

            // 增加触摸友好性
            cropFrameStrokeWidth: 4, // 进一步增加边框宽度
            cropGridStrokeWidth: 2, // 增加网格线宽度
            // 强制显示ActionBar并设置为NoActionBar主题
            // 这样可以确保我们的自定义主题生效
          ),
          IOSUiSettings(
            title: '裁剪头像',
            aspectRatioLockEnabled: true, // 锁定比例
            resetAspectRatioEnabled: false, // 不允许重置比例
            aspectRatioPickerButtonHidden: true, // 隐藏比例选择按钮
            rotateClockwiseButtonHidden: false,
            rotateButtonsHidden: false,
            rectHeight: 350, // 增加裁剪区域高度
            rectWidth: 350, // 增加裁剪区域宽度
            minimumAspectRatio: 1.0,
            // 增加按钮大小，方便点击
            cancelButtonTitle: '取消',
            doneButtonTitle: '完成',
          ),
        ],
      );

      if (croppedFile != null) {
        AppLogger.debug('用户手动裁剪完成: ${croppedFile.path}');
        return File(croppedFile.path);
      } else {
        AppLogger.debug('用户取消了裁剪');
        return null;
      }
    } catch (e) {
      AppLogger.debug('图片裁剪失败: $e');
      return null;
    }
  }

  /// 验证裁剪是否成功
  static Future<bool> isCroppedImageValid(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      return bytes.isNotEmpty;
    } catch (e) {
      AppLogger.debug('验证裁剪图片失败: $e');
      return false;
    }
  }
}
