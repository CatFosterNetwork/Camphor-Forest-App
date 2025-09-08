import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/providers/theme_config_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';
import 'providers/classtable_settings_provider.dart';
import 'models/custom_course_model.dart';
import 'widgets/add_custom_course_dialog.dart';

/// 自定义课表页面
class CustomClassTableScreen extends ConsumerStatefulWidget {
  const CustomClassTableScreen({super.key});

  @override
  ConsumerState<CustomClassTableScreen> createState() =>
      _CustomClassTableScreenState();
}

class _CustomClassTableScreenState
    extends ConsumerState<CustomClassTableScreen> {
  // 当前选择的学期
  String _selectedXnm = '';
  String _selectedXqm = '';

  @override
  void initState() {
    super.initState();
    // 初始化为当前学期
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    _selectedXnm = currentMonth < 7
        ? (currentYear - 1).toString()
        : currentYear.toString();
    _selectedXqm = currentMonth < 7 ? '12' : '3';
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final settings = ref.watch(classTableSettingsProvider);
    final theme = Theme.of(context);

    return ThemeAwareScaffold(
      useBackground: true,
      pageType: PageType.settings,
      appBar: AppBar(
        title: Text(_formatSemesterTitle()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _showSemesterSelector,
            tooltip: '选择学期',
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 统计信息
          SliverToBoxAdapter(
            child: _buildStatsCard(settings, isDarkMode, theme),
          ),

          // 自定义课程列表
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _buildCustomCoursesList(settings, isDarkMode, theme),
          ),

          // 底部添加按钮
          SliverToBoxAdapter(child: _buildAddButton(isDarkMode, theme)),

          // 底部安全区域
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ),
        ],
      ),
    );
  }

  /// 构建统计信息卡片
  Widget _buildStatsCard(
    ClassTableSettingsState settings,
    bool isDarkMode,
    ThemeData theme,
  ) {
    // 过滤当前学期的课程
    final currentSemesterCourses = settings.customCourses
        .where(
          (course) => course.xnm == _selectedXnm && course.xqm == _selectedXqm,
        )
        .toList();
    final coursesCount = currentSemesterCourses.length;
    final weeklyHours = _calculateWeeklyHours(currentSemesterCourses);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: theme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                '统计信息',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '自定义课程',
                  '$coursesCount 门',
                  Icons.class_,
                  theme,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  '每周课时',
                  '$weeklyHours 节',
                  Icons.schedule,
                  theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 构建统计项
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建自定义课程列表
  Widget _buildCustomCoursesList(
    ClassTableSettingsState settings,
    bool isDarkMode,
    ThemeData theme,
  ) {
    // 过滤当前学期的课程
    final currentSemesterCourses = settings.customCourses
        .where(
          (course) => course.xnm == _selectedXnm && course.xqm == _selectedXqm,
        )
        .toList();

    if (currentSemesterCourses.isEmpty) {
      return SliverToBoxAdapter(child: _buildEmptyState(theme));
    }

    // 按星期分组
    final groupedCourses = _groupCoursesByWeekday(currentSemesterCourses);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final weekday = index + 1;
        final courses = groupedCourses[weekday] ?? [];

        if (courses.isEmpty) return const SizedBox.shrink();

        return _buildWeekdaySection(weekday, courses, theme);
      }, childCount: 7),
    );
  }

  /// 构建星期分组
  Widget _buildWeekdaySection(
    int weekday,
    List<CustomCourse> courses,
    ThemeData theme,
  ) {
    const weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            weekdays[weekday],
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...courses.map((course) => _buildCourseCard(course, theme)),
        const SizedBox(height: 8),
      ],
    );
  }

  /// 构建课程卡片
  Widget _buildCourseCard(CustomCourse course, ThemeData theme) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];

    final color = colors[course.hashCode % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _editCourse(course),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (course.teacher != null)
                            Text(
                              course.teacher!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.7,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _editCourse(course);
                        } else if (value == 'delete') {
                          _deleteCourse(course);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('编辑'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18),
                              SizedBox(width: 8),
                              Text('删除'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.schedule,
                      course.timeDescription,
                      theme,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.calendar_today,
                      course.weeksDescription,
                      theme,
                    ),
                  ],
                ),
                if (course.classroom != null) ...[
                  const SizedBox(height: 8),
                  _buildInfoChip(Icons.location_on, course.classroom!, theme),
                ],
                if (course.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    course.description!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 构建信息标签
  Widget _buildInfoChip(IconData icon, String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            '还没有自定义课程',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击下方按钮添加您的第一门自定义课程',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 构建添加按钮
  Widget _buildAddButton(bool isDarkMode, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: FilledButton.icon(
        onPressed: _addCourse,
        icon: const Icon(Icons.add),
        label: const Text('添加自定义课程'),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// 计算每周总课时
  int _calculateWeeklyHours(List<CustomCourse> courses) {
    int totalHours = 0;
    for (final course in courses) {
      final hours = course.endTime - course.startTime + 1;
      totalHours += hours;
    }
    return totalHours;
  }

  /// 按星期分组课程
  Map<int, List<CustomCourse>> _groupCoursesByWeekday(
    List<CustomCourse> courses,
  ) {
    final grouped = <int, List<CustomCourse>>{};

    for (final course in courses) {
      grouped.putIfAbsent(course.weekday, () => []).add(course);
    }

    // 对每个星期的课程按时间排序
    for (final courses in grouped.values) {
      courses.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return grouped;
  }

  /// 添加课程
  void _addCourse() {
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

  /// 删除课程
  void _deleteCourse(CustomCourse course) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除课程"${course.title}"吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref
                  .read(classTableSettingsProvider.notifier)
                  .deleteCustomCourse(course.id);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('已删除课程"${course.title}"')));
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 格式化学期标题
  String _formatSemesterTitle() {
    final year = int.tryParse(_selectedXnm) ?? DateTime.now().year;
    if (_selectedXqm == '3') {
      return '${year}年秋季自定义课表';
    } else if (_selectedXqm == '12') {
      return '${year + 1}年春季自定义课表';
    } else {
      return '$_selectedXnm-$_selectedXqm自定义课表';
    }
  }

  /// 显示学期选择器
  void _showSemesterSelector() {
    final settings = ref.read(classTableSettingsProvider);

    // 从历史课表和当前学期生成学期列表
    final availableSemesters = <String, String>{};

    // 添加当前学期
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    final currentXnm = currentMonth < 7
        ? (currentYear - 1).toString()
        : currentYear.toString();
    final currentXqm = currentMonth < 7 ? '12' : '3';
    final currentYear2 = int.tryParse(currentXnm) ?? currentYear;
    final currentDisplayName = currentXqm == '3'
        ? '${currentYear2}年秋季学期'
        : '${currentYear2 + 1}年春季学期';
    availableSemesters['$currentXnm-$currentXqm'] = currentDisplayName;

    // 添加有历史课表的学期
    for (final history in settings.historyClassTables) {
      final key = '${history.xnm}-${history.xqm}';
      availableSemesters[key] = history.displayName;
    }

    // 从自定义课程中添加学期
    for (final course in settings.customCourses) {
      final key = '${course.xnm}-${course.xqm}';
      if (!availableSemesters.containsKey(key)) {
        final year = int.tryParse(course.xnm) ?? currentYear;
        final displayName = course.xqm == '3'
            ? '${year}年秋季学期'
            : '${year + 1}年春季学期';
        availableSemesters[key] = displayName;
      }
    }

    final sortedSemesters = availableSemesters.entries.toList()
      ..sort((a, b) {
        final aParts = a.key.split('-');
        final bParts = b.key.split('-');
        final aYear = int.tryParse(aParts[0]) ?? 0;
        final bYear = int.tryParse(bParts[0]) ?? 0;

        if (aYear != bYear) {
          return bYear.compareTo(aYear); // 年份降序
        }
        return aParts[1].compareTo(bParts[1]); // 学期升序
      });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择学期'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sortedSemesters.length,
            itemBuilder: (context, index) {
              final entry = sortedSemesters[index];
              final key = entry.key;
              final displayName = entry.value;
              final parts = key.split('-');
              final xnm = parts[0];
              final xqm = parts[1];
              final isSelected = xnm == _selectedXnm && xqm == _selectedXqm;

              return ListTile(
                title: Text(displayName),
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? Theme.of(context).primaryColor : null,
                ),
                onTap: () {
                  setState(() {
                    _selectedXnm = xnm;
                    _selectedXqm = xqm;
                  });
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
        ],
      ),
    );
  }
}
