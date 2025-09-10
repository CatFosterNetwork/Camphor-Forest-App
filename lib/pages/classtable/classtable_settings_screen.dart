import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/providers/theme_config_provider.dart';
import '../../widgets/app_background.dart';
import 'providers/classtable_settings_provider.dart';
import 'models/custom_course_model.dart';
import 'widgets/add_custom_course_dialog.dart';
import 'widgets/history_classtable_selector.dart';

/// 课程表设置页面
class ClassTableSettingsScreen extends ConsumerStatefulWidget {
  const ClassTableSettingsScreen({super.key});

  @override
  ConsumerState<ClassTableSettingsScreen> createState() =>
      _ClassTableSettingsScreenState();
}

class _ClassTableSettingsScreenState
    extends ConsumerState<ClassTableSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final settings = ref.watch(classTableSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 背景
          const AppBackground(blur: false),

          // 主要内容
          CustomScrollView(
            slivers: [
              // AppBar
              _buildAppBar(isDarkMode, theme),

              // 内容
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // 当前学期显示
                    _buildCurrentSemesterCard(settings, isDarkMode, theme),

                    const SizedBox(height: 16),

                    // 添加课程按钮
                    _buildAddCourseButton(isDarkMode, theme),

                    const SizedBox(height: 24),

                    // 自定义课程列表
                    _buildCustomCoursesSection(settings, isDarkMode, theme),

                    const SizedBox(height: 24),

                    // 历史课表按钮
                    _buildHistoryClassTableButton(isDarkMode, theme),

                    // 底部安全区域
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建 AppBar
  Widget _buildAppBar(bool isDarkMode, ThemeData theme) {
    return SliverAppBar(
      title: Text(
        '课程表设置',
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      floating: true,
      snap: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: Icon(
            Icons.refresh,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'refresh_all',
              child: Row(
                children: [
                  Icon(Icons.refresh),
                  SizedBox(width: 8),
                  Text('刷新所有数据'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'refresh_history',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text('刷新历史课表'),
                ],
              ),
            ),
          ],
          onSelected: (value) async {
            switch (value) {
              case 'refresh_all':
                await ref.read(classTableSettingsProvider.notifier).refresh();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已刷新所有数据'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                break;
              case 'refresh_history':
                await ref
                    .read(classTableSettingsProvider.notifier)
                    .refreshHistoryFromGrades();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('已从成绩数据刷新历史课表'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
                break;
            }
          },
        ),
      ],
    );
  }

  /// 构建当前学期卡片
  Widget _buildCurrentSemesterCard(
    ClassTableSettingsState settings,
    bool isDarkMode,
    ThemeData theme,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.7)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: theme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '当前学期',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  settings.currentSemesterDisplayName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showHistoryClassTableSelector(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '切换',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 16,
                    color: theme.primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建添加课程按钮
  Widget _buildAddCourseButton(bool isDarkMode, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => _showAddCourseDialog(),
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, size: 20),
            SizedBox(width: 8),
            Text(
              '添加课程',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建自定义课程列表部分
  Widget _buildCustomCoursesSection(
    ClassTableSettingsState settings,
    bool isDarkMode,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '自定义课程列表',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),

        if (settings.customCourses.isEmpty)
          _buildEmptyCoursesCard(isDarkMode)
        else
          ...settings.customCourses.map(
            (course) => _buildCustomCourseCard(course, isDarkMode, theme),
          ),
      ],
    );
  }

  /// 构建空课程卡片
  Widget _buildEmptyCoursesCard(bool isDarkMode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.5)
            : Colors.grey.shade100.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
          style: BorderStyle.solid,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.school_outlined,
            size: 48,
            color: isDarkMode ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 12),
          Text(
            '还没有自定义课程',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '点击上方按钮添加您的第一门课程',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建自定义课程卡片
  Widget _buildCustomCourseCard(
    CustomCourse course,
    bool isDarkMode,
    ThemeData theme,
  ) {
    final colorList = ref.watch(currentThemeProvider).colorList;
    final courseColor = colorList[course.hashCode % colorList.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.7)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: courseColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _editCourse(course),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 课程标题和周次
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: courseColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.weeksDescription,
                        style: TextStyle(
                          fontSize: 12,
                          color: courseColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 时间和地点信息
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${course.weekdayDescription} ${course.timeDescription}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),

                if (course.classroom != null || course.teacher != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (course.classroom != null) ...[
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: isDarkMode ? Colors.white54 : Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.classroom!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        if (course.teacher != null) ...[
                          const SizedBox(width: 16),
                          Icon(
                            Icons.person,
                            size: 16,
                            color: isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            course.teacher!,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        ],
                      ] else if (course.teacher != null) ...[
                        Icon(
                          Icons.person,
                          size: 16,
                          color: isDarkMode ? Colors.white54 : Colors.black54,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          course.teacher!,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建历史课表按钮
  Widget _buildHistoryClassTableButton(bool isDarkMode, ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: () => _showHistoryClassTableSelector(),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.primaryColor,
          side: BorderSide(color: theme.primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 20),
            SizedBox(width: 8),
            Text(
              '历史课表',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示添加课程对话框
  void _showAddCourseDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddCustomCourseDialog(),
    );
  }

  /// 编辑课程
  void _editCourse(CustomCourse course) {
    showDialog(
      context: context,
      builder: (context) => AddCustomCourseDialog(course: course),
    );
  }

  /// 显示历史课表选择器
  void _showHistoryClassTableSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const HistoryClassTableSelector(),
    );
  }
}
