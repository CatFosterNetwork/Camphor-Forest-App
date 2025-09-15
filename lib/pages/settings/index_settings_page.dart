// lib/pages/settings/index_settings_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/theme_aware_scaffold.dart';
import '../../core/config/providers/new_core_providers.dart'
    hide effectiveIsDarkModeProvider;
import '../../core/config/providers/theme_config_provider.dart';

// 创建配置项provider
final schoolNavigationConfigProvider = Provider<bool>((ref) {
  final appConfigAsync = ref.watch(appConfigNotifierProvider);
  return appConfigAsync.when(
    data: (appConfig) => appConfig.showSchoolNavigation,
    loading: () => true, // 默认true
    error: (_, __) => true, // 错误时默认true
  );
});

final bbsConfigProvider = Provider<bool>((ref) {
  final appConfigAsync = ref.watch(appConfigNotifierProvider);
  return appConfigAsync.when(
    data: (appConfig) => appConfig.showBBS,
    loading: () => true, // 默认true
    error: (_, __) => true, // 错误时默认true
  );
});

final lifeServiceConfigProvider = Provider<bool>((ref) {
  final appConfigAsync = ref.watch(appConfigNotifierProvider);
  return appConfigAsync.when(
    data: (appConfig) => appConfig.showLifeService,
    loading: () => true, // 默认true
    error: (_, __) => true, // 错误时默认true
  );
});

final feedbackConfigProvider = Provider<bool>((ref) {
  final appConfigAsync = ref.watch(appConfigNotifierProvider);
  return appConfigAsync.when(
    data: (appConfig) => appConfig.showFeedback,
    loading: () => true, // 默认true
    error: (_, __) => true, // 错误时默认true
  );
});

// 快捷卡片配置项provider
final showTodoConfigProvider = Provider<bool>((ref) {
  final appConfigAsync = ref.watch(appConfigNotifierProvider);
  return appConfigAsync.when(
    data: (appConfig) => appConfig.showTodo,
    loading: () => true, // 默认true
    error: (_, __) => true, // 错误时默认true
  );
});

final showFinishedTodoConfigProvider = Provider<bool>((ref) {
  final appConfigAsync = ref.watch(appConfigNotifierProvider);
  return appConfigAsync.when(
    data: (appConfig) => appConfig.showFinishedTodo,
    loading: () => true, // 默认true
    error: (_, __) => true, // 错误时默认true
  );
});

final showExamsConfigProvider = Provider<bool>((ref) {
  final appConfigAsync = ref.watch(appConfigNotifierProvider);
  return appConfigAsync.when(
    data: (appConfig) => appConfig.showExams,
    loading: () => true, // 默认true
    error: (_, __) => true, // 错误时默认true
  );
});

final showExpenseConfigProvider = Provider<bool>((ref) {
  final appConfigAsync = ref.watch(appConfigNotifierProvider);
  return appConfigAsync.when(
    data: (appConfig) => appConfig.showExpense,
    loading: () => true, // 默认true
    error: (_, __) => true, // 错误时默认true
  );
});

final showGradesConfigProvider = Provider<bool>((ref) {
  final appConfigAsync = ref.watch(appConfigNotifierProvider);
  return appConfigAsync.when(
    data: (appConfig) => appConfig.showGrades,
    loading: () => true, // 默认true
    error: (_, __) => true, // 错误时默认true
  );
});

