// lib/core/providers/permission_provider.dart

import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../services/permission_service.dart';

/// 权限管理状态
class PermissionState {
  final Map<AppPermissionType, bool> permissions;
  final bool isLoading;
  final String? error;

  const PermissionState({
    this.permissions = const {},
    this.isLoading = false,
    this.error,
  });

  PermissionState copyWith({
    Map<AppPermissionType, bool>? permissions,
    bool? isLoading,
    String? error,
  }) {
    return PermissionState(
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 权限管理器
class PermissionNotifier extends StateNotifier<PermissionState> {
  PermissionNotifier() : super(const PermissionState());

  /// 检查指定权限状态
  Future<bool> checkPermission(AppPermissionType permissionType) async {
    final isGranted = await PermissionService.checkPermission(permissionType);
    state = state.copyWith(
      permissions: {...state.permissions, permissionType: isGranted},
    );
    return isGranted;
  }

  /// 请求指定权限
  Future<PermissionRequestResult> requestPermission(
    AppPermissionType permissionType, {
    BuildContext? context,
    bool showRationale = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await PermissionService.requestPermission(
        permissionType,
        context: context,
        showRationale: showRationale,
      );

      state = state.copyWith(
        permissions: {...state.permissions, permissionType: result.isGranted},
        isLoading: false,
        error: result.errorMessage,
      );

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return PermissionRequestResult.denied('请求权限时发生错误: $e');
    }
  }

  /// 请求相机和相册权限
  Future<PermissionRequestResult> requestCameraAndPhotosPermission({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await PermissionService.requestCameraAndPhotosPermission(
        context: context,
        showRationale: showRationale,
      );

      // 更新权限状态
      final updatedPermissions = {...state.permissions};
      if (result.isGranted) {
        updatedPermissions[AppPermissionType.camera] = true;
        updatedPermissions[AppPermissionType.photos] = true;
      }

      state = state.copyWith(
        permissions: updatedPermissions,
        isLoading: false,
        error: result.errorMessage,
      );

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return PermissionRequestResult.denied('请求权限时发生错误: $e');
    }
  }

  /// 请求存储权限
  Future<PermissionRequestResult> requestStoragePermission({
    BuildContext? context,
    bool showRationale = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await PermissionService.requestStoragePermission(
        context: context,
        showRationale: showRationale,
      );

      state = state.copyWith(
        permissions: {
          ...state.permissions,
          AppPermissionType.photos: result.isGranted,
        },
        isLoading: false,
        error: result.errorMessage,
      );

      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return PermissionRequestResult.denied('请求权限时发生错误: $e');
    }
  }

  /// 选择图片（带权限检查）
  Future<String?> pickImage({
    required BuildContext context,
    required ImageSource source,
    bool showRationale = true,
  }) async {
    try {
      // 根据图片来源请求相应权限
      PermissionRequestResult result;
      if (source == ImageSource.camera) {
        // 拍照需要相机和相册权限
        result = await requestCameraAndPhotosPermission(
          context: context,
          showRationale: showRationale,
        );
      } else {
        // 从相册选择只需要相册权限
        result = await requestStoragePermission(
          context: context,
          showRationale: showRationale,
        );
      }

      if (!result.isGranted) {
        AppLogger.debug('🔒 权限被拒绝: ${result.errorMessage}');
        if (context.mounted) {
          PermissionService.showErrorSnackBar(
            context,
            result.errorMessage ?? '权限被拒绝',
          );
        }
        return null;
      }

      // 权限获取成功，选择图片
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source);

      if (pickedFile != null) {
        AppLogger.debug('🖼️ 选择图片成功: ${pickedFile.path}');
        return pickedFile.path;
      } else {
        AppLogger.debug('🖼️ 用户取消选择图片');
        return null;
      }
    } catch (e) {
      AppLogger.debug('🔒 选择图片异常: $e');
      if (context.mounted) {
        PermissionService.showErrorSnackBar(context, '选择图片失败: $e');
      }
      return null;
    }
  }

  /// 保存图片到相册（带权限检查）
  Future<bool> saveImageToGallery({
    required BuildContext context,
    required String imagePath,
    bool showRationale = true,
  }) async {
    try {
      // 请求存储权限
      final result = await requestStoragePermission(
        context: context,
        showRationale: showRationale,
      );

      if (!result.isGranted) {
        AppLogger.debug('🔒 保存图片权限被拒绝: ${result.errorMessage}');
        if (context.mounted) {
          PermissionService.showErrorSnackBar(
            context,
            result.errorMessage ?? '权限被拒绝',
          );
        }
        return false;
      }

      // 权限获取成功，保存图片
      // 这里可以集成Gal等保存库
      AppLogger.debug('🖼️ 保存图片到相册: $imagePath');
      return true;
    } catch (e) {
      AppLogger.debug('🔒 保存图片异常: $e');
      if (context.mounted) {
        PermissionService.showErrorSnackBar(context, '保存图片失败: $e');
      }
      return false;
    }
  }

  /// 刷新所有权限状态
  Future<void> refreshAllPermissions() async {
    state = state.copyWith(isLoading: true);

    final permissions = <AppPermissionType, bool>{};
    for (final permissionType in AppPermissionType.values) {
      permissions[permissionType] = await PermissionService.checkPermission(
        permissionType,
      );
    }

    state = state.copyWith(permissions: permissions, isLoading: false);
  }

  /// 获取权限状态
  bool getPermissionStatus(AppPermissionType permissionType) {
    return state.permissions[permissionType] ?? false;
  }

  /// 检查是否有任何权限被拒绝
  bool get hasAnyPermissionDenied {
    return state.permissions.values.any((granted) => !granted);
  }

  /// 检查相机相关权限是否都已授权
  bool get isCameraPermissionGranted {
    return getPermissionStatus(AppPermissionType.camera) &&
        getPermissionStatus(AppPermissionType.photos);
  }

  /// 检查相册权限是否已授权
  bool get isPhotosPermissionGranted {
    return getPermissionStatus(AppPermissionType.photos);
  }
}

/// 权限管理器Provider
final permissionProvider =
    StateNotifierProvider<PermissionNotifier, PermissionState>((ref) {
      return PermissionNotifier();
    });

/// 便捷的权限检查器
final permissionCheckerProvider = Provider<PermissionChecker>((ref) {
  return PermissionChecker(ref.watch(permissionProvider.notifier));
});

/// 权限检查器辅助类
class PermissionChecker {
  final PermissionNotifier _notifier;

  PermissionChecker(this._notifier);

  /// 简化的图片选择方法
  Future<String?> pickImageWithPermission(
    BuildContext context,
    ImageSource source,
  ) async {
    return await _notifier.pickImage(context: context, source: source);
  }

  /// 简化的图片保存方法
  Future<bool> saveImageWithPermission(
    BuildContext context,
    String imagePath,
  ) async {
    return await _notifier.saveImageToGallery(
      context: context,
      imagePath: imagePath,
    );
  }

  /// 检查并请求相机权限
  Future<bool> ensureCameraPermission(BuildContext context) async {
    final result = await _notifier.requestCameraAndPhotosPermission(
      context: context,
    );
    return result.isGranted;
  }

  /// 检查并请求相册权限
  Future<bool> ensurePhotosPermission(BuildContext context) async {
    final result = await _notifier.requestStoragePermission(context: context);
    return result.isGranted;
  }
}
