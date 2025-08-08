import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/providers/theme_config_provider.dart';

import 'providers/classtable_providers.dart';

import '../../core/widgets/theme_aware_scaffold.dart';
import 'widgets/class_table_chart.dart';
import 'widgets/week_selector_tabs.dart';
import 'widgets/course_detail_modal.dart';
import 'constants/semester.dart';
import 'models/course.dart';
import '../../core/models/theme_model.dart' as custom_theme_model;

class ClassTableScreen extends ConsumerStatefulWidget {
  const ClassTableScreen({super.key});

  @override
  ConsumerState<ClassTableScreen> createState() => _ClassTableScreenState();
}

class _ClassTableScreenState extends ConsumerState<ClassTableScreen>
    with SingleTickerProviderStateMixin {
  // 学年学期参数可用 queryParam 传递；此处简单写死
  static const String xnm = '2024';
  static const String xqm = '12';

  int _currentWeek = 1;
  bool _isLoading = false;
  bool _isRefreshing = false;

  // 添加动画控制器
  late AnimationController _refreshAnimController;
  late Animation<double> _refreshScaleAnimation;
  late Animation<double> _refreshRotateAnimation;

  @override
  
  void initState() {
    super.initState();
    // 计算当前周次
    final diffDays = DateTime.now().difference(SemesterConfig.start).inDays;
    _currentWeek = (diffDays ~/ 7) + 1;
    if (_currentWeek < 1) _currentWeek = 1;

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

    // 延迟初始化数据，确保状态正确更新
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _refreshAnimController.dispose();
    super.dispose();
  }

  // 加载或刷新数据
  Future<void> _loadData() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _isRefreshing = true;
    });

    // 启动刷新动画
    _refreshAnimController.reset();
    _refreshAnimController.forward();

    try {
      // 强制刷新课表数据
      await ref.read(classTableRepositoryProvider).fetchRemote(xnm, xqm);
      if (mounted) {
        ref.invalidate(classTableProvider((xnm: xnm, xqm: xqm)));
      }
    } catch (e) {
      debugPrint('加载课表数据失败: $e');
      // 如果远程加载失败，尝试从本地加载
      if (mounted) {
        ref.invalidate(classTableProvider((xnm: xnm, xqm: xqm)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;

          // 延迟关闭旋转动画，确保动画完成
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _isRefreshing = false;
              });
            }
          });
        });
      }
    }
  }

  // 显示课程详情对话框
  void _showCourseDetail(BuildContext context, Course course, bool isDark, Rect courseRect, List<Course> allCourses) {
    final currentTheme = ref.read(selectedCustomThemeProvider);
    
    // 使用与课表图表相同的颜色计算逻辑
    final courseColor = _getCourseColorFromChart(course, allCourses, currentTheme, isDark);
    
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
  Color _getCourseColorFromChart(Course course, List<Course> allCourses, custom_theme_model.Theme? customTheme, bool isDark) {
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
    final colorIndex = course.id.codeUnits.fold(0, (sum, code) => sum + code) % baseColors.length;
    return baseColors[colorIndex];
  }



  // 切换周次
  void _changeWeek(int week) {
    setState(() {
      _currentWeek = week;
      debugPrint('切换到第$_currentWeek周');
    });
  }



  @override
  Widget build(BuildContext context) {
    // 使用现有的主题系统
    final currentTheme = ref.watch(selectedCustomThemeProvider);
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final tableAsync = ref.watch(classTableProvider((xnm: xnm, xqm: xqm)));

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
              ElevatedButton(onPressed: _loadData, child: const Text('重试')),
            ],
          ),
        ),
      ),
      data: (table) {
        debugPrint('成功加载课表数据');

        // 当前周的课表数据
        final weekSchedule = table.getWeekSchedule(_currentWeek);
        
        // 提取所有课程，用于计算最大周次
        final allCourses = table.getAllCourses().values.expand((e) => e).toList();
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

        // 确保 _currentWeek 在范围内
        _currentWeek = _currentWeek.clamp(1, maxWeek);

        // 课表背景现在由ThemeAwareScaffold自动管理

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

        return ThemeAwareScaffold(
          useBackground: true,
          pageType: PageType.classtable,
          extendBodyBehindAppBar: true, // 让背景在AppBar下显示
          appBar: ThemeAwareAppBar(
            title: '2025/7/7',
            transparent: true,
            actions: [
              AnimatedBuilder(
                animation: _refreshAnimController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isRefreshing ? _refreshScaleAnimation.value : 1.0,
                    child: Transform.rotate(
                      angle: _isRefreshing
                          ? _refreshRotateAnimation.value
                          : 0.0,
                      child: IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadData,
                        tooltip: '刷新课表',
                        color: isDarkMode 
                    ? const Color(0xFFBFC2C9)
                    : (currentTheme?.foregColor ?? Colors.black),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_month),
                onPressed: () => _showWeekSelector(context, maxWeek, currentTheme),
                tooltip: '选择周次',
                color: isDarkMode 
                    ? const Color(0xFFBFC2C9)
                    : (currentTheme?.foregColor ?? Colors.black),
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
                            semesterStart: SemesterConfig.start,
                            customTheme: currentTheme,
                            onCourseTap: (course, courseRect) =>
                                _showCourseDetail(context, course, isDarkMode, courseRect, courses),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              

              // 悬浮按钮，添加动画效果
              Positioned(
                bottom: 32,
                right: 32,
                child: AnimatedBuilder(
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
                          return Transform.scale(scale: scale, child: child);
                        },
                        child: FloatingActionButton(
                          onPressed: () {
                            // 添加按下动画
                            setState(() {
                              _loadData();
                            });
                          },
                          backgroundColor: (currentTheme?.colorList.isNotEmpty == true 
                              ? currentTheme!.colorList.first 
                              : Colors.blue).withAlpha(204),
                          child: Transform.rotate(
                            angle: _isRefreshing
                                ? _refreshRotateAnimation.value
                                : 0.0,
                            child: const Icon(Icons.refresh),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }



  // 显示周次选择器
  void _showWeekSelector(BuildContext context, int maxWeek, custom_theme_model.Theme? currentTheme) {
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
                  final selectedColor = currentTheme?.colorList.isNotEmpty == true 
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
                        color: isSelected ? selectedColor : unselectedBackgroundColor,
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
}
