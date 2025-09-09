// lib/pages/index/index_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/providers/new_core_providers.dart';
import '../../core/config/models/app_config.dart';
import '../../core/config/models/theme_config.dart';
import '../../core/constants/route_constants.dart';
import '../../core/providers/weather_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/grade_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';

import 'widgets/class_table_brief.dart';
import 'widgets/forest_hidden.dart';
import 'widgets/todo_brief.dart';
import 'widgets/expense_brief.dart';
import 'widgets/grade_brief.dart';
import 'widgets/weather_widget.dart';

/// 主页/首页
class IndexScreen extends ConsumerStatefulWidget {
  const IndexScreen({super.key});

  @override
  ConsumerState<IndexScreen> createState() => _IndexScreenState();
}

class _IndexScreenState extends ConsumerState<IndexScreen> {
  Timer? _weatherTimer;
  Timer? _gradesTimer;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 初始化数据拉取
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });

    // 定时轮询天气和成绩数据
    _weatherTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _fetchWeatherData();
    });
    _gradesTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _fetchGradeData();
    });
  }

  @override
  void dispose() {
    _weatherTimer?.cancel();
    _gradesTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// 初始化数据
  void _initializeData() {
    _fetchWeatherData();
    _fetchGradeData();
  }

  /// 获取天气数据
  void _fetchWeatherData() {
    ref.read(weatherProvider.notifier).fetchWeather();
  }

  /// 获取成绩数据
  void _fetchGradeData() {
    debugPrint('IndexScreen: 开始获取成绩数据');
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    if (isAuthenticated) {
      ref.read(gradeProvider.notifier).refreshGrades();
    } else {
      debugPrint('IndexScreen: 用户未登录，跳过获取成绩数据');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用新的配置系统
    final themeConfigAsync = ref.watch(themeConfigNotifierProvider);
    final appConfigAsync = ref.watch(appConfigNotifierProvider);
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider); // 使用响应式的深色模式状态

    return themeConfigAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('加载配置失败: $e'))),
      data: (themeConfig) {
        return appConfigAsync.when(
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (e, st) => Scaffold(body: Center(child: Text('加载应用配置失败: $e'))),
          data: (appConfig) =>
              _buildIndexScreen(themeConfig, appConfig, isDarkMode),
        );
      },
    );
  }

  Widget _buildIndexScreen(
    ThemeConfig themeConfig,
    AppConfig appConfig,
    bool isDarkMode,
  ) {
    // 使用响应式的当前主题
    final selectedTheme = ref.watch(selectedCustomThemeProvider);
    final boxBlur = selectedTheme.indexMessageBoxBlur;

    return ThemeAwareScaffold(
      useBackground: true,
      pageType: PageType.indexPage,
      body: Stack(
        children: [
          // 主要内容 - 使用优化的滑动控制
          RefreshIndicator(
            onRefresh: () async {
              _initializeData();
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              // 使用iOS风格的弹性回弹，避免StretchingOverscrollIndicator禁用BackdropFilter
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 顶部额外空间 - 确保滑动到顶部时背景仍有内容用于BackdropFilter
                    const SizedBox(height: 10),
                    // 简单的navbar - 不固定位置，直接放在最顶部
                    _buildSimpleNavbar(isDarkMode, boxBlur),

                    // 主要内容区域
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 课表简要组件
                          if (appConfig.showClassroom)
                            ClassTableBrief(
                              blur: boxBlur,
                              darkMode: isDarkMode,
                            ),

                          if (appConfig.showClassroom)
                            const SizedBox(height: 16),

                          // 森林隐藏功能组件
                          ForestHidden(blur: boxBlur, darkMode: isDarkMode),

                          const SizedBox(height: 16),

                          // 待办事项组件
                          if (appConfig.showTodo) ...[
                            TodoBrief(blur: boxBlur, darkMode: isDarkMode),
                          ],

                          if (appConfig.showTodo) const SizedBox(height: 16),

                          // 水电费组件 - 作为生活服务的一部分
                          if (appConfig.showExpense)
                            ExpenseBrief(blur: boxBlur, darkMode: isDarkMode),

                          if (appConfig.showExpense) const SizedBox(height: 16),

                          // 成绩组件 - 作为生活服务的一部分
                          if (appConfig.showGrades)
                            GradeBrief(blur: boxBlur, darkMode: isDarkMode),

                          if (appConfig.showGrades) const SizedBox(height: 16),
                        ],
                      ),
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

  /// 构建简单的navbar - 固定内容，无滚动效果
  Widget _buildSimpleNavbar(bool isDark, bool boxBlur) {
    // 确保在浅色模式下有足够的对比度
    final textColor = isDark ? Colors.white : Colors.black;
    final currentUser = ref.watch(authProvider).user;
    final userName = currentUser?.name ?? '用户';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(left: 20, right: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左边：天气信息
          WeatherWidget(blur: boxBlur, darkMode: isDark),

          const SizedBox(width: 20), // 和天气保持距离
          // 中间：欢迎信息
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, // 左对齐
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '欢迎',
                style: TextStyle(
                  color: textColor.withAlpha(204), // 0.8 * 255 = 204
                  fontSize: 12,
                ),
              ),
              Text(
                userName,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const Spacer(), // 推送设置按钮到右边
          // 右边：设置按钮
          IconButton(
            icon: Icon(Icons.settings_outlined, color: textColor, size: 20),
            onPressed: () {
              context.push(RouteConstants.options);
            },
            tooltip: '设置',
          ),
        ],
      ),
    );
  }
}