class IndexSettingsPage extends ConsumerWidget {
  const IndexSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);

    // 获取主题色，如果没有主题则使用默认蓝色
    final themeColor = currentTheme.colorList.isNotEmpty == true
        ? currentTheme.colorList[0]
        : Colors.blue;
    final activeColor = isDarkMode ? themeColor.withAlpha(204) : themeColor;

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: false, // 设置页面使用纯色背景，保持专业感
      appBar: ThemeAwareAppBar(title: '主页设置'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 森林功能设置
          Container(
            margin: const EdgeInsets.only(bottom: 16),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '森林功能',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '开启后将在主页显示森林功能区域',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 四个森林功能的单独开关
                  Consumer(
                    builder: (context, ref, child) {
                      final isSchoolNavigationEnabled = ref.watch(
                        schoolNavigationConfigProvider,
                      );
                      return SwitchListTile(
                        title: Text(
                          '显示爱上校车',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '校车信息查看',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        value: isSchoolNavigationEnabled,
                        onChanged: (value) async {
                          await ref
                              .read(appConfigNotifierProvider.notifier)
                              .updateConfigItem(
                                'forest-showSchoolNavigation',
                                value,
                              );
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: activeColor,
                      );
                    },
                  ),

                  Consumer(
                    builder: (context, ref, child) {
                      final isBBSEnabled = ref.watch(bbsConfigProvider);
                      return SwitchListTile(
                        title: Text(
                          '显示情绪树洞',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          'BBS论坛功能',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        value: isBBSEnabled,
                        onChanged: (value) async {
                          await ref
                              .read(appConfigNotifierProvider.notifier)
                              .updateConfigItem('forest-showBBS', value);
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: activeColor,
                      );
                    },
                  ),

                  Consumer(
                    builder: (context, ref, child) {
                      final isLifeServiceEnabled = ref.watch(
                        lifeServiceConfigProvider,
                      );
                      return SwitchListTile(
                        title: Text(
                          '显示校园生活',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '生活服务功能集合',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        value: isLifeServiceEnabled,
                        onChanged: (value) async {
                          await ref
                              .read(appConfigNotifierProvider.notifier)
                              .updateConfigItem(
                                'forest-showLifeService',
                                value,
                              );
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: activeColor,
                      );
                    },
                  ),

                  Consumer(
                    builder: (context, ref, child) {
                      final isFeedbackEnabled = ref.watch(
                        feedbackConfigProvider,
                      );
                      return SwitchListTile(
                        title: Text(
                          '显示反馈改进',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '用户反馈功能',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        value: isFeedbackEnabled,
                        onChanged: (value) async {
                          await ref
                              .read(appConfigNotifierProvider.notifier)
                              .updateConfigItem('forest-showFeedback', value);
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: activeColor,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // 快捷卡片设置
          Container(
            margin: const EdgeInsets.only(bottom: 16),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '快捷卡片',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '选择在主页显示的快捷功能卡片',
                    style: TextStyle(
                      fontSize: 15,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Consumer(
                    builder: (context, ref, child) {
                      final showTodo = ref.watch(showTodoConfigProvider);
                      return SwitchListTile(
                        title: Text(
                          '显示待办',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '在主页显示待办事项',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        value: showTodo,
                        onChanged: (value) async {
                          await ref
                              .read(appConfigNotifierProvider.notifier)
                              .updateConfigItem('index-showTodo', value);
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: activeColor,
                      );
                    },
                  ),

                  Consumer(
                    builder: (context, ref, child) {
                      final showFinishedTodo = ref.watch(
                        showFinishedTodoConfigProvider,
                      );
                      return SwitchListTile(
                        title: Text(
                          '显示已完成待办',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '开启后将显示已完成的待办事项',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        value: showFinishedTodo,
                        onChanged: (value) async {
                          await ref
                              .read(appConfigNotifierProvider.notifier)
                              .updateConfigItem(
                                'index-showFinishedTodo',
                                value,
                              );
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: activeColor,
                      );
                    },
                  ),

                  Consumer(
                    builder: (context, ref, child) {
                      final showExams = ref.watch(showExamsConfigProvider);
                      return SwitchListTile(
                        title: Text(
                          '显示考试列表',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '在主页显示即将到来的考试',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        value: showExams,
                        onChanged: (value) async {
                          await ref
                              .read(appConfigNotifierProvider.notifier)
                              .updateConfigItem('index-showExams', value);
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: activeColor,
                      );
                    },
                  ),

                  Consumer(
                    builder: (context, ref, child) {
                      final showExpense = ref.watch(showExpenseConfigProvider);
                      return SwitchListTile(
                        title: Text(
                          '显示水电余额',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '显示宿舍水电费余额信息',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        value: showExpense,
                        onChanged: (value) async {
                          await ref
                              .read(appConfigNotifierProvider.notifier)
                              .updateConfigItem('index-showExpense', value);
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: activeColor,
                      );
                    },
                  ),

                  Consumer(
                    builder: (context, ref, child) {
                      final showGrades = ref.watch(showGradesConfigProvider);
                      return SwitchListTile(
                        title: Text(
                          '显示成绩',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : Colors.black,
                          ),
                        ),
                        subtitle: Text(
                          '在主页显示最新成绩信息',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        value: showGrades,
                        onChanged: (value) async {
                          await ref
                              .read(appConfigNotifierProvider.notifier)
                              .updateConfigItem('index-showGrades', value);
                        },
                        contentPadding: EdgeInsets.zero,
                        activeColor: activeColor,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
