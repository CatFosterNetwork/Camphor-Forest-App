import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../utils/app_logger.dart';

/// AlarmManager 回调处理器（顶级函数）
///
/// ⚠️ 重要：这个函数必须是顶级函数或静态方法，不能是实例方法
/// 因为 AlarmManager 在后台独立进程中调用，无法访问实例

/// 课程提醒回调
@pragma('vm:entry-point')
void alarmCallback(int id, Map<String, dynamic> data) async {
  AppLogger.info('⏰ [AlarmManager] 触发课程提醒回调, ID: $id');

  try {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android 通知详情
    const androidDetails = AndroidNotificationDetails(
      'course_reminder',
      '课程提醒',
      channelDescription: '课程上课提醒',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const details = NotificationDetails(android: androidDetails);

    // 从data中提取通知信息
    final title = data['title'] as String? ?? '课程提醒';
    final body = data['body'] as String? ?? '';

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: 'course_$id',
    );

    AppLogger.info('✅ [AlarmManager] 课程通知已显示');
  } catch (e) {
    AppLogger.error('💥 [AlarmManager] 显示通知失败: $e');
  }
}

/// 待办提醒回调
@pragma('vm:entry-point')
void todoAlarmCallback(int id, Map<String, dynamic> data) async {
  AppLogger.info('⏰ [AlarmManager] 触发待办提醒回调, ID: $id');

  try {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android 通知详情
    const androidDetails = AndroidNotificationDetails(
      'todo_reminder',
      '待办提醒',
      channelDescription: '待办事项到期提醒',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const details = NotificationDetails(android: androidDetails);

    // 从data中提取通知信息
    final title = data['title'] as String? ?? '待办提醒';
    final body = data['body'] as String? ?? '';

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      details,
      payload: 'todo_$id',
    );

    AppLogger.info('✅ [AlarmManager] 待办通知已显示');
  } catch (e) {
    AppLogger.error('💥 [AlarmManager] 显示通知失败: $e');
  }
}

/// 初始化AlarmManager回调（需要在main中调用）
Future<void> initializeAlarmManager() async {
  try {
    await AndroidAlarmManager.initialize();
    AppLogger.info('✅ [AlarmManager] 初始化成功');
  } catch (e) {
    AppLogger.error('💥 [AlarmManager] 初始化失败: $e');
  }
}
