import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/services/toast_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/config/providers/theme_config_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';
import '../classtable/providers/classtable_providers.dart';
import '../classtable/providers/classtable_settings_provider.dart';
import '../index/providers/todo_provider.dart';
import '../../core/providers/auth_provider.dart';

/// 通知设置页面
class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage> {
  final NotificationService _notificationService = NotificationService();

  bool _courseReminderEnabled = false; // 默认关闭
  bool _todoReminderEnabled = false; // 默认关闭
  int _courseAdvanceMinutes = 15;
  int _todoAdvanceMinutes = 30;

  // 预设的提前时间选项
  final List<int> _timeOptions = [5, 10, 15, 20, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final courseEnabled = await _notificationService
          .isCourseReminderEnabled();
      final todoEnabled = await _notificationService.isTodoReminderEnabled();
      final courseAdvance = await _notificationService
          .getCourseReminderAdvance();
      final todoAdvance = await _notificationService.getTodoReminderAdvance();

      setState(() {
        _courseReminderEnabled = courseEnabled;
        _todoReminderEnabled = todoEnabled;
        _courseAdvanceMinutes = courseAdvance;
        _todoAdvanceMinutes = todoAdvance;
      });
    } catch (e) {
      AppLogger.error('💥 加载通知设置失败: $e');
    }
  }

  Future<void> _saveCourseEnabled(bool value) async {
    // 如果要启用通知，先检查并申请权限
    if (value) {
      final result = await PermissionService.requestPermission(
        AppPermissionType.notification,
        context: context,
        showRationale: true,
      );

      if (!result.isGranted) {
        // 权限被拒绝，不启用通知
        ToastService.show(
          result.isPermanentlyDenied ? '通知权限被拒绝，请在系统设置中手动开启' : '需要通知权限才能启用课程提醒',
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        );
        return;
      }
    }

    await _notificationService.setCourseReminderEnabled(value);
    setState(() {
      _courseReminderEnabled = value;
    });

    // 如果启用了课程提醒，自动调度通知；如果禁用，则取消所有课程通知
    if (value) {
      try {
        final classTableSettings = ref.read(classTableSettingsProvider);
        final xnm = classTableSettings.currentXnm;
        final xqm = classTableSettings.currentXqm;

        final classTable = await ref.read(
          classTableProvider((xnm: xnm, xqm: xqm)).future,
        );

        await _notificationService.scheduleAllCourseNotifications(
          classTable: classTable,
          xnm: xnm,
          xqm: xqm,
        );

        ToastService.show('课程提醒已启用，通知已调度', backgroundColor: Colors.green);
      } catch (e) {
        AppLogger.error('自动调度课程通知失败: $e');
        ToastService.show('课程提醒已启用', backgroundColor: Colors.green);
      }
    } else {
      ToastService.show('课程提醒已禁用', backgroundColor: null);
    }
  }

  Future<void> _saveTodoEnabled(bool value) async {
    // 如果要启用通知，先检查并申请权限
    if (value) {
      final result = await PermissionService.requestPermission(
        AppPermissionType.notification,
        context: context,
        showRationale: true,
      );

      if (!result.isGranted) {
        // 权限被拒绝，不启用通知
        ToastService.show(
          result.isPermanentlyDenied ? '通知权限被拒绝，请在系统设置中手动开启' : '需要通知权限才能启用待办提醒',
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        );
        return;
      }
    }

    await _notificationService.setTodoReminderEnabled(value);
    setState(() {
      _todoReminderEnabled = value;
    });

    // 如果启用了待办提醒，自动调度通知；如果禁用，则取消所有待办通知
    if (value) {
      try {
        final todos = ref.read(todoProvider);
        await _notificationService.scheduleAllTodoNotifications(todos: todos);

        ToastService.show('待办提醒已启用，通知已调度', backgroundColor: Colors.green);
      } catch (e) {
        AppLogger.error('自动调度待办通知失败: $e');
        ToastService.show('待办提醒已启用', backgroundColor: Colors.green);
      }
    } else {
      ToastService.show('待办提醒已禁用', backgroundColor: null);
    }
  }

  Future<void> _saveCourseAdvance(int minutes) async {
    await _notificationService.setCourseReminderAdvance(minutes);
    setState(() {
      _courseAdvanceMinutes = minutes;
    });

    // 自动重新调度课程通知
    if (_courseReminderEnabled) {
      try {
        final classTableSettings = ref.read(classTableSettingsProvider);
        final xnm = classTableSettings.currentXnm;
        final xqm = classTableSettings.currentXqm;

        final classTable = await ref.read(
          classTableProvider((xnm: xnm, xqm: xqm)).future,
        );

        await _notificationService.scheduleAllCourseNotifications(
          classTable: classTable,
          xnm: xnm,
          xqm: xqm,
        );

        ToastService.show(
          '课程提醒时间已更新为提前 $minutes 分钟，通知已重新调度',
          backgroundColor: Colors.green,
        );
      } catch (e) {
        AppLogger.error('重新调度课程通知失败: $e');
        ToastService.show('提前时间已更新，但通知调度失败', backgroundColor: Colors.orange);
      }
    } else {
      ToastService.show(
        '课程提醒时间已设置为提前 $minutes 分钟',
        backgroundColor: Colors.green,
      );
    }
  }

  Future<void> _saveTodoAdvance(int minutes) async {
    await _notificationService.setTodoReminderAdvance(minutes);
    setState(() {
      _todoAdvanceMinutes = minutes;
    });

    // 自动重新调度待办通知
    if (_todoReminderEnabled) {
      try {
        final todos = ref.read(todoProvider);
        await _notificationService.scheduleAllTodoNotifications(todos: todos);

        ToastService.show(
          '待办提醒时间已更新为提前 $minutes 分钟，通知已重新调度',
          backgroundColor: Colors.green,
        );
      } catch (e) {
        AppLogger.error('重新调度待办通知失败: $e');
        ToastService.show('提前时间已更新，但通知调度失败', backgroundColor: Colors.orange);
      }
    } else {
      ToastService.show(
        '待办提醒时间已设置为提前 $minutes 分钟',
        backgroundColor: Colors.green,
      );
    }
  }

  void _showCourseAdvanceTimePicker(bool isDarkMode, Color activeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '选择课程提醒提前时间',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(_timeOptions.length, (index) {
                    final minutes = _timeOptions[index];
                    final isSelected = minutes == _courseAdvanceMinutes;

                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? activeColor : null,
                      ),
                      title: Text(
                        '提前 $minutes 分钟',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: activeColor)
                          : null,
                      onTap: () {
                        _saveCourseAdvance(minutes);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTodoAdvanceTimePicker(bool isDarkMode, Color activeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              '选择待办提醒提前时间',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(_timeOptions.length, (index) {
                    final minutes = _timeOptions[index];
                    final isSelected = minutes == _todoAdvanceMinutes;

                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected ? activeColor : null,
                      ),
                      title: Text(
                        '提前 $minutes 分钟',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: activeColor)
                          : null,
                      onTap: () {
                        _saveTodoAdvance(minutes);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _testCourseNotification() async {
    try {
      // 尝试获取真实的第一条课程通知
      Map<String, dynamic>? notification;

      if (_courseReminderEnabled) {
        final classTableSettings = ref.read(classTableSettingsProvider);
        final xnm = classTableSettings.currentXnm;
        final xqm = classTableSettings.currentXqm;

        final classTable = await ref.read(
          classTableProvider((xnm: xnm, xqm: xqm)).future,
        );

        notification = await _notificationService.getNextCourseNotification(
          classTable: classTable,
          xnm: xnm,
          xqm: xqm,
        );
      }

      // 如果没有真实通知，发送示例
      if (notification == null) {
        await _notificationService.showNotification(
          id: 0,
          title: '上计算机组成原理',
          body: '教学楼A101\n周一 第1-2节 - 张三',
        );
      } else {
        await _notificationService.showNotification(
          id: 0,
          title: notification['title'],
          body: notification['body'],
        );
      }

      ToastService.show('测试通知已发送', backgroundColor: Colors.green);
    } catch (e) {
      AppLogger.error('发送测试通知失败: $e');
      ToastService.show('发送失败', backgroundColor: Colors.red);
    }
  }

  Future<void> _testTodoNotification() async {
    try {
      // 尝试获取真实的第一条待办通知
      Map<String, dynamic>? notification;

      if (_todoReminderEnabled) {
        final todos = ref.read(todoProvider);
        notification = await _notificationService.getNextTodoNotification(
          todos: todos,
        );
      }

      // 如果没有真实通知，发送示例
      if (notification == null) {
        await _notificationService.showNotification(
          id: 1,
          title: '完成作业',
          body: '📅 截止：今天 18:30\n⏰ 还有30分钟到期',
        );
      } else {
        await _notificationService.showNotification(
          id: 1,
          title: notification['title'],
          body: notification['body'],
        );
      }

      ToastService.show('测试通知已发送', backgroundColor: Colors.green);
    } catch (e) {
      AppLogger.error('发送测试通知失败: $e');
      ToastService.show('发送失败', backgroundColor: Colors.red);
    }
  }

  /// 调度所有通知
  Future<void> _scheduleAllNotifications() async {
    try {
      // 获取用户信息（需要判断是否登录）
      final authState = ref.read(authProvider);
      if (authState.user == null) {
        ToastService.show('请先登录', backgroundColor: Colors.orange);
        return;
      }

      // 显示加载提示
      ToastService.show('正在调度通知...', backgroundColor: Colors.blue);

      int totalScheduled = 0;

      // 调度课程通知
      if (_courseReminderEnabled) {
        try {
          final classTableSettings = ref.read(classTableSettingsProvider);
          final xnm = classTableSettings.currentXnm;
          final xqm = classTableSettings.currentXqm;

          final classTableAsync = ref.read(
            classTableProvider((xnm: xnm, xqm: xqm)).future,
          );

          final classTable = await classTableAsync;
          await _notificationService.scheduleAllCourseNotifications(
            classTable: classTable,
            xnm: xnm,
            xqm: xqm,
          );

          // 统计课程通知数量
          classTable.weekTable.forEach((week, dayMap) {
            dayMap.forEach((weekday, courses) {
              totalScheduled += courses.length;
            });
          });
        } catch (e) {
          AppLogger.error('调度课程通知失败: $e');
        }
      }

      // 调度待办通知
      if (_todoReminderEnabled) {
        try {
          final todos = ref.read(todoProvider);
          await _notificationService.scheduleAllTodoNotifications(todos: todos);

          // 统计未完成且有截止时间的待办数量
          totalScheduled += todos
              .where((todo) => !todo.finished && todo.due != null)
              .length;
        } catch (e) {
          AppLogger.error('调度待办通知失败: $e');
        }
      }

      ToastService.show(
        '通知调度完成！已安排 $totalScheduled 个提醒',
        backgroundColor: Colors.green,
      );
    } catch (e) {
      AppLogger.error('调度通知失败: $e');
      ToastService.show('调度失败: $e', backgroundColor: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);

    // 获取主题色，如果没有主题则使用默认蓝色
    final themeColor = currentTheme.colorList.isNotEmpty == true
        ? currentTheme.colorList[0]
        : Colors.blue;
    final activeColor = isDarkMode ? themeColor.withAlpha(204) : themeColor;

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: false,
      appBar: ThemeAwareAppBar(title: '通知设置'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 课程提醒设置
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
                    '📚 课程提醒',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(
                      '启用课程提醒',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '在课程开始前提醒您',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: _courseReminderEnabled,
                    onChanged: _saveCourseEnabled,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: activeColor,
                  ),
                  ListTile(
                    enabled: _courseReminderEnabled,
                    leading: Icon(
                      Icons.access_time,
                      color: _courseReminderEnabled
                          ? (isDarkMode ? Colors.white70 : Colors.black54)
                          : (isDarkMode ? Colors.white24 : Colors.black26),
                    ),
                    title: Text(
                      '提前提醒时间',
                      style: TextStyle(
                        color: _courseReminderEnabled
                            ? (isDarkMode ? Colors.white : Colors.black)
                            : (isDarkMode ? Colors.white38 : Colors.black38),
                      ),
                    ),
                    subtitle: Text(
                      '提前 $_courseAdvanceMinutes 分钟',
                      style: TextStyle(
                        color: _courseReminderEnabled
                            ? (isDarkMode ? Colors.white70 : Colors.black54)
                            : (isDarkMode ? Colors.white24 : Colors.black26),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: _courseReminderEnabled
                          ? (isDarkMode ? Colors.white70 : Colors.black54)
                          : (isDarkMode ? Colors.white24 : Colors.black26),
                    ),
                    contentPadding: EdgeInsets.zero,
                    onTap: _courseReminderEnabled
                        ? () => _showCourseAdvanceTimePicker(
                            isDarkMode,
                            activeColor,
                          )
                        : null,
                  ),
                  ListTile(
                    enabled: _courseReminderEnabled,
                    leading: Icon(
                      Icons.notifications_active,
                      color: _courseReminderEnabled
                          ? (isDarkMode ? Colors.white70 : Colors.black54)
                          : (isDarkMode ? Colors.white24 : Colors.black26),
                    ),
                    title: Text(
                      '测试课程通知',
                      style: TextStyle(
                        color: _courseReminderEnabled
                            ? (isDarkMode ? Colors.white : Colors.black)
                            : (isDarkMode ? Colors.white38 : Colors.black38),
                      ),
                    ),
                    subtitle: Text(
                      '发送一条测试通知',
                      style: TextStyle(
                        color: _courseReminderEnabled
                            ? (isDarkMode ? Colors.white70 : Colors.black54)
                            : (isDarkMode ? Colors.white24 : Colors.black26),
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    onTap: _courseReminderEnabled
                        ? _testCourseNotification
                        : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 待办提醒设置
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
                    '📋 待办提醒',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(
                      '启用待办提醒',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '在待办事项到期前提醒您',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    value: _todoReminderEnabled,
                    onChanged: _saveTodoEnabled,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: activeColor,
                  ),
                  ListTile(
                    enabled: _todoReminderEnabled,
                    leading: Icon(
                      Icons.access_time,
                      color: _todoReminderEnabled
                          ? (isDarkMode ? Colors.white70 : Colors.black54)
                          : (isDarkMode ? Colors.white24 : Colors.black26),
                    ),
                    title: Text(
                      '提前提醒时间',
                      style: TextStyle(
                        color: _todoReminderEnabled
                            ? (isDarkMode ? Colors.white : Colors.black)
                            : (isDarkMode ? Colors.white38 : Colors.black38),
                      ),
                    ),
                    subtitle: Text(
                      '提前 $_todoAdvanceMinutes 分钟',
                      style: TextStyle(
                        color: _todoReminderEnabled
                            ? (isDarkMode ? Colors.white70 : Colors.black54)
                            : (isDarkMode ? Colors.white24 : Colors.black26),
                      ),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: _todoReminderEnabled
                          ? (isDarkMode ? Colors.white70 : Colors.black54)
                          : (isDarkMode ? Colors.white24 : Colors.black26),
                    ),
                    contentPadding: EdgeInsets.zero,
                    onTap: _todoReminderEnabled
                        ? () => _showTodoAdvanceTimePicker(
                            isDarkMode,
                            activeColor,
                          )
                        : null,
                  ),
                  ListTile(
                    enabled: _todoReminderEnabled,
                    leading: Icon(
                      Icons.notifications_active,
                      color: _todoReminderEnabled
                          ? (isDarkMode ? Colors.white70 : Colors.black54)
                          : (isDarkMode ? Colors.white24 : Colors.black26),
                    ),
                    title: Text(
                      '测试待办通知',
                      style: TextStyle(
                        color: _todoReminderEnabled
                            ? (isDarkMode ? Colors.white : Colors.black)
                            : (isDarkMode ? Colors.white38 : Colors.black38),
                      ),
                    ),
                    subtitle: Text(
                      '发送一条测试通知',
                      style: TextStyle(
                        color: _todoReminderEnabled
                            ? (isDarkMode ? Colors.white70 : Colors.black54)
                            : (isDarkMode ? Colors.white24 : Colors.black26),
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    onTap: _todoReminderEnabled ? _testTodoNotification : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 通知管理
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
                    '🛠️ 通知管理',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(
                      Icons.info_outline,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    title: Text(
                      '待发送通知数量',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: FutureBuilder(
                      future: _notificationService.getPendingNotifications(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Text(
                            '${snapshot.data!.length} 条待发送通知',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          );
                        }
                        return Text(
                          '加载中...',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        );
                      },
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.schedule_send,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    title: Text(
                      '立即调度所有通知',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '根据课表和待办安排提醒通知',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    onTap: _scheduleAllNotifications,
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_sweep,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                    title: Text(
                      '清除所有通知',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      '取消所有待发送的通知',
                      style: TextStyle(
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: isDarkMode
                              ? const Color(0xFF2A2A2A)
                              : Colors.white,
                          title: Text(
                            '确认清除',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          content: Text(
                            '确定要清除所有待发送的通知吗？',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black87,
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: Text(
                                '取消',
                                style: TextStyle(
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.black87,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: Text(
                                '确定',
                                style: TextStyle(color: activeColor),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await _notificationService.cancelAll();
                        setState(() {});

                        ToastService.show(
                          '已清除所有通知',
                          backgroundColor: Colors.green,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // 温馨提示
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
                  Row(
                    children: [
                      Icon(
                        Icons.tips_and_updates,
                        color: Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '温馨提示',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• 通知需要在系统设置中授予权限\n'
                    '• 课程提醒会在课程开始前自动发送\n'
                    '• 待办提醒会在到期时间前自动发送\n'
                    '• 如果关闭通知权限，将无法接收提醒',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: isDarkMode ? Colors.white70 : Colors.black54,
                    ),
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
