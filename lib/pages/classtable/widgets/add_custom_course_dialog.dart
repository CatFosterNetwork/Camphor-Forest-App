import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camphor_forest/core/services/toast_service.dart';
import '../../../core/config/providers/theme_config_provider.dart';
import '../models/custom_course_model.dart';
import '../providers/classtable_settings_provider.dart';

/// 添加/编辑自定义课程对话框
class AddCustomCourseDialog extends ConsumerStatefulWidget {
  final CustomCourse? course; // 如果不为空则为编辑模式

  const AddCustomCourseDialog({super.key, this.course});

  @override
  ConsumerState<AddCustomCourseDialog> createState() =>
      _AddCustomCourseDialogState();
}

class _AddCustomCourseDialogState extends ConsumerState<AddCustomCourseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _teacherController = TextEditingController();
  final _classroomController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _selectedWeekday = 1; // 1-7 对应周一到周日
  int _startTime = 1; // 开始节次
  int _endTime = 1; // 结束节次
  Set<int> _selectedWeeks = {1}; // 选中的周次
  String _selectedCourseType = '自定义课程';

  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.course != null;

    if (_isEditMode) {
      final course = widget.course!;
      _titleController.text = course.title;
      _teacherController.text = course.teacher ?? '';
      _classroomController.text = course.classroom ?? '';
      _descriptionController.text = course.description ?? '';
      _selectedWeekday = course.weekday;
      _startTime = course.startTime;
      _endTime = course.endTime;
      _selectedWeeks = course.weeks.toSet();
      _selectedCourseType = course.courseType;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _teacherController.dispose();
    _classroomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final calculatedWidth = (screenWidth * 0.85).clamp(500.0, 800.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16), // 控制Dialog与屏幕边缘的距离
      child: SizedBox(
        width: calculatedWidth, // 使用clamp确保在500-800px范围内
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          margin: const EdgeInsets.all(0), // 移除margin，由insetPadding控制
          padding: const EdgeInsets.all(24), // 增加内边距
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _isEditMode ? '编辑课程' : '添加课程',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  if (_isEditMode)
                    IconButton(
                      onPressed: _showDeleteConfirmDialog,
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red.shade400,
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 表单内容
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 课程名称
                        _buildTextField(
                          controller: _titleController,
                          label: '课程名称 *',
                          hint: '请输入课程名称',
                          isDarkMode: isDarkMode,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入课程名称';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // 教师和教室
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _teacherController,
                                label: '教师',
                                hint: '请输入教师姓名',
                                isDarkMode: isDarkMode,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildTextField(
                                controller: _classroomController,
                                label: '教室',
                                hint: '请输入教室',
                                isDarkMode: isDarkMode,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // 课程类型选择
                        _buildCourseTypeSelector(isDarkMode, theme),

                        const SizedBox(height: 16),

                        // 星期选择
                        _buildWeekdaySelector(isDarkMode, theme),

                        const SizedBox(height: 16),

                        // 节次选择
                        _buildTimeSelector(isDarkMode, theme),

                        const SizedBox(height: 16),

                        // 周次选择
                        _buildWeeksSelector(isDarkMode, theme),

                        const SizedBox(height: 16),

                        // 课程描述
                        _buildTextField(
                          controller: _descriptionController,
                          label: '课程描述',
                          hint: '请输入课程描述（可选）',
                          isDarkMode: isDarkMode,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDarkMode
                            ? Colors.white
                            : Colors.black54,
                        side: BorderSide(
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.6)
                              : Colors.black26, // 深色模式下提高边框对比度
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveCourse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDarkMode
                            ? Colors.white
                            : theme.primaryColor, // 深色模式下使用白色背景
                        foregroundColor: isDarkMode
                            ? Colors.black
                            : Colors.white, // 深色模式下使用黑色文字
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDarkMode
                                      ? Colors.black
                                      : Colors.white, // 深色模式下使用黑色
                                ),
                              ),
                            )
                          : Text(_isEditMode ? '保存' : '添加'),
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

  /// 构建文本输入框
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDarkMode,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
            filled: true,
            fillColor: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).primaryColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  /// 构建星期选择器
  Widget _buildWeekdaySelector(bool isDarkMode, ThemeData theme) {
    const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '星期 *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: weekdays.asMap().entries.map((entry) {
            final index = entry.key + 1; // 1-7
            final weekday = entry.value;
            final isSelected = _selectedWeekday == index;

            return FilterChip(
              label: Text(weekday),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedWeekday = index;
                });
              },
              selectedColor: isDarkMode
                  ? Colors.white.withOpacity(0.2) // 深色模式下使用白色
                  : theme.primaryColor.withOpacity(0.2),
              checkmarkColor: isDarkMode
                  ? Colors
                        .white // 深色模式下使用纯白色
                  : theme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? (isDarkMode
                          ? Colors.white
                          : theme.primaryColor) // 深色模式下选中项使用白色
                    : (isDarkMode ? Colors.white70 : Colors.black54),
              ),
              backgroundColor: isDarkMode
                  ? Colors.grey.shade800.withOpacity(0.8) // 增加不透明度
                  : Colors.grey.shade100,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 构建时间选择器
  Widget _buildTimeSelector(bool isDarkMode, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '上课时间 *',
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
              child: _buildDropdown(
                value: _startTime,
                label: '开始节次',
                items: List.generate(14, (i) => i + 1),
                onChanged: (value) {
                  setState(() {
                    _startTime = value!;
                    if (_endTime < _startTime) {
                      _endTime = _startTime;
                    }
                  });
                },
                isDarkMode: isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown(
                value: _endTime,
                label: '结束节次',
                items: List.generate(
                  14,
                  (i) => i + 1,
                ).where((i) => i >= _startTime).toList(),
                onChanged: (value) {
                  setState(() {
                    _endTime = value!;
                  });
                },
                isDarkMode: isDarkMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建下拉框
  Widget _buildDropdown({
    required int value,
    required String label,
    required List<int> items,
    required void Function(int?) onChanged,
    required bool isDarkMode,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: value,
          onChanged: onChanged,
          style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
          dropdownColor: isDarkMode
              ? Colors.grey.shade900
              : Colors.white, // 深色模式下使用更深的颜色
          items: items.map((item) {
            return DropdownMenuItem<int>(value: item, child: Text('第$item节'));
          }).toList(),
        ),
      ],
    );
  }

  /// 构建周次选择器
  Widget _buildWeeksSelector(bool isDarkMode, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '上课周次 *',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedWeeks.length == 20) {
                    _selectedWeeks.clear();
                    _selectedWeeks.add(1);
                  } else {
                    _selectedWeeks = Set.from(List.generate(20, (i) => i + 1));
                  }
                });
              },
              child: Text(
                _selectedWeeks.length == 20 ? '取消全选' : '全选',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode
                      ? Colors.white
                      : theme.primaryColor, // 深色模式下使用白色
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(20, (i) {
            final week = i + 1;
            final isSelected = _selectedWeeks.contains(week);

            return FilterChip(
              label: Text('$week'),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedWeeks.add(week);
                  } else {
                    _selectedWeeks.remove(week);
                    // 至少保留一周
                    if (_selectedWeeks.isEmpty) {
                      _selectedWeeks.add(week);
                    }
                  }
                });
              },
              selectedColor: isDarkMode
                  ? Colors.white.withOpacity(0.2) // 深色模式下使用白色
                  : theme.primaryColor.withOpacity(0.2),
              checkmarkColor: isDarkMode
                  ? Colors
                        .white // 深色模式下使用纯白色
                  : theme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? (isDarkMode
                          ? Colors.white
                          : theme.primaryColor) // 深色模式下选中项使用白色
                    : (isDarkMode ? Colors.white70 : Colors.black54),
                fontSize: 12,
              ),
              backgroundColor: isDarkMode
                  ? Colors.grey.shade800.withOpacity(0.8) // 增加不透明度
                  : Colors.grey.shade100,
            );
          }),
        ),
      ],
    );
  }

  /// 保存课程
  Future<void> _saveCourse() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedWeeks.isEmpty) {
      ToastService.show('请至少选择一个上课周次');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final now = DateTime.now();
      final settings = ref.read(classTableSettingsProvider);

      final course = CustomCourse(
        id: _isEditMode
            ? widget.course!.id
            : 'custom_${now.millisecondsSinceEpoch}',
        title: _titleController.text.trim(),
        teacher: _teacherController.text.trim().isEmpty
            ? null
            : _teacherController.text.trim(),
        classroom: _classroomController.text.trim().isEmpty
            ? null
            : _classroomController.text.trim(),
        weekday: _selectedWeekday,
        startTime: _startTime,
        endTime: _endTime,
        weeks: _selectedWeeks.toList()..sort(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        courseType: _selectedCourseType,
        xnm: _isEditMode ? widget.course!.xnm : settings.currentXnm,
        xqm: _isEditMode ? widget.course!.xqm : settings.currentXqm,
        createdAt: _isEditMode ? widget.course!.createdAt : now,
        updatedAt: now,
      );

      final notifier = ref.read(classTableSettingsProvider.notifier);
      if (_isEditMode) {
        await notifier.updateCustomCourse(course);
      } else {
        await notifier.addCustomCourse(course);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ToastService.show(
          _isEditMode ? '课程更新成功' : '课程添加成功',
          backgroundColor: Colors.green,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastService.show(
          '保存失败: $e',
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 显示删除确认对话框
  void _showDeleteConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除课程'),
        content: Text('确定要删除课程"${widget.course!.title}"吗？此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // 关闭确认对话框
              try {
                await ref
                    .read(classTableSettingsProvider.notifier)
                    .deleteCustomCourse(widget.course!.id);
                if (mounted) {
                  Navigator.of(context).pop(); // 关闭编辑对话框
                  ToastService.show(
                    '课程删除成功',
                    backgroundColor: Colors.green,
                  );
                }
              } catch (e) {
                if (mounted) {
                  ToastService.show(
                    '删除失败: $e',
                    backgroundColor: Colors.red,
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  /// 构建课程类型选择器
  Widget _buildCourseTypeSelector(bool isDarkMode, ThemeData theme) {
    const courseTypes = [
      '自定义课程',
      '必修课',
      '选修课',
      '通识课',
      '专业课',
      '实习课',
      '实验课',
      '补习课',
      '兴趣班',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '课程类型',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDarkMode ? Colors.white24 : Colors.black26,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCourseType,
              isExpanded: true,
              items: courseTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(
                    type,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontSize: 16,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCourseType = value;
                  });
                }
              },
              dropdownColor: isDarkMode
                  ? Colors.grey.shade900
                  : Colors.white, // 深色模式下使用更深的颜色
              icon: Icon(
                Icons.arrow_drop_down,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
