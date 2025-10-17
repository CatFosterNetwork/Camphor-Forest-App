// lib/pages/settings/profile_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/providers/theme_config_provider.dart';
import '../../core/providers/permission_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';
import '../../core/widgets/cached_image.dart';
import '../../core/widgets/theme_aware_dialog.dart';
import '../../core/providers/core_providers.dart';
import '../../core/services/image_service.dart';
import '../../core/services/image_cache_service.dart';
import '../../core/services/image_upload_service.dart';
import '../../core/services/toast_service.dart';

class ProfileSettingsPage extends ConsumerStatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  ConsumerState<ProfileSettingsPage> createState() =>
      _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends ConsumerState<ProfileSettingsPage> {
  /// 头像上传中状态
  bool _isUploadingAvatar = false;

  /// 强制刷新用户数据
  Future<void> _refreshUserData() async {
    try {
      await ref.refreshUser();
      // 强制重新构建当前页面
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('刷新用户数据失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // 获取主题色，如果没有主题则使用默认蓝色
    final themeColor = currentTheme.colorList.isNotEmpty == true
        ? currentTheme.colorList[0]
        : Colors.blue;
    final activeColor = isDarkMode ? themeColor.withAlpha(204) : themeColor;

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      appBar: ThemeAwareAppBar(title: '个人资料设置'),
      body: authState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : authState.errorMessage != null
          ? Center(child: Text('加载失败: ${authState.errorMessage}'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 个人信息卡片
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF2A2A2A).withAlpha(217)
                        : Colors.white.withAlpha(128),
                    borderRadius: BorderRadius.circular(16),
                    border: isDarkMode
                        ? Border.all(
                            color: Colors.white.withAlpha(26),
                            width: 1,
                          )
                        : null,
                    boxShadow: isDarkMode
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.grey.withAlpha(51),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.grey.withAlpha(25),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '基本信息',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // 头像 - 使用缓存组件
                        Center(
                          child: GestureDetector(
                            onTap: _isUploadingAvatar
                                ? null
                                : () => _showAvatarUploadDialog(
                                    context,
                                    ref,
                                    themeColor,
                                  ),
                            child: Stack(
                              children: [
                                // 头像或加载动画
                                _isUploadingAvatar
                                    ? Container(
                                        width: 100,
                                        height: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade300,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 3,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  themeColor,
                                                ),
                                          ),
                                        ),
                                      )
                                    : CachedAvatar(
                                        imageUrl: user?.avatarUrl,
                                        radius: 50,
                                        backgroundColor: Colors.grey.shade300,
                                        child: Icon(
                                          Icons.person,
                                          size: 50,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                // 相机图标
                                if (!_isUploadingAvatar)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      width: 30,
                                      height: 30,
                                      decoration: BoxDecoration(
                                        color: themeColor,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isDarkMode
                                              ? Colors.grey.shade800
                                              : Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // 姓名（只读）
                        _buildInfoItem(
                          '用户名',
                          user?.name ?? '未设置',
                          Icons.person_outline,
                          isDarkMode,
                        ),

                        // 学号（只读）
                        _buildInfoItem(
                          '学号',
                          user?.studentId ?? '未设置',
                          Icons.badge_outlined,
                          isDarkMode,
                          readOnly: true,
                        ),

                        // 邮箱
                        _buildInfoItem(
                          '邮箱',
                          user?.email ?? '未设置',
                          Icons.email_outlined,
                          isDarkMode,
                          onTap: () =>
                              _showEditDialog(context, '邮箱', user?.email ?? ''),
                        ),

                        // 学院
                        _buildInfoItem(
                          '学院',
                          user?.college.isNotEmpty == true
                              ? user!.college
                              : '未设置',
                          Icons.school_outlined,
                          isDarkMode,
                        ),

                        // 专业
                        _buildInfoItem(
                          '专业',
                          user?.major.isNotEmpty == true ? user!.major : '未设置',
                          Icons.book_outlined,
                          isDarkMode,
                        ),

                        // 班级
                        _buildInfoItem(
                          '班级',
                          user?.className.isNotEmpty == true
                              ? user!.className
                              : '未设置',
                          Icons.group_outlined,
                          isDarkMode,
                        ),

                        // 个人简介
                        _buildInfoItem(
                          '个人简介',
                          user?.bio.isNotEmpty == true ? user!.bio : '未设置',
                          Icons.info_outlined,
                          isDarkMode,
                          onTap: () =>
                              _showEditDialog(context, '个人简介', user?.bio ?? ''),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 注：密码修改和指纹登录功能已按要求移除

                // 隐私设置
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF2A2A2A).withAlpha(217)
                        : Colors.white.withAlpha(128),
                    borderRadius: BorderRadius.circular(16),
                    border: isDarkMode
                        ? Border.all(
                            color: Colors.white.withAlpha(26),
                            width: 1,
                          )
                        : null,
                    boxShadow: isDarkMode
                        ? null
                        : [
                            BoxShadow(
                              color: Colors.grey.withAlpha(51),
                              blurRadius: 20,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.grey.withAlpha(25),
                              blurRadius: 6,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '隐私设置',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),

                        SwitchListTile(
                          title: Text(
                            '允许数据统计',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            '帮助改进应用体验',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                          value: true,
                          onChanged: (value) {
                            // TODO: 实现数据统计开关
                          },
                          contentPadding: EdgeInsets.zero,
                          activeColor: activeColor,
                        ),

                        SwitchListTile(
                          title: Text(
                            '崩溃报告',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            '自动发送崩溃日志',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                          value: true,
                          onChanged: (value) {
                            // TODO: 实现崩溃报告开关
                          },
                          contentPadding: EdgeInsets.zero,
                          activeColor: activeColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    String field,
    String currentValue,
  ) {
    showDialog(
      context: context,
      builder: (context) => _EditFieldDialog(
        field: field,
        currentValue: currentValue,
        onSuccess: _refreshUserData,
      ),
    );
  }

  /// 显示头像上传选项对话框
  void _showAvatarUploadDialog(
    BuildContext context,
    WidgetRef ref,
    Color themeColor,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '选择头像',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildUploadOption(
                  context,
                  ref,
                  Icons.camera_alt,
                  '拍照',
                  ImageSource.camera,
                  themeColor,
                ),
                _buildUploadOption(
                  context,
                  ref,
                  Icons.photo_library,
                  '从相册选择',
                  ImageSource.gallery,
                  themeColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 构建上传选项按钮
  Widget _buildUploadOption(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String label,
    ImageSource source,
    Color themeColor,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        _pickAndUploadImage(context, ref, source);
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: themeColor.withAlpha(26),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, size: 30, color: themeColor),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  /// 选择并上传头像
  Future<void> _pickAndUploadImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      debugPrint('🎬 开始头像上传流程...');
      debugPrint('📷 图片来源: ${source == ImageSource.camera ? "相机" : "相册"}');

      // 1. 检查并请求权限
      final permissionChecker = ref.read(permissionCheckerProvider);
      bool hasPermission;

      if (source == ImageSource.camera) {
        hasPermission = await permissionChecker.ensureCameraPermission(context);
      } else {
        hasPermission = await permissionChecker.ensurePhotosPermission(context);
      }

      if (!hasPermission) {
        debugPrint('❌ 权限检查失败');
        return;
      }

      // 2. 使用图片服务选择和处理图片（裁剪+压缩）
      debugPrint('🖼️ 第2步：选择和处理图片...');
      final imageService = ImageService();
      final processedImageFile = await imageService.pickAndProcessAvatar(
        source: source,
      );

      // 如果用户取消了裁剪，返回
      if (processedImageFile == null) {
        debugPrint('❌ 用户取消了图片选择或裁剪');
        return;
      }

      debugPrint('✅ 图片处理完成: ${processedImageFile.path}');
      debugPrint('📊 文件大小: ${await processedImageFile.length()} bytes');

      // 3. 开始上传，设置加载状态
      if (mounted) {
        setState(() {
          _isUploadingAvatar = true;
        });
      }

      // 3. 上传图片到OSS
      debugPrint('☁️ 第3步：上传图片到OSS...');
      final authState = ref.read(authProvider);
      final studentId = authState.user?.studentId ?? '';

      final imageUploadService = ref.read(imageUploadServiceProvider);
      final uploadContext = studentId.isNotEmpty
          ? ImageUploadContext.fromStudentId(studentId)
          : ImageUploadContext.empty();

      final avatarUrl = await imageUploadService.uploadImage(
        processedImageFile.path,
        context: uploadContext,
        prefix: 'avatar',
      );

      debugPrint('🎉 图片上传成功！头像URL: $avatarUrl');

      // 5. 更新用户信息到服务器
      debugPrint('👤 第4步：更新用户信息到服务器...');
      if (authState.user != null) {
        final updatedUser = authState.user!.copyWith(avatarUrl: avatarUrl);
        final userMap = {
          'name': updatedUser.name,
          'studentId': updatedUser.studentId,
          'email': updatedUser.email,
          'college': updatedUser.college,
          'major': updatedUser.major,
          'className': updatedUser.className,
          'bio': updatedUser.bio,
          'avatarUrl': avatarUrl,
        };

        debugPrint('📋 准备更新的用户信息:');
        debugPrint('  - name: ${updatedUser.name}');
        debugPrint('  - studentId: ${updatedUser.studentId}');
        debugPrint('  - avatarUrl: $avatarUrl');

        final apiService = ref.read(apiServiceProvider);
        final response = await apiService.modifyPersonalInfo(userMap);
        debugPrint('📬 用户信息更新响应: $response');
        final success = response['success'] ?? false;
        debugPrint('✅ 用户信息更新${success ? "成功" : "失败"}');

        // 6. API成功后，立即更新本地状态
        debugPrint('🔄 第5步：更新本地状态...');
        if (success) {
          try {
            final currentUser = authState.user;
            if (currentUser != null) {
              debugPrint('👤 当前用户: ${currentUser.name}');

              // 清除旧头像的缓存（包括所有可能的URL变体）
              final imageCacheService = ImageCacheService();
              if (currentUser.avatarUrl.isNotEmpty) {
                // 移除旧URL的缓存
                final oldUrl = currentUser.avatarUrl.split('?').first; // 去除时间戳
                await imageCacheService.removeFromCache(oldUrl);
                await imageCacheService.removeFromCache(currentUser.avatarUrl);
                debugPrint('🗑️ 已清除旧头像缓存');
              }

              // 清除新头像URL的缓存（以防万一）
              await imageCacheService.removeFromCache(avatarUrl);

              // 添加时间戳参数强制刷新
              final timestamp = DateTime.now().millisecondsSinceEpoch;
              final avatarUrlWithTimestamp = '$avatarUrl?t=$timestamp';

              // 更新用户信息
              final updatedUser = currentUser.copyWith(
                avatarUrl: avatarUrlWithTimestamp,
              );
              debugPrint('🔄 更新用户头像URL（带时间戳）: $avatarUrlWithTimestamp');
              ref.updateUser(updatedUser);

              debugPrint('✅ 本地状态更新完成');
            } else {
              debugPrint('⚠️ 当前用户为null');
            }
          } catch (e) {
            debugPrint('❌ 更新用户状态失败: $e');
          }

          // 关闭加载状态
          if (mounted) {
            setState(() {
              _isUploadingAvatar = false;
            });
          }

          // 7. 显示成功提示
          if (context.mounted) {
            ToastService.show('头像上传成功', backgroundColor: Colors.green);
          }
        } else {
          // 关闭加载状态
          if (mounted) {
            setState(() {
              _isUploadingAvatar = false;
            });
          }

          if (context.mounted) {
            await ThemeAwareDialog.showAlertDialog(
              context,
              title: '上传失败',
              message: '头像上传失败，请重试',
              buttonText: '确定',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ 上传过程发生错误: $e');

      // 关闭加载状态
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }

      if (context.mounted) {
        // 特殊处理SSL证书错误
        String errorMessage = '上传失败';
        if (e.toString().contains('CERTIFICATE_VERIFY_FAILED') ||
            e.toString().contains('certificate has expired') ||
            e.toString().contains('unable to get local issuer certificate')) {
          errorMessage = '服务器SSL证书问题，请联系技术管理员处理证书配置';
        } else if (e.toString().contains('HandshakeException')) {
          errorMessage = 'SSL握手失败，这是服务器端证书配置问题，请联系管理员';
        } else {
          errorMessage =
              '上传失败: ${e.toString().length > 100 ? "${e.toString().substring(0, 100)}..." : e.toString()}';
        }

        await ThemeAwareDialog.showAlertDialog(
          context,
          title: '上传失败',
          message: errorMessage,
          buttonText: '确定',
        );
      }
    }
  }

  /// 构建信息项目
  Widget _buildInfoItem(
    String label,
    String value,
    IconData icon,
    bool isDarkMode, {
    VoidCallback? onTap,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: readOnly ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDarkMode ? Colors.white70 : Colors.black54,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDarkMode
                            ? (readOnly ? Colors.white38 : Colors.white)
                            : (readOnly ? Colors.black38 : Colors.black),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!readOnly && onTap != null)
                Icon(
                  Icons.edit,
                  color: isDarkMode ? Colors.white54 : Colors.black45,
                  size: 18,
                ),
              if (readOnly)
                Icon(
                  Icons.lock_outline,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 编辑字段对话框（支持加载状态）
class _EditFieldDialog extends ConsumerStatefulWidget {
  final String field;
  final String currentValue;
  final Future<void> Function()? onSuccess;

  const _EditFieldDialog({
    required this.field,
    required this.currentValue,
    this.onSuccess,
  });

  @override
  ConsumerState<_EditFieldDialog> createState() => _EditFieldDialogState();
}

class _EditFieldDialogState extends ConsumerState<_EditFieldDialog> {
  late TextEditingController _controller;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(
        '编辑${widget.field}',
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
      ),
      content: TextField(
        controller: _controller,
        enabled: !_isSaving, // 保存时禁用输入
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          labelText: widget.field,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
          border: const OutlineInputBorder(),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(
              color: isDarkMode ? Colors.white30 : Colors.black26,
            ),
          ),
        ),
        keyboardType: widget.field == '邮箱'
            ? TextInputType.emailAddress
            : TextInputType.text,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            '取消',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveField,
          child: _isSaving
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('保存中...'),
                  ],
                )
              : const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _saveField() async {
    if (_isSaving) return;

    final newValue = _controller.text.trim();
    if (newValue == widget.currentValue) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final authState = ref.read(authProvider);
      if (authState.user == null) return;

      // 构建更新后的用户信息
      final user = authState.user!;
      Map<String, dynamic> userMap;

      switch (widget.field) {
        case '邮箱':
          // 邮箱验证
          final emailRegex = RegExp(
            r'^[\w\-.]+@[\w\-.]+\.[A-Z]{2,4}$',
            caseSensitive: false,
          );
          if (!emailRegex.hasMatch(newValue)) {
            if (mounted) {
              ToastService.show('请输入有效的邮箱地址', backgroundColor: Colors.red);
            }
            return;
          }
          userMap = {
            'name': user.name,
            'studentId': user.studentId,
            'email': newValue,
            'college': user.college,
            'major': user.major,
            'className': user.className,
            'bio': user.bio,
            'avatarUrl': user.avatarUrl,
          };
          break;
        case '个人简介':
          userMap = {
            'name': user.name,
            'studentId': user.studentId,
            'email': user.email,
            'college': user.college,
            'major': user.major,
            'className': user.className,
            'bio': newValue,
            'avatarUrl': user.avatarUrl,
          };
          break;
        default:
          if (mounted) {
            ToastService.show(
              '不支持编辑${widget.field}',
              backgroundColor: Colors.red,
            );
          }
          return;
      }

      // 调用API保存
      final apiService = ref.read(apiServiceProvider);
      final response = await apiService.modifyPersonalInfo(userMap);

      if (mounted) {
        if (response['success'] == true) {
          // API成功后，直接更新本地状态为用户输入的新值
          try {
            final authState = ref.read(authProvider);
            final currentUser = authState.user;
            if (currentUser != null) {
              // 直接使用用户输入的新值
              final updatedUser = currentUser.copyWith(
                email: widget.field == '邮箱' ? newValue : currentUser.email,
                bio: widget.field == '个人简介' ? newValue : currentUser.bio,
              );

              // 立即更新状态 - 这样UI就会显示用户输入的值
              ref.updateUser(updatedUser);
            }
          } catch (e) {
            debugPrint('更新用户状态失败: $e');
          }

          Navigator.of(context).pop();
          ToastService.show(
            '${widget.field}修改成功',
            backgroundColor: Colors.green,
          );
        } else {
          ToastService.show('${widget.field}修改失败', backgroundColor: Colors.red);
        }
      }
    } catch (e) {
      if (mounted) {
        ToastService.show('修改失败: $e', backgroundColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
