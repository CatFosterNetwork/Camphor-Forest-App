// lib/pages/settings/custom_theme_settings_page.dart

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:camphor_forest/core/services/toast_service.dart';

import '../../core/providers/permission_provider.dart';
import '../../core/config/providers/theme_config_provider.dart';
import '../../core/models/theme_model.dart' as theme_model;
import '../../core/widgets/theme_aware_scaffold.dart';
import '../../core/widgets/theme_aware_dialog.dart';

class CustomThemeSettingsPage extends ConsumerStatefulWidget {
  final String? themeId; // 'create' 或 具体的主题代码

  const CustomThemeSettingsPage({super.key, this.themeId});

  @override
  ConsumerState<CustomThemeSettingsPage> createState() =>
      _CustomThemeSettingsPageState();
}

class _CustomThemeSettingsPageState
    extends ConsumerState<CustomThemeSettingsPage> {
  theme_model.Theme? customTheme;
  bool isInitializing = true;
  String? customThemeId;
  bool isCreateMode = false; // 是否是创建模式
  bool hasUnsavedChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeTheme();
  }

  void _initializeTheme() async {
    try {
      final themeId = widget.themeId;

      if (themeId == 'create') {
        // 创建新主题模式
        await _createNewTheme();
      } else if (themeId != null) {
        // 编辑现有主题模式
        await _loadExistingTheme(themeId);
      } else {
        // 默认模式（向后兼容）
        await _loadDefaultTheme();
      }
    } catch (e) {
      AppLogger.debug('初始化主题失败: $e');
      await _loadDefaultTheme();
    } finally {
      if (mounted) {
        setState(() {
          isInitializing = false;
        });
      }
    }
  }

  Future<void> _createNewTheme() async {
    final currentTheme = ref.read(selectedCustomThemeProvider);
    final baseTheme = currentTheme.colorList.isNotEmpty
        ? currentTheme
        : _getDefaultTheme();

    final service = ref.read(customThemeServiceProvider);
    final uniqueCode = await service.generateUniqueThemeCode('custom');

    customTheme = _copyTheme(baseTheme);
    customTheme = customTheme!.copyWith(
      code: uniqueCode,
      title: '我的主题 ${DateTime.now().month}-${DateTime.now().day}',
    );
    customThemeId = uniqueCode;
    isCreateMode = true;
    hasUnsavedChanges = true;
  }

  Future<void> _loadExistingTheme(String themeCode) async {
    final themes = await ref.read(customThemesProvider.future);
    final existingTheme = themes.firstWhere(
      (theme) => theme.code == themeCode,
      orElse: () => _getDefaultTheme(),
    );

    customTheme = _copyTheme(existingTheme);
    customThemeId = themeCode;
    isCreateMode = false;
  }

  Future<void> _loadDefaultTheme() async {
    final currentTheme = ref.read(selectedCustomThemeProvider);
    customTheme = _copyTheme(
      currentTheme.colorList.isNotEmpty ? currentTheme : _getDefaultTheme(),
    );
    isCreateMode = true;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    if (isInitializing || customTheme == null) {
      return Scaffold(
        backgroundColor: isDarkMode
            ? Colors.grey.shade900
            : Colors.grey.shade50,
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在初始化主题编辑器...'),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: _handleBackPress,
      child: ThemeAwareScaffold(
        pageType: PageType.settings,
        appBar: AppBar(
          title: Text(isCreateMode ? '创建主题' : '编辑主题'),
          backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
          foregroundColor: isDarkMode ? Colors.white : Colors.black,
          elevation: 0,
          actions: [
            if (hasUnsavedChanges)
              TextButton(
                onPressed: _saveTheme,
                child: const Text(
                  '保存',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              onPressed: _showOptionsMenu,
              icon: Icon(
                Platform.isIOS
                    ? CupertinoIcons.ellipsis_circle
                    : Icons.more_vert,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 主题基本信息
            _buildThemeBasicInfo(isDarkMode),

            const SizedBox(height: 16),

            // 图片设置
            _buildImageSettings(isDarkMode),

            const SizedBox(height: 16),

            // 颜色设置
            _buildColorSettings(isDarkMode),

            const SizedBox(height: 24),

            // 保存按钮
            _buildSaveButton(isDarkMode),

            const SizedBox(height: 16),

            // 主题预览
            _buildThemePreview(isDarkMode),
          ],
        ),
      ),
    );
  }

  // 主题基本信息
  Widget _buildThemeBasicInfo(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2A2A2A).withAlpha(217)
            : Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode
            ? Border.all(color: Colors.white.withAlpha(26), width: 1)
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
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  '主题信息',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 主题名称
            Text(
              '主题名称',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: customTheme?.title ?? '我的自定义主题',
              decoration: InputDecoration(
                hintText: '输入主题名称',
                hintStyle: TextStyle(
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
                filled: true,
                fillColor: isDarkMode
                    ? Colors.grey.shade700
                    : Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
              onChanged: (value) {
                if (customTheme != null) {
                  _updateTheme(title: value.isNotEmpty ? value : '我的自定义主题');
                }
              },
            ),

            const SizedBox(height: 16),

            // 主题代码
            Text(
              '主题代码',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                customTheme?.code ?? '',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 图片设置
  Widget _buildImageSettings(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2A2A2A).withAlpha(217)
            : Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode
            ? Border.all(color: Colors.white.withAlpha(26), width: 1)
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
            Row(
              children: [
                Icon(
                  Icons.image_outlined,
                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  '背景图片',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 主页背景图片
            _buildImagePicker(
              title: '主页背景图片',
              currentPath: customTheme?.indexBackgroundImg ?? '',
              onImagePicked: (path) => _updateTheme(indexBackgroundImg: path),
              isDarkMode: isDarkMode,
            ),

            // 主页相关模糊效果
            const SizedBox(height: 8),
            _buildBlurOption(
              title: '主页背景模糊',
              value: customTheme?.indexBackgroundBlur ?? false,
              onChanged: (value) => _updateTheme(indexBackgroundBlur: value),
              isDarkMode: isDarkMode,
            ),
            _buildBlurOption(
              title: '主页卡片模糊',
              value: customTheme?.indexMessageBoxBlur ?? false,
              onChanged: (value) => _updateTheme(indexMessageBoxBlur: value),
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 16),

            // 课表背景图片
            _buildImagePicker(
              title: '课表背景图片',
              currentPath: customTheme?.img ?? '',
              onImagePicked: (path) => _updateTheme(img: path),
              isDarkMode: isDarkMode,
            ),

            // 课表相关模糊效果
            const SizedBox(height: 8),
            _buildBlurOption(
              title: '课表背景模糊',
              value: customTheme?.classTableBackgroundBlur ?? false,
              onChanged: (value) =>
                  _updateTheme(classTableBackgroundBlur: value),
              isDarkMode: isDarkMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required String title,
    required String currentPath,
    required Function(String) onImagePicked,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade700
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  currentPath.isEmpty ? '未设置' : currentPath,
                  style: TextStyle(
                    color: currentPath.isEmpty
                        ? (isDarkMode ? Colors.white54 : Colors.black54)
                        : (isDarkMode ? Colors.white : Colors.black),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _pickImage(onImagePicked),
              icon: const Icon(Icons.photo_library, size: 16),
              label: const Text('选择'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 颜色设置
  Widget _buildColorSettings(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2A2A2A).withAlpha(217)
            : Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode
            ? Border.all(color: Colors.white.withAlpha(26), width: 1)
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
            Row(
              children: [
                Icon(
                  Icons.palette_outlined,
                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  '主题颜色',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 基础颜色
            _buildColorSelector(
              title: '背景颜色',
              color: customTheme?.backColor ?? Colors.blue,
              onColorChanged: (color) => _updateTheme(backColor: color),
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 16),

            _buildColorSelector(
              title: '前景颜色',
              color: customTheme?.foregColor ?? Colors.white,
              onColorChanged: (color) => _updateTheme(foregColor: color),
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 16),

            _buildColorSelector(
              title: '日期颜色',
              color: customTheme?.weekColor ?? Colors.grey,
              onColorChanged: (color) => _updateTheme(weekColor: color),
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 16),

            // 课表颜色列表
            Text(
              '课表颜色列表',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            _buildColorList(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildColorSelector({
    required String title,
    required Color color,
    required Function(Color) onColorChanged,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showColorPicker(color, onColorChanged),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDarkMode ? Colors.white24 : Colors.black12,
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'rgba(${color.red.toString()}, ${color.green.toString()}, ${color.blue.toString()}, ${(color.alpha / 255.0).toStringAsFixed(2)})',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit,
                  color: isDarkMode ? Colors.white54 : Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorList(bool isDarkMode) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: customTheme?.colorList.length ?? 0,
      itemBuilder: (context, index) {
        final color = customTheme!.colorList[index];
        return InkWell(
          onTap: () => _showColorPicker(color, (newColor) {
            final newList = List<Color>.from(customTheme!.colorList);
            newList[index] = newColor;
            _updateTheme(colorList: newList);
          }),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isDarkMode ? Colors.white24 : Colors.black12,
                      width: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 单个模糊效果选项
  Widget _buildBlurOption({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required bool isDarkMode,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: CheckboxListTile(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        value: value,
        onChanged: (newValue) => onChanged(newValue ?? false),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        tileColor: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // 保存按钮
  Widget _buildSaveButton(bool isDarkMode) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: hasUnsavedChanges ? _saveTheme : null,
        icon: const Icon(Icons.save, color: Colors.white),
        label: Text(
          hasUnsavedChanges ? '保存主题' : '没有更改',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: hasUnsavedChanges ? Colors.blue : Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // 主题预览
  Widget _buildThemePreview(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2A2A2A).withAlpha(217)
            : Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode
            ? Border.all(color: Colors.white.withAlpha(26), width: 1)
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
            Row(
              children: [
                Icon(
                  Icons.preview_outlined,
                  color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                ),
                const SizedBox(width: 8),
                Text(
                  '主题预览',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 简单的主题预览
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: customTheme?.backColor ?? Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  // 背景色块
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      width: 80,
                      height: 40,
                      decoration: BoxDecoration(
                        color: customTheme?.foregColor ?? Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '前景色',
                          style: TextStyle(
                            color: customTheme?.backColor ?? Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 日期色块
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      width: 60,
                      height: 24,
                      decoration: BoxDecoration(
                        color: customTheme?.weekColor ?? Colors.grey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Center(
                        child: Text(
                          '日期',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 颜色列表预览
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      children: [
                        ...customTheme?.colorList
                                .take(5)
                                .map(
                                  (color) => Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: Colors.white24,
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                )
                                .toList() ??
                            [],
                        if ((customTheme?.colorList.length ?? 0) > 5)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Text(
                                '...',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 工具方法
  void _updateTheme({
    String? title,
    String? img,
    String? indexBackgroundImg,
    bool? indexBackgroundBlur,
    bool? indexMessageBoxBlur,
    bool? classTableBackgroundBlur,
    Color? backColor,
    Color? foregColor,
    Color? weekColor,
    List<Color>? colorList,
  }) {
    if (customTheme == null) return;

    setState(() {
      customTheme = customTheme!.copyWith(
        title: title ?? customTheme!.title,
        img: img,
        indexBackgroundImg: indexBackgroundImg,
        indexBackgroundBlur: indexBackgroundBlur,
        indexMessageBoxBlur: indexMessageBoxBlur,
        classTableBackgroundBlur: classTableBackgroundBlur,
        backColor: backColor,
        foregColor: foregColor,
        weekColor: weekColor,
        colorList: colorList,
      );
      hasUnsavedChanges = true;
    });
  }

  void _showColorPicker(Color currentColor, Function(Color) onColorChanged) {
    Color selectedColor = currentColor;
    final TextEditingController hexController = TextEditingController();
    final TextEditingController rController = TextEditingController();
    final TextEditingController gController = TextEditingController();
    final TextEditingController bController = TextEditingController();
    final TextEditingController aController = TextEditingController();

    void updateControllersFromColor(
      Color color, {
      bool updateHex = true,
      bool updateRGBA = true,
    }) {
      if (updateHex) {
        hexController.text = color
            .toARGB32()
            .toRadixString(16)
            .padLeft(8, '0')
            .toUpperCase();
      }
      if (updateRGBA) {
        rController.text = color.red.toString();
        gController.text = color.green.toString();
        bController.text = color.blue.toString();
        aController.text = (color.alpha / 255.0).toStringAsFixed(2);
      }
    }

    void updateColorFromHex(String hex) {
      try {
        String cleanHex = hex.replaceAll('#', '');
        if (cleanHex.length == 6) {
          cleanHex = 'FF$cleanHex'; // 添加alpha通道
        }
        if (cleanHex.length == 8) {
          final int value = int.parse(cleanHex, radix: 16);
          selectedColor = Color(value);
          updateControllersFromColor(selectedColor, updateHex: false);
        }
      } catch (e) {
        // 忽略无效的hex值
      }
    }

    void updateColorFromRGBA() {
      try {
        final int r = int.parse(rController.text).clamp(0, 255);
        final int g = int.parse(gController.text).clamp(0, 255);
        final int b = int.parse(bController.text).clamp(0, 255);
        final double a = double.parse(aController.text).clamp(0.0, 1.0);
        final int alpha = (a * 255).round();

        selectedColor = Color.fromARGB(alpha, r, g, b);
        updateControllersFromColor(selectedColor, updateRGBA: false);
      } catch (e) {
        // 忽略无效的RGBA值
      }
    }

    updateControllersFromColor(currentColor);

    final isDarkMode = ref.read(effectiveIsDarkModeProvider);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Platform.isIOS
              ? null
              : (isDarkMode ? const Color(0xFF202125) : Colors.white),
          shape: Platform.isIOS
              ? null
              : RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(
            '选择颜色',
            style: Platform.isIOS
                ? null
                : TextStyle(
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 颜色轮
                  ColorPicker(
                    color: selectedColor,
                    onColorChanged: (color) {
                      setState(() {
                        selectedColor = color;
                        updateControllersFromColor(color);
                      });
                    },
                    pickersEnabled: const <ColorPickerType, bool>{
                      ColorPickerType.primary: false,
                      ColorPickerType.accent: false,
                      ColorPickerType.wheel: true,
                    },
                    enableShadesSelection: false,
                    enableTonalPalette: false,
                    enableOpacity: true,
                  ),

                  const SizedBox(height: 20),

                  // 颜色预览
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: selectedColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Hex 输入
                  TextField(
                    controller: hexController,
                    decoration: const InputDecoration(
                      labelText: 'Hex颜色值',
                      prefixText: '#',
                      border: OutlineInputBorder(),
                      hintText: 'AARRGGBB 或 RRGGBB',
                    ),
                    onChanged: (value) {
                      updateColorFromHex(value);
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 16),

                  // RGBA 输入
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: rController,
                          decoration: const InputDecoration(
                            labelText: 'R',
                            border: OutlineInputBorder(),
                            hintText: '0-255',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            updateColorFromRGBA();
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: gController,
                          decoration: const InputDecoration(
                            labelText: 'G',
                            border: OutlineInputBorder(),
                            hintText: '0-255',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            updateColorFromRGBA();
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: bController,
                          decoration: const InputDecoration(
                            labelText: 'B',
                            border: OutlineInputBorder(),
                            hintText: '0-255',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            updateColorFromRGBA();
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: aController,
                          decoration: const InputDecoration(
                            labelText: 'A',
                            border: OutlineInputBorder(),
                            hintText: '0.0-1.0',
                          ),
                          keyboardType: TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (value) {
                            updateColorFromRGBA();
                            setState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: Platform.isIOS
              ? null
              : const EdgeInsets.fromLTRB(8, 0, 8, 8),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: Platform.isIOS
                  ? null
                  : TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
              child: Text(
                '取消',
                style: Platform.isIOS
                    ? null
                    : TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
              ),
            ),
            TextButton(
              onPressed: () {
                onColorChanged(selectedColor);
                Navigator.of(context).pop();
              },
              style: Platform.isIOS
                  ? null
                  : TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
              child: Text(
                '确定',
                style: Platform.isIOS
                    ? null
                    : TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(Function(String) onImagePicked) async {
    // 使用新的权限管理器
    final permissionChecker = ref.read(permissionCheckerProvider);
    final imagePath = await permissionChecker.pickImageWithPermission(
      context,
      ImageSource.gallery,
    );

    if (imagePath != null) {
      // 检查图片大小
      final file = File(imagePath);
      final fileSize = await file.length();
      final fileSizeMB = fileSize / (1000 * 1000);

      AppLogger.debug('📊 选择的图片大小: ${fileSizeMB.toStringAsFixed(2)} MB');

      var shouldUseImage = true;

      // 如果图片超过 5MB，提示用户
      if (fileSizeMB > 5) {
        if (!mounted) {
          shouldUseImage = false;
        } else {
          shouldUseImage = await ThemeAwareDialog.showConfirmDialog(
            context,
            title: '图片体积较大',
            message:
                '图片体积为 ${fileSizeMB.toStringAsFixed(1)} MB，超过 5 MB。\n'
                '较大的图片可能导致上传失败或处理缓慢，确定仍然使用吗？',
            negativeText: '取消',
            positiveText: '仍然使用',
          );

          if (!shouldUseImage) {
            ToastService.show(
              '请选择小于 5MB 的图片，以确保上传成功',
              backgroundColor: Colors.orange,
            );
          }
        }
      }

      if (shouldUseImage) {
        onImagePicked(imagePath);
        if (mounted) {
          setState(() {
            hasUnsavedChanges = true;
          });
        }
      }
    }
  }

  void _saveTheme() async {
    if (customTheme == null) return;

    try {
      final manager = ref.read(customThemeManagerProvider.notifier);
      await manager.saveTheme(customTheme!);

      // 自动应用保存的主题
      await ref
          .read(selectedThemeCodeProvider.notifier)
          .setThemeCode(customTheme!.code);

      setState(() {
        hasUnsavedChanges = false;
        isCreateMode = false;
      });

      ToastService.show('主题保存成功', backgroundColor: Colors.green);
    } catch (e) {
      await ThemeAwareDialog.showAlertDialog(
        context,
        title: '保存失败',
        message: e.toString(),
        buttonText: '确定',
      );
    }
  }

  /// 显示平台适配的选项菜单
  void _showOptionsMenu() {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _saveTheme();
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.floppy_disk,
                    color: CupertinoColors.activeBlue,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '保存主题',
                    style: TextStyle(
                      color: CupertinoColors.activeBlue,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _resetTheme();
              },
              isDestructiveAction: true,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.refresh,
                    color: CupertinoColors.destructiveRed,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '重置更改',
                    style: TextStyle(
                      color: CupertinoColors.destructiveRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              '取消',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.save, color: Colors.blue),
                title: const Text(
                  '保存主题',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _saveTheme();
                },
              ),
              ListTile(
                leading: const Icon(Icons.refresh, color: Colors.red),
                title: const Text(
                  '重置更改',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.red,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _resetTheme();
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    '取消',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _resetTheme() async {
    final result = await ThemeAwareDialog.showConfirmDialog(
      context,
      title: '重置更改',
      message: '确定要放弃所有未保存的更改吗？',
      positiveText: '重置',
      negativeText: '取消',
    );

    if (result) {
      _initializeTheme();
    }
  }

  Future<bool> _handleBackPress() async {
    if (!hasUnsavedChanges) {
      return true;
    }

    final result = await ThemeAwareDialog.showConfirmDialog(
      context,
      title: '未保存的更改',
      message: '您有未保存的更改，确定要离开吗？',
      positiveText: '离开',
      negativeText: '取消',
    );

    return result;
  }

  theme_model.Theme _getDefaultTheme() {
    // 你好西大人主题的标准配置（与themes.json保持一致）
    final standardHelloTheme = theme_model.Theme(
      code: 'classic-theme-1',
      title: '你好西大人',
      img:
          'https://data.swu.social/service/external_files/2301371392301561862291631292311861844564564.webp',
      indexBackgroundBlur: false,
      indexBackgroundImg:
          'https://www.yumus.cn/api/?target=img&brand=bing&ua=m',
      indexMessageBoxBlur: true,
      backColor: Color.fromRGBO(35, 88, 168, 1), // 确保使用正确的RGB值
      foregColor: Color.fromRGBO(255, 255, 255, 1),
      weekColor: Color.fromRGBO(221, 221, 221, 1),
      classTableBackgroundBlur: false,
      colorList: [
        Color(0xFF2255a3),
        Color(0xFF2358a8),
        Color(0xFF275baa),
        Color(0xFF2c5fab),
        Color(0xFF3767b0),
        Color(0xFF3969b1),
        Color(0xFF3d6cb2),
        Color(0xFF426fb4),
        Color(0xFF4673b6),
        Color(0xFF4a76b7),
      ],
    );

    // 如果是创建模式，生成一个基于标准主题的新自定义主题
    if (isCreateMode) {
      return standardHelloTheme.copyWith(
        code: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        title: '我的主题 ${DateTime.now().month}-${DateTime.now().day}',
      );
    }

    // 预设主题模板
    return standardHelloTheme;
  }

  theme_model.Theme _copyTheme(theme_model.Theme original) {
    return theme_model.Theme(
      code: original.code,
      title: original.title.isEmpty ? '我的自定义主题' : original.title,
      img: original.img,
      indexBackgroundBlur: original.indexBackgroundBlur,
      indexBackgroundImg: original.indexBackgroundImg,
      indexMessageBoxBlur: original.indexMessageBoxBlur,
      backColor: original.backColor,
      foregColor: original.foregColor,
      weekColor: original.weekColor,
      classTableBackgroundBlur: original.classTableBackgroundBlur,
      colorList: List<Color>.from(original.colorList),
    );
  }
}
