// lib/pages/lifeService/widgets/grade_transcript_tab.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../../../core/models/grade_models.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/services/preview_service.dart';
import '../../../core/services/permission_service.dart';

/// 成绩单Tab页
class GradeTranscriptTab extends ConsumerStatefulWidget {
  const GradeTranscriptTab({super.key});

  @override
  ConsumerState<GradeTranscriptTab> createState() => _GradeTranscriptTabState();
}

class _GradeTranscriptTabState extends ConsumerState<GradeTranscriptTab> {
  final TextEditingController _emailController = TextEditingController();
  int _selectedTranscriptIndex = 0;
  String _jdType = '1'; // 绩点类型
  String _pmType = '1'; // 排名类型
  String _pjfType = '0'; // 平均分类型
  bool _isLoading = false;

  // 成绩单类型列表
  final List<TranscriptType> _transcriptTypes = [
    TranscriptType(
      name: '中文成绩单',
      fileProperty: 'c5bdaa73-4076-48ad-87d6-c5435922524f',
    ),
    TranscriptType(
      name: '英文成绩单',
      fileProperty: '72dd8cfb-56d3-40ed-958a-f9dd552a9e06',
    ),
    TranscriptType(
      name: '最好成绩中文成绩单',
      fileProperty: '77886b51-b8ce-4fc5-863f-3ebc08b18d74',
    ),
    TranscriptType(
      name: '最好成绩英文成绩单',
      fileProperty: '10bda17a-2548-4091-8b5f-f0709dc74427',
    ),
    TranscriptType(
      name: '中文辅修成绩单',
      fileProperty: 'b52d541e-ad41-4305-a90b-13df4583fe50',
    ),
    TranscriptType(
      name: '英文辅修成绩单',
      fileProperty: 'a918fd1c-0a47-450c-ab65-763f5ce97968',
    ),
    TranscriptType(
      name: '最好成绩中文辅修成绩单',
      fileProperty: '6ffd75e1-7c7c-40d0-9e49-9a419c10eb24',
    ),
    TranscriptType(
      name: '最好成绩英文辅修成绩单',
      fileProperty: '14c6354a-1f8f-40ae-b531-5dce30287dfc',
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
    final themeColor = currentTheme?.colorList.isNotEmpty == true
        ? currentTheme!.colorList[0]
        : Colors.blue;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 成绩单类型选择
          _buildTranscriptTypeSelector(isDarkMode, themeColor),

          const SizedBox(height: 20),

          // 绩点类型选择
          _buildGpaTypeSelector(isDarkMode, themeColor),

          const SizedBox(height: 20),

          // 排名类型选择
          _buildRankingTypeSelector(isDarkMode, themeColor),

          const SizedBox(height: 20),

          // 平均分类型选择
          _buildAverageTypeSelector(isDarkMode, themeColor),

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

  /// 构建成绩单类型选择器
  Widget _buildTranscriptTypeSelector(bool isDarkMode, Color themeColor) {
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
            '成绩单类型',
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

          // 成绩单选项（2列网格布局）
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
            ),
            itemCount: _transcriptTypes.length,
            itemBuilder: (context, index) {
              final isSelected = index == _selectedTranscriptIndex;
              final transcript = _transcriptTypes[index];

              return InkWell(
                onTap: () {
                  if (isSelected) {
                    // 如果已选中，则预览
                    _previewTranscript(index, themeColor);
                  } else {
                    // 如果未选中，则选择
                    setState(() {
                      _selectedTranscriptIndex = index;
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
                        ? Colors.blue.withAlpha(204)
                        : (isDarkMode
                              ? Colors.grey.shade700
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        transcript.name,
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

  /// 构建绩点类型选择器
  Widget _buildGpaTypeSelector(bool isDarkMode, Color themeColor) {
    return _buildRadioSection(
      '绩点类型',
      _jdType,
      [
        {'value': '0', 'label': '不显示'},
        {'value': '1', 'label': '全科平均绩点'},
        {'value': '2', 'label': '授予学位学科平均绩点'},
      ],
      (value) => setState(() => _jdType = value),
      isDarkMode,
      themeColor,
    );
  }

  /// 构建排名类型选择器
  Widget _buildRankingTypeSelector(bool isDarkMode, Color themeColor) {
    return _buildRadioSection(
      '排名类型',
      _pmType,
      [
        {'value': '0', 'label': '不显示'},
        {'value': '1', 'label': '所有必修课排名'},
        {'value': '2', 'label': '授予学位学科排名'},
      ],
      (value) {
        setState(() {
          _pmType = value;
          if (value != '0') _pjfType = '0'; // 排名和平均分互斥
        });
      },
      isDarkMode,
      themeColor,
    );
  }

  /// 构建平均分类型选择器
  Widget _buildAverageTypeSelector(bool isDarkMode, Color themeColor) {
    return _buildRadioSection(
      '平均分类型',
      _pjfType,
      [
        {'value': '0', 'label': '不显示'},
        {'value': '1', 'label': '所有必修课正考成绩加权平均分'},
        {'value': '2', 'label': '授予学位学科成绩加权平均分'},
      ],
      (value) {
        setState(() {
          _pjfType = value;
          if (value != '0') _pmType = '0'; // 排名和平均分互斥
        });
      },
      isDarkMode,
      themeColor,
    );
  }

  /// 构建单选组件
  Widget _buildRadioSection(
    String title,
    String currentValue,
    List<Map<String, String>> options,
    Function(String) onChanged,
    bool isDarkMode,
    Color themeColor,
  ) {
    return Container(
      width: double.infinity,
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
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),

          Column(
            children: options.map((option) {
              final value = option['value']!;
              final label = option['label']!;

              return RadioListTile<String>(
                title: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                value: value,
                groupValue: currentValue,
                onChanged: (newValue) => onChanged(newValue!),
                activeColor: themeColor,
                contentPadding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
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
            '成绩单将发送至以下邮箱',
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
        onPressed: (_isLoading || !isEmailValid) ? null : _sendTranscript,
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
                '发送成绩单',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }

  /// 预览成绩单
  Future<void> _previewTranscript(int index, Color themeColor) async {
    try {
      _showSnackBar('正在生成预览...', themeColor);

      final apiService = ref.read(apiServiceProvider);
      final selectedTranscript = _transcriptTypes[index];
      final isDarkMode = ref.read(effectiveIsDarkModeProvider);

      final result = await apiService.studyCertificate({
        'fileProperty': selectedTranscript.fileProperty,
        'jd': _jdType,
        'pjf': _pjfType,
        'pm': _pmType,
      });

      if (result['success'] == true) {
        final data = result['data'];
        final smallImageList = data['smallImageList'];

        if (smallImageList != null && mounted) {
          // 显示预览模态框
          await PreviewService.showPreviewModal(
            context,
            base64Image: smallImageList,
            title: selectedTranscript.name,
            isDarkMode: isDarkMode,
          );
        } else {
          _showSnackBar('预览生成失败', themeColor);
        }
      } else {
        _showSnackBar('预览生成失败，请稍后再试', themeColor);
      }
    } catch (e) {
      _showSnackBar('预览生成失败: $e', themeColor);
    }
  }

  /// 发送成绩单
  Future<void> _sendTranscript() async {
    if (!_isValidEmail(_emailController.text)) {
      _showSnackBar('请输入正确的邮箱地址', Colors.red);
      return;
    }

    // 先申请存储权限（用于可能的本地保存）
    final shouldContinue =
        await PermissionService.showPermissionRationaleDialog(
          context,
          title: '权限申请',
          content: '为了更好地为您服务，我们需要存储权限来保存成绩单到本地。您也可以选择跳过，仅发送到邮箱。',
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
              content: '没有存储权限，但您仍可以将成绩单发送到邮箱。是否继续？',
              confirmText: '继续',
              cancelText: '取消',
            );
        if (!continueAnyway) return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(apiServiceProvider);
      final selectedTranscript = _transcriptTypes[_selectedTranscriptIndex];

      // 显示处理进度
      PermissionService.showSaveProgressDialog(context, '正在生成成绩单...');

      // 1. 先生成成绩单
      final studyCertResult = await apiService.studyCertificate({
        'fileProperty': selectedTranscript.fileProperty,
        'jd': _jdType,
        'pjf': _pjfType,
        'pm': _pmType,
      });

      if (studyCertResult['success'] == true) {
        final data = studyCertResult['data'];
        final fileUrl = data['fileUrl'];
        final pdfSerialId = data['pdfSerialId'];

        // 2. 发送邮件
        await apiService.sendStudyCertificate({
          'fileUrl': fileUrl,
          'pdfSerialId': pdfSerialId,
          'fileName': selectedTranscript.name,
          'vcid': selectedTranscript.fileProperty,
          'toEmail': _emailController.text,
        });

        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          PermissionService.showSuccessSnackBar(context, '成绩单发送成功，请查看您的邮箱');
          _emailController.clear();
        }
      } else {
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          PermissionService.showErrorSnackBar(context, '成绩单生成失败，请稍后再试');
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

  /// 显示提示消息
  void _showSnackBar(String message, Color themeColor) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: themeColor),
      );
    }
  }
}
