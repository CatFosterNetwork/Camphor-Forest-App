// lib/pages/lifeService/widgets/grade_voucher_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camphor_forest/core/services/toast_service.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../../../core/models/grade_models.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/preview_service.dart';
import '../../../core/services/permission_service.dart';

/// 电子凭证Tab页
class GradeVoucherTab extends ConsumerStatefulWidget {
  const GradeVoucherTab({super.key});

  @override
  ConsumerState<GradeVoucherTab> createState() => _GradeVoucherTabState();
}

class _GradeVoucherTabState extends ConsumerState<GradeVoucherTab> {
  final TextEditingController _emailController = TextEditingController();
  int _selectedVoucherIndex = 0;
  bool _isLoading = false;

  // 电子凭证类型列表
  final List<VoucherType> _voucherTypes = [
    VoucherType(
      name: '中文在读证明',
      fileProperty: 'f4b7f9f8-3782-48b3-8256-276bd2d9ecc8',
    ),
    VoucherType(
      name: '英文在读证明',
      fileProperty: '8523b3e3-a2fb-425e-bbe4-943efcd17eca',
    ),
    VoucherType(
      name: '中文预毕业证明',
      fileProperty: '3103cfef-c0bb-4666-86ee-e757cba7e987',
    ),
    VoucherType(
      name: '英文预毕业证明',
      fileProperty: '2ff6ce06-6ab9-43a5-beb7-4dd33587c3d9',
    ),
    VoucherType(
      name: '中文绩点计算证明',
      fileProperty: '8e69e2dd-4b25-4ebe-8544-2a0b73f7cde9',
    ),
    VoucherType(
      name: '英文绩点计算证明',
      fileProperty: '4a850fe4-3d6e-427a-94b9-13891adfc6e4',
    ),
  ];

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);
    final themeColor = currentTheme.colorList.isNotEmpty == true
        ? currentTheme.colorList[0]
        : Colors.orange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 说明文本
          _buildDescriptionCard(isDarkMode),

          const SizedBox(height: 20),

          // 电子凭证类型选择
          _buildVoucherTypeSelector(isDarkMode, themeColor),

          const SizedBox(height: 20),

          // 邮箱输入
          _buildEmailInput(isDarkMode, themeColor),

          const SizedBox(height: 30),

          // 发送按钮
          _buildSendButton(isDarkMode, themeColor),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  /// 构建说明卡片
  Widget _buildDescriptionCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withAlpha(76), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.amber.shade600, size: 20),
              const SizedBox(width: 8),
              Text(
                '电子凭证说明',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Text(
            '• 电子凭证是官方认可的学业证明文件\n'
            '• 可用于求职、升学等正式场合\n'
            '• 支持中英文两种语言版本\n'
            '• 生成后将以PDF格式发送至您的邮箱',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建电子凭证类型选择器
  Widget _buildVoucherTypeSelector(bool isDarkMode, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withAlpha(128)
            : Colors.white.withAlpha(204),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '电子凭证类型',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),

          // 中英文标题行
          Row(
            children: [
              Expanded(
                child: Text(
                  '中文',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'English',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 电子凭证选项（2列网格布局）
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: _voucherTypes.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedVoucherIndex;
              final voucher = _voucherTypes[index];

              return InkWell(
                onTap: () {
                  if (isSelected) {
                    // 如果已选中，则预览
                    _previewVoucher(index, themeColor);
                  } else {
                    // 如果未选中，则选择
                    setState(() {
                      _selectedVoucherIndex = index;
                    });
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? themeColor.withAlpha(204)
                        : (isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? themeColor : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        voucher.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDarkMode ? Colors.white : Colors.black),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isSelected ? '点击预览' : '点击选择',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected
                              ? Colors.white.withAlpha(204)
                              : (isDarkMode ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 构建邮箱输入框
  Widget _buildEmailInput(bool isDarkMode, Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withAlpha(128)
            : Colors.white.withAlpha(204),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '邮箱地址',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            '电子凭证将发送至以下邮箱',
            style: TextStyle(
              fontSize: 12,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: '请输入邮箱地址',
              hintStyle: TextStyle(
                color: isDarkMode ? Colors.white54 : Colors.black54,
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDarkMode
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: themeColor, width: 2),
              ),
              filled: true,
              fillColor: isDarkMode
                  ? Colors.grey.shade700
                  : Colors.grey.shade50,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建发送按钮
  Widget _buildSendButton(bool isDarkMode, Color themeColor) {
    final isEmailValid = _isValidEmail(_emailController.text);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: (_isLoading || !isEmailValid) ? null : _sendVoucher,
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25), // 改为圆弧样式
          ),
          elevation: 2,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                '发送电子凭证',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  /// 预览电子凭证
  Future<void> _previewVoucher(int index, Color themeColor) async {
    // 显示加载对话框
    _showLoadingDialog('正在生成预览...');

    try {
      final apiService = ref.read(apiServiceProvider);
      final selectedVoucher = _voucherTypes[index];
      final isDarkMode = ref.read(effectiveIsDarkModeProvider);

      // 设置30秒超时
      final result = await apiService
          .studyCertificate({'fileProperty': selectedVoucher.fileProperty})
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('请求超时，请稍后再试'),
          );

      if (mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
      }

      if (result['success'] == true) {
        final data = result['data'];
        final smallImageList = data['smallImageList'];

        if (smallImageList != null && mounted) {
          // 显示预览模态框
          await PreviewService.showPreviewModal(
            context,
            base64Image: smallImageList,
            title: selectedVoucher.name,
            isDarkMode: isDarkMode,
          );
        } else {
          _showSnackBar('预览生成失败', themeColor);
        }
      } else {
        _showSnackBar('预览生成失败，请稍后再试', themeColor);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭加载对话框
      }
      _showSnackBar('预览生成失败: $e', themeColor);
    }
  }

  /// 发送电子凭证
  Future<void> _sendVoucher() async {
    if (!_isValidEmail(_emailController.text)) {
      _showSnackBar('请输入正确的邮箱地址', Colors.red);
      return;
    }

    // 先申请存储权限（用于可能的本地保存）
    final shouldContinue =
        await PermissionService.showPermissionRationaleDialog(
          context,
          title: '权限申请',
          content: '为了更好地为您服务，我们需要存储权限来保存电子凭证到本地。您也可以选择跳过，仅发送到邮箱。',
          confirmText: '授予权限',
          cancelText: '跳过',
        );

    if (shouldContinue) {
      final hasPermission =
          await PermissionService.checkAndRequestStoragePermission(context);
      if (!hasPermission) {
        final continueAnyway =
            await PermissionService.showPermissionRationaleDialog(
              context,
              title: '继续操作',
              content: '没有存储权限，但您仍可以将电子凭证发送到邮箱。是否继续？',
              confirmText: '继续',
              cancelText: '取消',
            );
        if (!continueAnyway) return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final selectedVoucher = _voucherTypes[_selectedVoucherIndex];

      // 显示处理进度
      PermissionService.showSaveProgressDialog(context, '正在生成电子凭证...');

      // 1. 先生成电子凭证
      final studyCertResult = await apiService.studyCertificate({
        'fileProperty': selectedVoucher.fileProperty,
      });

      if (studyCertResult['success'] == true) {
        final data = studyCertResult['data'];
        final fileUrl = data['fileUrl'];
        final pdfSerialId = data['pdfSerialId'];

        // 2. 发送邮件
        await apiService.sendStudyCertificate({
          'fileUrl': fileUrl,
          'pdfSerialId': pdfSerialId,
          'fileName': selectedVoucher.name,
          'vcid': selectedVoucher.fileProperty,
          'toEmail': _emailController.text,
        });

        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          PermissionService.showSuccessSnackBar(context, '电子凭证发送成功，请查看您的邮箱');
          _emailController.clear();
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          PermissionService.showErrorSnackBar(context, '电子凭证生成失败，请稍后再试');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        PermissionService.showErrorSnackBar(context, '发送失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 验证邮箱格式
  bool _isValidEmail(String email) {
    return RegExp(
      r'^[\w\-.]+@[\w\-.]+\.[A-Z]{2,4}$',
      caseSensitive: false,
    ).hasMatch(email);
  }

  /// 显示加载对话框
  void _showLoadingDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false, // 不允许点击外部关闭
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
    }
  }

  /// 显示提示消息
  void _showSnackBar(String message, Color themeColor) {
    if (!mounted) return;
    ToastService.show(
      message,
      backgroundColor: themeColor,
      textColor: Colors.white,
    );
  }
}
