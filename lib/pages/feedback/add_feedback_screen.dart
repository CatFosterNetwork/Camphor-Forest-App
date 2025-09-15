// lib/pages/feedback/add_feedback_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/config/providers/theme_config_provider.dart';
import '../../core/providers/permission_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';
import 'providers/feedback_provider.dart';
import 'widgets/image_upload_widget.dart';

/// Add feedback screen
class AddFeedbackScreen extends ConsumerStatefulWidget {
  const AddFeedbackScreen({super.key});

  @override
  ConsumerState<AddFeedbackScreen> createState() => _AddFeedbackScreenState();
}

class _AddFeedbackScreenState extends ConsumerState<AddFeedbackScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Reset form state when entering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(addFeedbackProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _emailController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!mounted) return;

    // 使用全局权限管理器选择图片
    final imagePath = await ref
        .read(permissionProvider.notifier)
        .pickImage(context: context, source: ImageSource.gallery);

    if (imagePath != null && mounted) {
      ref.read(addFeedbackProvider.notifier).addImage(File(imagePath));
    }
  }

  Future<void> _takePhoto() async {
    if (!mounted) return;

    // 使用全局权限管理器拍照
    final imagePath = await ref
        .read(permissionProvider.notifier)
        .pickImage(context: context, source: ImageSource.camera);

    if (imagePath != null && mounted) {
      ref.read(addFeedbackProvider.notifier).addImage(File(imagePath));
    }
  }

  void _showImageSourceDialog() {
    final isDarkMode = ref.read(effectiveIsDarkModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        title: Text(
          '选择图片来源',
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: Text(
                '从相册选择',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.green),
              title: Text(
                '拍照',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (!mounted) return;

    final success = await ref
        .read(addFeedbackProvider.notifier)
        .submitFeedback();

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('提交成功'), backgroundColor: Colors.green),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final addFeedbackState = ref.watch(addFeedbackProvider);

    // Listen to form changes
    ref.listen(addFeedbackProvider, (previous, current) {
      if (current.error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(current.error!), backgroundColor: Colors.red),
        );
        if (mounted) {
          ref.read(addFeedbackProvider.notifier).clearError();
        }
      }
    });

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: false,
      appBar: ThemeAwareAppBar(title: '新反馈'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title section
            _buildSectionTitle('添加标题', isDarkMode),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _titleController,
              hintText: '标题',
              onChanged: (value) {
                ref.read(addFeedbackProvider.notifier).updateTitle(value);
              },
              isDarkMode: isDarkMode,
              isValid: addFeedbackState.title.isNotEmpty,
            ),

            const SizedBox(height: 24),

            // Email section
            _buildSectionTitle('联系方式', isDarkMode),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _emailController,
              hintText: '邮箱',
              keyboardType: TextInputType.emailAddress,
              onChanged: (value) {
                ref.read(addFeedbackProvider.notifier).updateEmail(value);
              },
              isDarkMode: isDarkMode,
              isValid:
                  addFeedbackState.email.isNotEmpty &&
                  RegExp(
                    r'^[\w\-.]+@[\w\-.]+\.[A-Z]{2,4}$',
                    caseSensitive: false,
                  ).hasMatch(addFeedbackState.email),
            ),

            const SizedBox(height: 24),

            // Content section
            _buildSectionTitle('添加描述', isDarkMode),
            const SizedBox(height: 8),
            _buildContentField(isDarkMode, addFeedbackState),

            const SizedBox(height: 24),

            // Images section
            _buildSectionTitle('上传图片', isDarkMode),
            const SizedBox(height: 8),
            ImageUploadWidget(
              images: addFeedbackState.images,
              onAddImage: _showImageSourceDialog,
              onRemoveImage: (index) {
                ref.read(addFeedbackProvider.notifier).removeImage(index);
              },
            ),

            const SizedBox(height: 32),

            // Submit button
            _buildSubmitButton(addFeedbackState, isDarkMode),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required Function(String) onChanged,
    required bool isDarkMode,
    required bool isValid,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: controller.text.isEmpty
              ? Colors.grey
              : isValid
              ? Colors.green
              : Colors.red,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(
          color: isDarkMode ? Colors.white : const Color(0xFF303133),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: isDarkMode
                ? const Color(0xFFA9AAAC)
                : const Color(0xFF909399),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildContentField(bool isDarkMode, AddFeedbackState state) {
    return Container(
      constraints: const BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _contentController.text.isEmpty
              ? Colors.grey
              : state.content.isNotEmpty
              ? Colors.green
              : Colors.red,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _contentController,
        maxLines: null,
        maxLength: 1000,
        onChanged: (value) {
          ref.read(addFeedbackProvider.notifier).updateContent(value);
        },
        style: TextStyle(
          color: isDarkMode ? Colors.white : const Color(0xFF303133),
        ),
        decoration: InputDecoration(
          hintText: '描述',
          hintStyle: TextStyle(
            color: isDarkMode
                ? const Color(0xFFA9AAAC)
                : const Color(0xFF909399),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
          counterStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AddFeedbackState state, bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: state.isValid && !state.isSubmitting
            ? _submitFeedback
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: state.isValid
              ? Colors.green.withAlpha(isDarkMode ? 204 : 255)
              : Colors.green.withAlpha(128),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: state.isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                '提交',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
      ),
    );
  }
}
