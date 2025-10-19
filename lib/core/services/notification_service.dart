import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../utils/app_logger.dart';
import '../../pages/classtable/models/class_table.dart';
import '../../pages/classtable/models/course.dart';
import '../../pages/classtable/constants/period_times.dart';
import '../../pages/classtable/constants/semester.dart';
import '../../pages/index/models/todo_item.dart';
import 'alarm_callbacks.dart';

/// 本地通知服务
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// 通知ID常量
  static const int courseReminderIdBase = 1000; // 课程提醒基础ID
  static const int todoReminderIdBase = 2000; // 待办提醒基础ID

  /// 初始化通知服务
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // 初始化时区数据
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));

      // Android初始化设置
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS初始化设置
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // 初始化设置
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // 初始化插件
      final result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _initialized = result ?? false;

      if (_initialized) {
        AppLogger.info('✅ 通知服务初始化成功');

        // 请求权限
        await _requestPermissions();
      } else {
        AppLogger.error('❌ 通知服务初始化失败');
      }

      return _initialized;
    } catch (e) {
      AppLogger.error('💥 通知服务初始化异常: $e');
      return false;
    }
  }

  /// 请求通知权限
  Future<bool> _requestPermissions() async {
    try {
      // Android 13+ 需要请求通知权限
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();

      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        AppLogger.debug('📱 Android通知权限: ${granted == true ? "已授予" : "未授予"}');
        return granted ?? false;
      }

      // iOS请求权限
      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();

      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        AppLogger.debug('🍎 iOS通知权限: ${granted == true ? "已授予" : "未授予"}');
        return granted ?? false;
      }

      return true;
    } catch (e) {
      AppLogger.error('💥 请求通知权限失败: $e');
      return false;
    }
  }

  /// 通知被点击的回调
  void _onNotificationTapped(NotificationResponse response) {
    AppLogger.debug('🔔 通知被点击: ${response.payload}');
    // TODO: 根据payload跳转到对应页面
  }

  /// 显示即时通知
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        'default_channel',
        '默认通知',
        channelDescription: '默认通知渠道',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, details, payload: payload);
      AppLogger.debug('📤 发送通知: $title');
    } catch (e) {
      AppLogger.error('💥 显示通知失败: $e');
    }
  }

  /// 调度课程提醒
  /// [time] 时间描述（如"周一 第1-2节"）
  Future<void> scheduleCourseReminder({
    required int courseId,
    required String courseName,
    required String location,
    required String teacher,
    required String time,
    required DateTime scheduledTime,
    required int minutes,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // 如果时间已过，不调度
      if (scheduledTime.isBefore(DateTime.now())) {
        AppLogger.debug('⏰ 课程提醒时间已过，跳过: $courseName');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'course_reminder',
        '课程提醒',
        channelDescription: '课程上课提醒',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // 通知格式：3行（标题 + 2行内容）
      // 标题: 上{课程名称}
      // 内容1: 地点
      // 内容2: 时间 - 教师名
      final title = '上$courseName';
      final locationText = location != '未指定教室'
          ? '🏡 地点: $location'
          : '🏡 $location';
      final body =
          '$locationText\n🕒 $time - ${teacher.isNotEmpty ? teacher : "未知教师"}';

      // 平台判断：Android 使用 AlarmManager，iOS 使用 flutter_local_notifications
      if (Platform.isAndroid) {
        // Android: 使用 AlarmManager 确保精确触发
        await _scheduleAndroidAlarm(
          id: courseId,
          title: title,
          body: body,
          scheduledTime: scheduledTime,
          isCourse: true,
        );
      } else {
        // iOS: 使用 flutter_local_notifications
        await _notifications.zonedSchedule(
          courseId,
          title,
          body,
          tzScheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'course_$courseId',
        );
      }

      AppLogger.debug(
        '⏰ 已调度课程提醒 [${Platform.isAndroid ? "Android-AlarmManager" : "iOS"}]: $courseName, 时间: ${scheduledTime.toString()}',
      );
    } catch (e) {
      AppLogger.error('💥 调度课程提醒失败: $e');
    }
  }

  /// 调度待办事项提醒
  Future<void> scheduleTodoReminder({
    required int todoId,
    required String todoTitle,
    required DateTime dueTime,
    int? advanceMinutes,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      // 获取用户设置的提前时间（默认30分钟）
      final minutes = advanceMinutes ?? await getTodoReminderAdvance();
      final scheduledTime = dueTime.subtract(Duration(minutes: minutes));

      // 如果时间已过，不调度
      if (scheduledTime.isBefore(DateTime.now())) {
        AppLogger.debug('⏰ 待办提醒时间已过，跳过: $todoTitle');
        return;
      }

      const androidDetails = AndroidNotificationDetails(
        'todo_reminder',
        '待办提醒',
        channelDescription: '待办事项到期提醒',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = todoReminderIdBase + todoId;
      final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

      // 通知格式：3行（标题 + 2行内容）
      // 标题: 待办标题
      // 内容1: 截止时间
      // 内容2: 提前提醒
      final dueTimeStr = _formatDateTime(dueTime);
      final title = todoTitle;
      final body = '📅 截止：$dueTimeStr\n⏰ 还有$minutes分钟到期';

      // 平台判断：Android 使用 AlarmManager，iOS 使用 flutter_local_notifications
      if (Platform.isAndroid) {
        // Android: 使用 AlarmManager 确保精确触发
        await _scheduleAndroidAlarm(
          id: notificationId,
          title: title,
          body: body,
          scheduledTime: scheduledTime,
          isCourse: false,
        );
      } else {
        // iOS: 使用 flutter_local_notifications
        await _notifications.zonedSchedule(
          notificationId,
          title,
          body,
          tzScheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'todo_$todoId',
        );
      }

      AppLogger.debug(
        '⏰ 已调度待办提醒 [${Platform.isAndroid ? "Android-AlarmManager" : "iOS"}]: $todoTitle, 时间: ${scheduledTime.toString()}',
      );
    } catch (e) {
      AppLogger.error('💥 调度待办提醒失败: $e');
    }
  }

  /// 取消课程提醒
  Future<void> cancelCourseReminder(int courseId) async {
    try {
      final notificationId = courseReminderIdBase + courseId;

      if (Platform.isAndroid) {
        // Android: 取消 AlarmManager 闹钟
        await AndroidAlarmManager.cancel(notificationId);
      } else {
        // iOS: 取消 flutter_local_notifications 通知
        await _notifications.cancel(notificationId);
      }

      AppLogger.debug('🗑️ 已取消课程提醒: $courseId');
    } catch (e) {
      AppLogger.error('💥 取消课程提醒失败: $e');
    }
  }

  /// 取消待办提醒
  Future<void> cancelTodoReminder(int todoId) async {
    try {
      final notificationId = todoReminderIdBase + todoId;

      if (Platform.isAndroid) {
        // Android: 取消 AlarmManager 闹钟
        await AndroidAlarmManager.cancel(notificationId);
      } else {
        // iOS: 取消 flutter_local_notifications 通知
        await _notifications.cancel(notificationId);
      }

      AppLogger.debug('🗑️ 已取消待办提醒: $todoId');
    } catch (e) {
      AppLogger.error('💥 取消待办提醒失败: $e');
    }
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    try {
      if (Platform.isAndroid) {
        // Android: 需要逐个取消 AlarmManager 的闹钟
        // 注意：这里没有批量取消的API，建议在使用时逐个取消
        AppLogger.debug('🗑️ Android平台需要逐个取消闹钟');
      } else {
        // iOS: 取消所有通知
        await _notifications.cancelAll();
      }

      AppLogger.debug('🗑️ 已取消所有通知');
    } catch (e) {
      AppLogger.error('💥 取消所有通知失败: $e');
    }
  }

  /// 获取待处理的通知列表
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      AppLogger.error('💥 获取待处理通知失败: $e');
      return [];
    }
  }

  // ============ 设置相关 ============

  /// 获取课程提醒提前时间（分钟）
  Future<int> getCourseReminderAdvance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('course_reminder_advance') ?? 15;
  }

  /// 设置课程提醒提前时间（分钟）
  Future<void> setCourseReminderAdvance(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('course_reminder_advance', minutes);
    AppLogger.debug('⚙️ 课程提醒提前时间已设置: $minutes分钟');
  }

  /// 获取待办提醒提前时间（分钟）
  Future<int> getTodoReminderAdvance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('todo_reminder_advance') ?? 30;
  }

  /// 设置待办提醒提前时间（分钟）
  Future<void> setTodoReminderAdvance(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('todo_reminder_advance', minutes);
    AppLogger.debug('⚙️ 待办提醒提前时间已设置: $minutes分钟');
  }

  /// 获取是否启用课程提醒
  Future<bool> isCourseReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('course_reminder_enabled') ?? false;
  }

  /// 设置是否启用课程提醒
  Future<void> setCourseReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('course_reminder_enabled', enabled);
    AppLogger.debug('⚙️ 课程提醒已${enabled ? "启用" : "禁用"}');
  }

  /// 获取是否启用待办提醒（默认关闭）
  Future<bool> isTodoReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('todo_reminder_enabled') ?? false;
  }

  /// 设置是否启用待办提醒
  Future<void> setTodoReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('todo_reminder_enabled', enabled);
    AppLogger.debug('⚙️ 待办提醒已${enabled ? "启用" : "禁用"}');
  }

  // ==================== 批量调度通知 ====================

  /// 重新调度课程通知（供 Provider 使用）
  /// 自动检查是否启用、获取课表数据、调度通知
  Future<void> rescheduleCourseNotificationsForSemester({
    required ClassTable classTable,
    required String xnm,
    required String xqm,
  }) async {
    try {
      // 检查是否启用课程提醒
      final isEnabled = await isCourseReminderEnabled();
      if (!isEnabled) {
        AppLogger.debug('🔔 课程提醒已禁用，跳过通知调度');
        return;
      }

      // 调度所有课程通知
      await scheduleAllCourseNotifications(
        classTable: classTable,
        xnm: xnm,
        xqm: xqm,
      );

      AppLogger.debug('🔔 已重新调度课程通知');
    } catch (e) {
      AppLogger.error('🔔 重新调度课程通知失败: $e');
    }
  }

  /// 调度所有课程通知
  /// [classTable] 课表数据
  /// [xnm] 学年 (如 "2024")
  /// [xqm] 学期 (如 "3" 或 "12")
  Future<void> scheduleAllCourseNotifications({
    required ClassTable classTable,
    required String xnm,
    required String xqm,
  }) async {
    // 检查是否启用课程提醒
    final isEnabled = await isCourseReminderEnabled();
    if (!isEnabled) {
      AppLogger.debug('⏰ 课程提醒已禁用，跳过调度');
      return;
    }

    // 先取消所有已存在的课程通知
    await _cancelAllCourseNotifications();

    final advanceMinutes = await getCourseReminderAdvance();
    final semesterStart = SemesterConfig.getSemesterStart(xnm, xqm);
    final now = DateTime.now();

    int scheduledCount = 0;

    // 遍历课表数据
    classTable.weekTable.forEach((week, dayMap) {
      dayMap.forEach((weekday, courses) {
        for (final course in courses) {
          // 计算课程的实际日期
          final courseDate = _calculateCourseDate(semesterStart, week, weekday);

          // 跳过已经过去的课程
          if (courseDate.isBefore(now.subtract(const Duration(days: 1)))) {
            continue;
          }

          // 获取课程的第一节开始时间
          if (course.periods.isEmpty) continue;
          final firstPeriod = course.periods.first;
          final periodTime = PeriodTimes.times[firstPeriod];
          if (periodTime == null) continue;

          // 解析开始时间
          final timeParts = periodTime.begin.split(':');
          if (timeParts.length != 2) continue;

          final courseDateTime = DateTime(
            courseDate.year,
            courseDate.month,
            courseDate.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          // 计算通知时间（提前N分钟）
          final notificationTime = courseDateTime.subtract(
            Duration(minutes: advanceMinutes),
          );

          // 跳过已经过去的通知
          if (notificationTime.isBefore(now)) {
            continue;
          }

          // 调度通知
          _scheduleCourseNotification(
            course: course,
            scheduledTime: notificationTime,
            advanceMinutes: advanceMinutes,
          );

          scheduledCount++;
        }
      });
    });

    AppLogger.info('✅ 已调度 $scheduledCount 个课程通知');
  }

  /// 为单个待办事项调度通知（供 Provider 使用）
  /// 自动检查是否启用、是否完成、是否有截止时间
  Future<void> scheduleSingleTodoNotification(TodoItem todo) async {
    try {
      // 检查是否启用待办提醒
      final isEnabled = await isTodoReminderEnabled();
      if (!isEnabled) {
        AppLogger.debug('🔔 待办提醒已禁用，跳过通知调度');
        return;
      }

      // 只为未完成且有截止时间的待办调度通知
      if (todo.finished || todo.due == null) {
        AppLogger.debug('🔔 待办已完成或无截止时间，跳过通知调度');
        return;
      }

      await scheduleTodoReminder(
        todoId: todo.id,
        todoTitle: todo.title,
        dueTime: todo.due!,
      );

      AppLogger.debug('🔔 已为待办 "${todo.title}" 调度通知');
    } catch (e) {
      AppLogger.error('🔔 调度待办通知失败: $e');
    }
  }

  /// 调度所有待办通知
  /// [todos] 待办事项列表
  Future<void> scheduleAllTodoNotifications({
    required List<TodoItem> todos,
  }) async {
    // 检查是否启用待办提醒
    final isEnabled = await isTodoReminderEnabled();
    if (!isEnabled) {
      AppLogger.debug('⏰ 待办提醒已禁用，跳过调度');
      return;
    }

    // 先取消所有已存在的待办通知
    await _cancelAllTodoNotifications();

    final advanceMinutes = await getTodoReminderAdvance();
    final now = DateTime.now();

    int scheduledCount = 0;

    for (final todo in todos) {
      // 跳过已完成的待办
      if (todo.finished) continue;

      // 跳过没有截止时间的待办
      if (todo.due == null) continue;

      // 计算通知时间（提前N分钟）
      final notificationTime = todo.due!.subtract(
        Duration(minutes: advanceMinutes),
      );

      // 跳过已经过去的通知
      if (notificationTime.isBefore(now)) {
        continue;
      }

      // 调度通知
      await scheduleTodoReminder(
        todoId: todo.id,
        todoTitle: todo.title,
        dueTime: todo.due!,
        advanceMinutes: advanceMinutes,
      );

      scheduledCount++;
    }

    AppLogger.info('✅ 已调度 $scheduledCount 个待办通知');
  }

  /// 取消所有课程通知
  Future<void> _cancelAllCourseNotifications() async {
    try {
      if (Platform.isAndroid) {
        // Android: 取消 AlarmManager 范围内的所有课程闹钟
        // 课程通知ID范围: 1000-1999 (共1000个)
        for (int i = 0; i < 1000; i++) {
          final notificationId = courseReminderIdBase + i;
          await AndroidAlarmManager.cancel(notificationId);
        }
      } else {
        // iOS: 获取所有待处理的通知并取消课程相关的
        final pending = await getPendingNotifications();
        for (final notification in pending) {
          // 课程通知ID范围: 1000-1999
          if (notification.id >= courseReminderIdBase &&
              notification.id < todoReminderIdBase) {
            await _notifications.cancel(notification.id);
          }
        }
      }
      AppLogger.debug('🗑️ 已取消所有课程通知');
    } catch (e) {
      AppLogger.error('💥 取消课程通知失败: $e');
    }
  }

  /// 取消所有待办通知
  Future<void> _cancelAllTodoNotifications() async {
    try {
      if (Platform.isAndroid) {
        // Android: 取消 AlarmManager 范围内的所有待办闹钟
        // 待办通知ID范围: 2000-2999 (共1000个)
        for (int i = 0; i < 1000; i++) {
          final notificationId = todoReminderIdBase + i;
          await AndroidAlarmManager.cancel(notificationId);
        }
      } else {
        // iOS: 获取所有待处理的通知并取消待办相关的
        final pending = await getPendingNotifications();
        for (final notification in pending) {
          // 待办通知ID范围: 2000-2999
          if (notification.id >= todoReminderIdBase &&
              notification.id < todoReminderIdBase + 1000) {
            await _notifications.cancel(notification.id);
          }
        }
      }
      AppLogger.debug('🗑️ 已取消所有待办通知');
    } catch (e) {
      AppLogger.error('💥 取消待办通知失败: $e');
    }
  }

  /// 私有方法：调度单个课程通知
  void _scheduleCourseNotification({
    required Course course,
    required DateTime scheduledTime,
    required int advanceMinutes,
  }) {
    // 使用课程ID的hashCode作为通知ID的一部分
    final notificationId =
        courseReminderIdBase + (course.id.hashCode.abs() % 1000);

    // 格式化通知内容 - 使用准确时间而不是节次
    final timeText = _formatCourseTime(course.periods);
    final weekdayText = _getWeekdayName(course.weekday);

    scheduleCourseReminder(
      courseId: notificationId,
      courseName: course.title,
      location: course.classroom.isNotEmpty ? course.classroom : '未指定教室',
      teacher: course.teacher,
      time: '$weekdayText $timeText',
      scheduledTime: scheduledTime,
      minutes: advanceMinutes,
    );
  }

  /// 计算课程的实际日期
  DateTime _calculateCourseDate(DateTime semesterStart, int week, int weekday) {
    // 计算从学期开始到指定周的天数
    final daysFromStart = (week - 1) * 7;

    // 计算到指定星期几的偏移（weekday: 1=周一, 7=周日）
    // semesterStart.weekday: 1=周一, 7=周日
    final startWeekday = semesterStart.weekday;
    final dayOffset = weekday - startWeekday;

    return semesterStart.add(Duration(days: daysFromStart + dayOffset));
  }

  /// 格式化节次列表（显示节次编号，已弃用，改用_formatCourseTime）
  String _formatPeriods(List<int> periods) {
    if (periods.isEmpty) return '';
    if (periods.length == 1) return '第${periods.first}节';

    final first = periods.first;
    final last = periods.last;
    if (last - first + 1 == periods.length) {
      // 连续节次
      return '第$first-$last节';
    }

    // 非连续节次，只显示首尾
    return '第$first-$last节';
  }

  /// 格式化课程时间（显示准确的上课时间）
  String _formatCourseTime(List<int> periods) {
    if (periods.isEmpty) return '';

    // 获取第一节课的开始时间
    final firstPeriod = periods.first;
    final firstPeriodTime = PeriodTimes.times[firstPeriod];

    // 获取最后一节课的结束时间
    final lastPeriod = periods.last;
    final lastPeriodTime = PeriodTimes.times[lastPeriod];

    if (firstPeriodTime == null || lastPeriodTime == null) {
      return _formatPeriods(periods); // 降级到显示节次
    }

    // 返回格式：08:00-09:40
    return '${firstPeriodTime.begin}-${lastPeriodTime.end}';
  }

  /// 获取星期几的中文名称
  String _getWeekdayName(int weekday) {
    const weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekday >= 1 && weekday <= 7 ? weekdays[weekday] : '周?';
  }

  /// 格式化日期时间
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final targetDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    String dateStr;
    if (targetDate == today) {
      dateStr = '今天';
    } else if (targetDate == tomorrow) {
      dateStr = '明天';
    } else {
      dateStr = '${dateTime.month}月${dateTime.day}日';
    }

    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$dateStr $hour:$minute';
  }

  // ==================== 获取下一条通知 ====================

  /// 获取下一条课程通知信息
  Future<Map<String, dynamic>?> getNextCourseNotification({
    required ClassTable classTable,
    required String xnm,
    required String xqm,
  }) async {
    final isEnabled = await isCourseReminderEnabled();
    if (!isEnabled) return null;

    final advanceMinutes = await getCourseReminderAdvance();
    final semesterStart = SemesterConfig.getSemesterStart(xnm, xqm);
    final now = DateTime.now();

    DateTime? nextTime;
    Course? nextCourse;
    String? nextWeekday;
    String? nextPeriod;

    // 遍历课表查找最近的课程
    classTable.weekTable.forEach((week, dayMap) {
      dayMap.forEach((weekday, courses) {
        for (final course in courses) {
          final courseDate = _calculateCourseDate(semesterStart, week, weekday);
          if (courseDate.isBefore(now.subtract(const Duration(days: 1)))) {
            continue;
          }

          if (course.periods.isEmpty) continue;
          final firstPeriod = course.periods.first;
          final periodTime = PeriodTimes.times[firstPeriod];
          if (periodTime == null) continue;

          final timeParts = periodTime.begin.split(':');
          if (timeParts.length != 2) continue;

          final courseDateTime = DateTime(
            courseDate.year,
            courseDate.month,
            courseDate.day,
            int.parse(timeParts[0]),
            int.parse(timeParts[1]),
          );

          final notificationTime = courseDateTime.subtract(
            Duration(minutes: advanceMinutes),
          );

          if (notificationTime.isBefore(now)) continue;

          if (nextTime == null || notificationTime.isBefore(nextTime!)) {
            nextTime = notificationTime;
            nextCourse = course;
            nextWeekday = _getWeekdayName(weekday);
            nextPeriod = _formatCourseTime(course.periods);
          }
        }
      });
    });

    if (nextCourse == null || nextWeekday == null || nextPeriod == null) {
      return null;
    }

    // 使用!确保非null
    final title = '上${nextCourse!.title}';
    final location = nextCourse!.classroom.isNotEmpty
        ? '地点: ${nextCourse!.classroom}'
        : "未指定教室";
    final teacher = nextCourse!.teacher.isNotEmpty
        ? nextCourse!.teacher
        : "未知教师";
    final body = '🏡 $location\n🕒 $nextWeekday $nextPeriod - $teacher';

    return {'title': title, 'body': body};
  }

  /// 获取下一条待办通知信息
  Future<Map<String, dynamic>?> getNextTodoNotification({
    required List<TodoItem> todos,
  }) async {
    final isEnabled = await isTodoReminderEnabled();
    if (!isEnabled) return null;

    final advanceMinutes = await getTodoReminderAdvance();
    final now = DateTime.now();

    DateTime? nextTime;
    TodoItem? nextTodo;

    for (final todo in todos) {
      if (todo.finished || todo.due == null) continue;

      final notificationTime = todo.due!.subtract(
        Duration(minutes: advanceMinutes),
      );

      if (notificationTime.isBefore(now)) continue;

      if (nextTime == null || notificationTime.isBefore(nextTime)) {
        nextTime = notificationTime;
        nextTodo = todo;
      }
    }

    if (nextTodo == null) return null;

    final dueTimeStr = _formatDateTime(nextTodo.due!);
    return {
      'title': nextTodo.title,
      'body': '📅 截止：$dueTimeStr\n⏰ 还有$advanceMinutes分钟到期',
    };
  }

  // ==================== 平台特定实现 ====================

  /// Android 平台：使用 AlarmManager 调度精确闹钟
  Future<void> _scheduleAndroidAlarm({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required bool isCourse,
  }) async {
    try {
      // 准备传递给回调的数据
      final data = {'title': title, 'body': body};

      // 使用 AlarmManager 设置精确闹钟
      await AndroidAlarmManager.oneShotAt(
        scheduledTime,
        id,
        isCourse ? alarmCallback : todoAlarmCallback,
        exact: true, // 精确触发
        wakeup: true, // 唤醒设备
        rescheduleOnReboot: true, // 重启后重新调度
        params: data,
      );

      AppLogger.debug('✅ [Android-AlarmManager] 闹钟已设置, ID: $id');
    } catch (e) {
      AppLogger.error('💥 [Android-AlarmManager] 设置失败: $e');
      rethrow;
    }
  }
}
