import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/providers/theme_config_provider.dart';

import 'providers/classtable_providers.dart';

import '../../core/widgets/theme_aware_scaffold.dart';
import 'widgets/class_table_chart.dart';
import 'widgets/week_selector_tabs.dart';
import 'widgets/course_detail_modal.dart';
import 'widgets/history_classtable_selector.dart';
import 'providers/classtable_settings_provider.dart';
import 'constants/semester.dart';
import 'models/course.dart';
import '../../core/models/theme_model.dart' as custom_theme_model;
import '../../core/services/widget_service.dart';
import 'package:go_router/go_router.dart';

class ClassTableScreen extends ConsumerStatefulWidget {
  const ClassTableScreen({super.key});

  @override
  ConsumerState<ClassTableScreen> createState() => _ClassTableScreenState();
}

class _ClassTableScreenState extends ConsumerState<ClassTableScreen>
    with SingleTickerProviderStateMixin {
  // 学年学期参数 - 使用稳定的值，避免不必要的重建
  late String _currentXnm;
  late String _currentXqm;
  bool _isInitialized = false;
  bool _hasAutoCalculatedWeek = false;

  int _currentWeek = 1;
  final bool _isLoading = false;
  bool _isRefreshing = false;
  bool _isRefreshSuccess = false;

  // 添加动画控制器
  late AnimationController _refreshAnimController;
  late Animation<double> _refreshScaleAnimation;
  late Animation<double> _refreshRotateAnimation;

  @override
  void initState() {
    super.initState();

    // 初始化学年学期参数
    final now = DateTime.now();
    _currentXnm = now.year.toString();
    _currentXqm = now.month < 7 ? '12' : '3';

    // 计算当前周次将在build方法中根据当前学期动态计算
    _currentWeek = 1; // 默认值

    // 初始化刷新动画
    _refreshAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // 弹性缩放动画
    _refreshScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.8,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.8,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.bounceOut)),
        weight: 40,
      ),
    ]).animate(_refreshAnimController);

    // 旋转动画
    _refreshRotateAnimation =
        Tween<double>(
          begin: 0.0,
          end: 2 * 3.1415926, // 360度
        ).animate(
          CurvedAnimation(
            parent: _refreshAnimController,
            curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
          ),
        );

    // 课表数据现在由classTableProvider自动管理
  }

  @override
  void dispose() {
    _refreshAnimController.dispose();
    super.dispose();
  }

  // 显示课程详情对话框
  void _showCourseDetail(
    BuildContext context,
    Course course,
    bool isDark,
    Rect courseRect,
    List<Course> allCourses,
  ) {
    final currentTheme = ref.read(selectedCustomThemeProvider);

    // 使用与课表图表相同的颜色计算逻辑
    final courseColor = _getCourseColorFromChart(
      course,
      allCourses,
      currentTheme,
      isDark,
    );

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false, // 设置为透明
        pageBuilder: (context, animation, secondaryAnimation) {
          return CourseDetailModal(
            course: course,
            isDarkMode: isDark,
            courseColor: courseColor,
            sourceRect: courseRect,
            animation: animation,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return child;
        },
      ),
    );
  }

  // 使用与课表图表完全相同的颜色计算逻辑
  Color _getCourseColorFromChart(
    Course course,
    List<Course> allCourses,
    custom_theme_model.Theme? customTheme,
    bool isDark,
  ) {
    final scheme = Theme.of(context).colorScheme;

    // 深色模式下使用统一的深色背景
    if (isDark) {
      return const Color(0xFF202125);
    }

    // 浅色模式下使用自定义主题的颜色列表
    final List<Color> baseColors;
    if (customTheme?.colorList.isNotEmpty == true) {
      baseColors = customTheme!.colorList;
    } else {
      baseColors = [
        scheme.primary,
        scheme.secondary,
        scheme.tertiary,
        Colors.purple,
        Colors.teal,
        Colors.amber.shade800,
        Colors.indigo,
        Colors.pink,
        Colors.green,
        Colors.deepOrange,
      ];
    }

    // 使用课程ID的字符码和来选择颜色，与课表图表逻辑完全一致
    final colorIndex =
        course.id.codeUnits.fold(0, (sum, code) => sum + code) %
        baseColors.length;
    return baseColors[colorIndex];
  }

  // 切换周次
  void _changeWeek(int week) {
    setState(() {
      _currentWeek = week;
      debugPrint('🗓️ 切换到第$_currentWeek周 (学期: $_currentXnm-$_currentXqm)');
    });
  }

  // 格式化AppBar标题：当前学期显示日期，历史学期显示学期名称
  String _formatAppBarTitle() {
    // 判断是否为当前学期
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // 计算当前学期
    final currentXnm = currentMonth < 7
        ? (currentYear - 1).toString()
        : currentYear.toString();
    final currentXqm = currentMonth < 7 ? '12' : '3';

    // 如果是当前学期，显示当前日期
    if (_currentXnm == currentXnm && _currentXqm == currentXqm) {
      return DateTime.now().toString().split(' ')[0];
    }

    // 如果是历史学期，只显示学期名称
    final year = int.tryParse(_currentXnm) ?? DateTime.now().year;
    if (_currentXqm == '3') {
      return '$year年秋季学期';
    } else if (_currentXqm == '12') {
      return '${year + 1}年春季学期';
    } else {
      return '$_currentXnm-$_currentXqm学期';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 使用现有的主题系统
    final currentTheme = ref.watch(selectedCustomThemeProvider);
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    // 初始化时读取设置
    if (!_isInitialized) {
      final settings = ref.read(classTableSettingsProvider);
      // 直接更新，不用setState，避免触发监听器
      _currentXnm = settings.currentXnm;
      _currentXqm = settings.currentXqm;
      _isInitialized = true;
      debugPrint('📅 初始化学期: ${settings.currentXnm}-${settings.currentXqm}');
    }

    // 监听学期变化
    ref.listen<ClassTableSettingsState>(classTableSettingsProvider, (
      previous,
      next,
    ) {
      if (previous != null &&
          (next.currentXnm != _currentXnm || next.currentXqm != _currentXqm)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _currentXnm = next.currentXnm;
              _currentXqm = next.currentXqm;
              _currentWeek = 1; // 重置周次
              _hasAutoCalculatedWeek = false; // 允许新学期重新计算周次
            });
            debugPrint('📅 学期切换: ${next.currentXnm}-${next.currentXqm}，周次重置为1');
          }
        });
      }
    });

    final tableAsync = ref.watch(
      classTableProvider((xnm: _currentXnm, xqm: _currentXqm)),
    );

    // 根据当前学期动态计算周次
    final semesterStart = SemesterConfig.getSemesterStart(
      _currentXnm,
      _currentXqm,
    );

    // 判断是否为当前学期
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final currentXnm = currentMonth < 7
        ? (currentYear - 1).toString()
        : currentYear.toString();
    final currentXqm = currentMonth < 7 ? '12' : '3';
    final isCurrentSemester =
        _currentXnm == currentXnm && _currentXqm == currentXqm;

    // 只有当前学期才基于日期计算周次，历史学期使用固定的第1周
    if (isCurrentSemester) {
      final diffDays = now.difference(semesterStart).inDays;
      final calculatedWeek = (diffDays ~/ 7) + 1;

      // 只在真正的首次初始化时根据日期设置周次，避免覆盖用户手动选择
      if (_currentWeek == 1 && calculatedWeek > 0 && !_hasAutoCalculatedWeek) {
        _hasAutoCalculatedWeek = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            _currentWeek = calculatedWeek.clamp(1, 30);
            debugPrint('🕰️ 根据日期自动设置为第$_currentWeek周（当前学期，首次初始化）');
          });
        });
      }
    } else {
      // 历史学期：如果是刚切换过来的（周次为1且未自动计算过），保持第1周
      debugPrint('📅 历史学期 $_currentXnm-$_currentXqm，保持第$_currentWeek周');
    }

    if (_isLoading && !_isRefreshing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return tableAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('加载失败 $e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // 使用强制刷新确保从远程获取数据
                  ref.invalidate(
                    forceRefreshClassTableProvider((
                      xnm: _currentXnm,
                      xqm: _currentXqm,
                    )),
                  );

                  // 刷新普通provider
                  ref.invalidate(
                    classTableProvider((xnm: _currentXnm, xqm: _currentXqm)),
                  );
                },
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      ),
      data: (table) {
        debugPrint('成功加载课表数据');

        // 当前周的课表数据
        final weekSchedule = table.getWeekSchedule(_currentWeek);

        // 提取所有课程，用于计算最大周次
        final allCourses = table
            .getAllCourses()
            .values
            .expand((e) => e)
            .toList();
        debugPrint('总课程数量: ${allCourses.length}');

        int maxWeek = 1;

        // 如果有课程，计算最大周次
        if (allCourses.isNotEmpty) {
          // 遍历所有课程找出最大周次
          for (final course in allCourses) {
            if (course.weeks.isNotEmpty) {
              final courseMaxWeek = course.weeks.reduce(
                (a, b) => a > b ? a : b,
              );
              if (courseMaxWeek > maxWeek) {
                maxWeek = courseMaxWeek;
              }
            }
          }
        } else {
          maxWeek = 20; // 如果没有课程，默认设置为20周
        }
        maxWeek = maxWeek > 20 ? maxWeek : 20;
        debugPrint('计算得到最大周次: $maxWeek');

        // 只有当前周超出范围时才调整
        if (_currentWeek > maxWeek) {
          debugPrint('⚠️ 当前周 $_currentWeek 超出最大周次 $maxWeek，调整为: $maxWeek');
          _currentWeek = maxWeek;
        } else if (_currentWeek < 1) {
          debugPrint('⚠️ 当前周 $_currentWeek 小于1，调整为: 1');
          _currentWeek = 1;
        }

        // 获取当前周次的所有课程
        final List<Course> courses;
        if (weekSchedule != null) {
          // 从当前周的课表中提取所有课程
          courses = weekSchedule.values.expand((list) => list).toList();
          debugPrint('当前第$_currentWeek周的课程数量: ${courses.length}');
        } else {
          courses = [];
          debugPrint('当前第$_currentWeek周没有课程');
        }

        // 更新小组件数据（仅在当前学期时更新）
        if (isCurrentSemester && courses.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            WidgetService.updateClassTableWidget(
              courses: courses,
              currentWeek: _currentWeek,
              semesterStart: semesterStart,
            );
          });
        }

        return Stack(
          children: [
            ThemeAwareScaffold(
              useBackground: true,
              pageType: PageType.classtable,
              extendBodyBehindAppBar: true, // 让背景在AppBar下显示
              appBar: ThemeAwareAppBar(
                title: _formatAppBarTitle(),
                transparent: true,
                foregroundColor: const Color(0xFFBFC2C9),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.calendar_month),
                    onPressed: () =>
                        _showWeekSelector(context, maxWeek, currentTheme),
                    tooltip: '选择周次',
                    color: isDarkMode
                        ? const Color(0xFFBFC2C9)
                        : (currentTheme.foregColor),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
              body: Stack(
                children: [
                  Column(
                    children: [
                      // 添加周数选择器
                      WeekSelectorTabs(
                        currentWeek: _currentWeek,
                        maxWeek: maxWeek,
                        onWeekChanged: _changeWeek,
                        customTheme: currentTheme,
                        darkMode: isDarkMode,
                      ),

                      // 课表内容
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent, // 确保空白区域也能接收手势
                          onHorizontalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;

                            if (velocity.abs() < 200) return;
                            if (velocity < 0 && _currentWeek < maxWeek) {
                              // 向左滑，下一周
                              _changeWeek(_currentWeek + 1);
                            } else if (velocity > 0 && _currentWeek > 1) {
                              // 向右滑，上一周
                              _changeWeek(_currentWeek - 1);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: ClassTableChart(
                              courses: courses,
                              darkMode: isDarkMode,
                              currentWeek: _currentWeek,
                              semesterStart: SemesterConfig.getSemesterStart(
                                _currentXnm,
                                _currentXqm,
                              ),
                              customTheme: currentTheme,
                              onCourseTap: (course, courseRect) =>
                                  _showCourseDetail(
                                    context,
                                    course,
                                    isDarkMode,
                                    courseRect,
                                    courses,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // 悬浮按钮组，添加动画效果
                  Positioned(
                    bottom: 32,
                    right: 32,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 设置按钮
                        FloatingActionButton(
                          heroTag: "settings",
                          onPressed: () {
                            debugPrint('🔧 设置按钮被点击，显示操作菜单');
                            _showActionMenu(context);
                          },
                          backgroundColor:
                              (currentTheme.colorList.isNotEmpty == true
                                      ? currentTheme.colorList.first
                                      : Colors.blue)
                                  .withAlpha(153),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // 刷新按钮
                        AnimatedBuilder(
                          animation: _refreshAnimController,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _isRefreshing
                                  ? _refreshScaleAnimation.value
                                  : 1.0,
                              child: TweenAnimationBuilder<double>(
                                tween: Tween<double>(begin: 1.0, end: 1.0),
                                duration: const Duration(milliseconds: 200),
                                builder: (context, scale, child) {
                                  return Transform.scale(
                                    scale: scale,
                                    child: child,
                                  );
                                },
                                child: FloatingActionButton(
                                  heroTag: "refresh",
                                  onPressed: () async {
                                    if (_isRefreshing || _isRefreshSuccess)
                                      return;

                                    setState(() {
                                      _isRefreshing = true;
                                      _isRefreshSuccess =
                                          false; // Ensure checkmark is hidden
                                    });
                                    _refreshAnimController
                                        .forward(); // Start animation visually

                                    try {
                                      // Await the provider that fetches from remote. This solves the race condition.
                                      final _ = await ref.refresh(
                                        forceRefreshClassTableProvider((
                                          xnm: _currentXnm,
                                          xqm: _currentXqm,
                                        )).future,
                                      );

                                      // Now that the cache is updated, invalidate the UI provider.
                                      ref.invalidate(
                                        classTableProvider((
                                          xnm: _currentXnm,
                                          xqm: _currentXqm,
                                        )),
                                      );

                                      // Update state to show success
                                      if (mounted) {
                                        HapticFeedback.mediumImpact();
                                        setState(() {
                                          _isRefreshSuccess = true;
                                        });

                                        // After 2 seconds, hide the checkmark
                                        Future.delayed(
                                          const Duration(seconds: 2),
                                          () {
                                            if (mounted) {
                                              setState(
                                                () => _isRefreshSuccess = false,
                                              );
                                            }
                                          },
                                        );
                                      }
                                    } catch (e) {
                                      debugPrint('课表刷新失败: $e');
                                      // Optionally show an error snackbar or change icon to an error icon
                                    } finally {
                                      // This block runs whether refresh succeeded or failed
                                      if (mounted) {
                                        // Stop the animation and reset the refreshing state
                                        _refreshAnimController.reset();
                                        setState(() {
                                          _isRefreshing = false;
                                        });
                                      }
                                    }
                                  },
                                  backgroundColor:
                                      (currentTheme.colorList.isNotEmpty == true
                                              ? currentTheme.colorList.first
                                              : Colors.blue)
                                          .withAlpha(204),
                                  child: _isRefreshSuccess
                                      ? const Icon(
                                          Icons.check,
                                          color: Colors.white,
                                        )
                                      : Transform.rotate(
                                          angle: _isRefreshing
                                              ? _refreshRotateAnimation.value
                                              : 0.0,
                                          child: const Icon(
                                            Icons.refresh,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // 显示周次选择器
  void _showWeekSelector(
    BuildContext context,
    int maxWeek,
    custom_theme_model.Theme? currentTheme,
  ) {
    final isDarkMode = ref.read(effectiveIsDarkModeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              '选择周次',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                ),
                itemCount: maxWeek,
                itemBuilder: (context, index) {
                  final week = index + 1;
                  final isSelected = week == _currentWeek;

                  // 获取选中状态的颜色
                  final selectedColor =
                      currentTheme?.colorList.isNotEmpty == true
                      ? currentTheme!.colorList.first
                      : Theme.of(context).primaryColor;

                  // 根据深色模式设置未选中状态的颜色
                  final unselectedBackgroundColor = isDarkMode
                      ? Colors.grey.shade800
                      : Colors.grey.shade200;
                  final unselectedTextColor = isDarkMode
                      ? Colors.white70
                      : Colors.black87;

                  return InkWell(
                    onTap: () {
                      setState(() => _currentWeek = week);
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? selectedColor
                            : unselectedBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$week',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? _getTextColorForBackground(selectedColor)
                                : unselectedTextColor,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 根据背景颜色获取合适的文本颜色
  Color _getTextColorForBackground(Color backgroundColor) {
    final brightness = backgroundColor.computeLuminance();
    return brightness > 0.5 ? Colors.black87 : Colors.white;
  }

  /// 显示操作菜单（使用Material的ModalBottomSheet）
  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildMaterialActionSheet(context),
    );
  }

  /// 构建Material风格的ActionSheet
  Widget _buildMaterialActionSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = ref.read(effectiveIsDarkModeProvider);

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade900
            : Colors.white, // 使用与其他modal一致的颜色
        borderRadius: BorderRadius.circular(16),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖拽指示器
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.white38
                    : Colors.black26, // 使用与其他modal一致的颜色
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '课表设置',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black, // 明确设置文字颜色
                ),
              ),
            ),

            const Divider(height: 1),

            // 菜单选项
            _buildMaterialOption(
              context,
              icon: Icons.history_rounded,
              title: '历史课表',
              subtitle: '查看和切换到以前的学期',
              onTap: () {
                Navigator.pop(context);
                _showHistoryDialog(context);
              },
            ),

            _buildMaterialOption(
              context,
              icon: Icons.edit_calendar_rounded,
              title: '自定义课表',
              subtitle: '添加和编辑自定义课程',
              onTap: () {
                Navigator.pop(context);
                context.push('/classTable/customize');
              },
            ),

            const SizedBox(height: 8),

            // 取消按钮
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? Colors.white.withOpacity(0.2) // 深色模式下使用半透明白色
                      : theme.colorScheme.secondary,
                  foregroundColor: isDarkMode
                      ? Colors
                            .white // 深色模式下使用纯白色文字
                      : theme.colorScheme.onSecondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('取消'),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 构建Material风格的选项
  Widget _buildMaterialOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDarkMode = ref.read(effectiveIsDarkModeProvider);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.1) // 深色模式下使用半透明白色
              : theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDarkMode
              ? Colors
                    .white // 深色模式下使用纯白色
              : theme.colorScheme.onPrimaryContainer,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.white : null, // 深色模式下明确设置文字颜色
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: isDarkMode
              ? Colors.white.withOpacity(0.7) // 深色模式下使用半透明白色
              : theme.colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDarkMode
            ? Colors.white.withOpacity(0.5) // 深色模式下使用半透明白色
            : theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  /// 显示历史课表选择对话框
  void _showHistoryDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HistoryClassTableSelector(),
    );
  }
}
