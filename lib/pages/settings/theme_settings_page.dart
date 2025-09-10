// lib/pages/settings/theme_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/providers/theme_config_provider.dart';

import '../../core/models/theme_model.dart' as theme_model;
import '../../core/constants/route_constants.dart';
import '../../core/widgets/theme_aware_scaffold.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeConfigAsync = ref.watch(themeConfigNotifierProvider);
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final selectedThemeCode = ref.watch(selectedThemeCodeProvider);
    final customThemesAsync = ref.watch(customThemesProvider);

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: false, // 主题设置使用纯色背景，便于查看主题效果
      forceStatusBarIconBrightness: isDarkMode
          ? Brightness.light
          : Brightness.dark, // 强制状态栏图标适配
      appBar: ThemeAwareAppBar(title: '主题设置'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 深色/浅色模式切换
          Container(
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
                  Text(
                    '外观模式',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  themeConfigAsync.when(
                    data: (config) => Column(
                      children: [
                        _buildThemeModeOption(
                          ref,
                          ThemeMode.system,
                          '跟随系统',
                          Icons.settings_brightness,
                          config.themeMode,
                          isDarkMode,
                        ),
                        _buildThemeModeOption(
                          ref,
                          ThemeMode.light,
                          '浅色模式',
                          Icons.light_mode,
                          config.themeMode,
                          isDarkMode,
                        ),
                        _buildThemeModeOption(
                          ref,
                          ThemeMode.dark,
                          '深色模式',
                          Icons.dark_mode,
                          config.themeMode,
                          isDarkMode,
                        ),
                      ],
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (_, _) => const Text('加载主题模式失败'),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 预设主题选择
          _buildPresetThemeSection(
            ref,
            customThemesAsync,
            selectedThemeCode,
            isDarkMode,
            context,
          ),

          const SizedBox(height: 16),

          // 自定义主题管理
          _buildCustomThemeSection(
            ref,
            customThemesAsync,
            selectedThemeCode,
            isDarkMode,
            context,
          ),

          const SizedBox(height: 24),

          // 预览区域
          Container(
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
                  Text(
                    '主题预览',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPreviewArea(ref, isDarkMode),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeOption(
    WidgetRef ref,
    ThemeMode mode,
    String title,
    IconData icon,
    String currentThemeMode,
    bool isDarkMode,
  ) {
    final isSelected = currentThemeMode == mode.name;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isSelected
            ? (isDarkMode ? Colors.blue.shade300 : Colors.blue)
            : (isDarkMode ? Colors.white70 : Colors.black54),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: isDarkMode ? Colors.blue.shade300 : Colors.blue,
            )
          : null,
      onTap: () => ref
          .read(themeConfigNotifierProvider.notifier)
          .setThemeMode(mode.name),
    );
  }

  Widget _buildPreviewArea(WidgetRef ref, bool isDarkMode) {
    final customTheme = ref.watch(selectedCustomThemeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDarkMode ? Colors.white12 : Colors.black12),
      ),
      child: Column(
        children: [
          // 主题模式指示器
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  themeMode == 'light'
                      ? Icons.light_mode
                      : themeMode == 'dark'
                      ? Icons.dark_mode
                      : Icons.settings_brightness,
                  size: 16,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
                const SizedBox(width: 8),
                Text(
                  themeMode == 'light'
                      ? '浅色模式'
                      : themeMode == 'dark'
                      ? '深色模式'
                      : themeMode == 'system'
                      ? '跟随系统'
                      : '自动',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const Spacer(),
                Text(
                  customTheme.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // 预览内容
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    customTheme.backColor,
                    customTheme.backColor.withAlpha(204),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 模拟主页卡片
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(230),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(26),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: customTheme.colorList.first,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '今日课程',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: customTheme.foregColor,
                                    ),
                                  ),
                                  Text(
                                    '高等数学 | 8:00-9:40',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: customTheme.foregColor.withAlpha(
                                        178,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // 颜色色块展示
                    Row(
                      children: [
                        Text(
                          '课表颜色:',
                          style: TextStyle(
                            fontSize: 11,
                            color: customTheme.foregColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ...customTheme.colorList
                            .take(6)
                            .map(
                              (color) => Container(
                                width: 16,
                                height: 16,
                                margin: const EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: Colors.white.withAlpha(76),
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // 时间和日期颜色展示
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: customTheme.foregColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '时间色',
                            style: TextStyle(
                              fontSize: 9,
                              color: customTheme.foregColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: customTheme.weekColor.withAlpha(26),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '日期色',
                            style: TextStyle(
                              fontSize: 9,
                              color: customTheme.weekColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 预设主题选择区域
  Widget _buildPresetThemeSection(
    WidgetRef ref,
    AsyncValue<List<theme_model.Theme>> customThemesAsync,
    String selectedThemeCode,
    bool isDarkMode,
    BuildContext context,
  ) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '🎨 预设主题',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                customThemesAsync.when(
                  loading: () => const SizedBox(),
                  error: (_, _) => const SizedBox(),
                  data: (themes) {
                    final presetThemes = themes
                        .where((theme) => !theme.code.startsWith('custom'))
                        .toList();
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withAlpha(26),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${presetThemes.length} 个主题',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '经过精心设计的主题，直接使用无需修改',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            customThemesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                '加载主题失败: $error',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              data: (themes) {
                final presetThemes = themes
                    .where((theme) => !theme.code.startsWith('custom'))
                    .toList();
                return Column(
                  children: presetThemes
                      .map(
                        (theme) => _buildThemeSelectionTile(
                          theme,
                          selectedThemeCode == theme.code,
                          isDarkMode,
                          () => _selectTheme(ref, theme),
                          showDelete: false,
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 自定义主题管理区域
  Widget _buildCustomThemeSection(
    WidgetRef ref,
    AsyncValue<List<theme_model.Theme>> customThemesAsync,
    String selectedThemeCode,
    bool isDarkMode,
    BuildContext context,
  ) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '✨ 我的主题',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Row(
                  children: [
                    customThemesAsync.when(
                      loading: () => const SizedBox(),
                      error: (_, _) => const SizedBox(),
                      data: (themes) {
                        final customThemes = themes
                            .where((theme) => theme.code.startsWith('custom'))
                            .toList();
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(26),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${customThemes.length} 个主题',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => _createNewTheme(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('创建'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            customThemesAsync.when(
              loading: () => const SizedBox(),
              error: (_, _) => const SizedBox(),
              data: (themes) {
                final customThemes = themes
                    .where((theme) => theme.code.startsWith('custom'))
                    .toList();
                return Text(
                  customThemes.isEmpty
                      ? '您还没有创建任何自定义主题'
                      : '您创建的个性化主题，可以自由编辑和删除',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            customThemesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text(
                '加载主题失败: $error',
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              data: (themes) {
                final customThemes = themes
                    .where((theme) => theme.code.startsWith('custom'))
                    .toList();

                if (customThemes.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey.shade600
                            : Colors.grey.shade300,
                        style: BorderStyle.solid,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 48,
                          color: isDarkMode
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '还没有自定义主题',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDarkMode
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '点击右上角"创建"按钮开始设计您的专属主题',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode
                                ? Colors.grey.shade500
                                : Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: customThemes
                      .map(
                        (theme) => _buildThemeSelectionTile(
                          theme,
                          selectedThemeCode == theme.code,
                          isDarkMode,
                          () => _selectTheme(ref, theme),
                          showDelete: true,
                          onDelete: () => _deleteTheme(ref, theme, context),
                          onEdit: () => _editTheme(context, theme),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // 主题选择瓦片
  Widget _buildThemeSelectionTile(
    theme_model.Theme theme,
    bool isSelected,
    bool isDarkMode,
    VoidCallback onTap, {
    bool showDelete = false,
    VoidCallback? onDelete,
    VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50)
            : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(12),
        border: isDarkMode
            ? Border.all(color: Colors.white.withAlpha(26), width: 1)
            : null,
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withAlpha(38),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.grey.withAlpha(19),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 1),
                ),
              ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // 主要信息行
              Row(
                children: [
                  // 主题预览 - 渐变色块
                  Container(
                    width: 50,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.white24 : Colors.black12,
                        width: 1,
                      ),
                      gradient: LinearGradient(
                        colors: theme.colorList.isNotEmpty
                            ? theme.colorList
                            : [theme.backColor, theme.foregColor],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // 主题名称和标签
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                theme.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.code.startsWith('custom')
                                    ? Colors.orange.withAlpha(51)
                                    : Colors.green.withAlpha(51),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                theme.code.startsWith('custom') ? '自定义' : '预设',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.code.startsWith('custom')
                                      ? Colors.orange.shade700
                                      : Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // 操作按钮
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showDelete && onEdit != null)
                        InkWell(
                          onTap: onEdit,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.edit_outlined,
                              color: Colors.blue.shade400,
                              size: 16,
                            ),
                          ),
                        ),
                      if (showDelete && onDelete != null)
                        InkWell(
                          onTap: onDelete,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.red.shade400,
                              size: 16,
                            ),
                          ),
                        ),
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.check_circle,
                            color: isDarkMode
                                ? Colors.blue.shade300
                                : Colors.blue,
                            size: 20,
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // 颜色列表行
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(width: 62), // 对齐主题预览块下方
                  Expanded(
                    child: Row(
                      children: [
                        ...theme.colorList
                            .take(8)
                            .map(
                              (color) => Container(
                                width: 14,
                                height: 14,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDarkMode
                                        ? Colors.white24
                                        : Colors.black12,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                            ),
                        if (theme.colorList.length > 8)
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.white24
                                  : Colors.black12,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '•••',
                                style: TextStyle(
                                  fontSize: 6,
                                  color: isDarkMode
                                      ? Colors.white60
                                      : Colors.black45,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 选择主题
  void _selectTheme(WidgetRef ref, theme_model.Theme theme) {
    ref.read(selectedThemeCodeProvider.notifier).setThemeCode(theme.code);
  }

  // 创建新主题
  void _createNewTheme(BuildContext context) {
    context.push(RouteConstants.optionsCustomThemeSettings, extra: 'create');
  }

  // 编辑主题
  void _editTheme(BuildContext context, theme_model.Theme theme) {
    context.push(RouteConstants.optionsCustomThemeSettings, extra: theme.code);
  }

  // 删除主题
  void _deleteTheme(
    WidgetRef ref,
    theme_model.Theme theme,
    BuildContext context,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除主题'),
        content: Text('确定要删除主题"${theme.title}"吗？\n此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        final manager = ref.read(customThemeManagerProvider.notifier);
        final success = await manager.deleteTheme(theme.code);

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('主题删除成功'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // 如果删除的是当前选中的主题，回到默认主题
          final selectedThemeCode = ref.read(selectedThemeCodeProvider);
          if (selectedThemeCode == theme.code) {
            await ref
                .read(selectedThemeCodeProvider.notifier)
                .setThemeCode('classic-theme-1'); // 回到你好西大人主题
          }
        } else {
          throw Exception('删除主题失败');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
