import 'dart:convert';

import '../../../core/utils/app_logger.dart';
import 'course.dart';

/// 课表数据结构：按周次和星期几组织课程信息
/// 结构：Map<week, Map<weekday, List<Course>>>
class ClassTable {
  /// 课表数据，格式为：{周次: {星期几: [课程列表]}}
  final Map<int, Map<int, List<Course>>> weekTable;

  /// 学年，如 "2024"
  final String xnm;

  /// 学期，如 "12" 表示第一学期
  final String xqm;

  const ClassTable({
    required this.weekTable,
    required this.xnm,
    required this.xqm,
  });

  /// 从格式化的JSON创建课表对象
  factory ClassTable.fromFormattedJson(
    Map<String, dynamic> json, {
    required String xnm,
    required String xqm,
  }) {
    final weekTable = <int, Map<int, List<Course>>>{};

    try {
      json.forEach((weekKey, weekValue) {
        final week = int.tryParse(weekKey);
        if (week == null || weekValue is! Map) return;

        final weekdayMap = <int, List<Course>>{};
        weekTable[week] = weekdayMap;

        weekValue.forEach((weekdayKey, courseList) {
          final weekday = int.tryParse(weekdayKey);
          if (weekday == null || courseList is! List) return;

          final courses = courseList
              .whereType<Map<String, dynamic>>()
              .map((courseJson) => Course.fromFormattedJson(courseJson))
              .toList();

          weekdayMap[weekday] = courses;
        });
      });
    } catch (e) {
      AppLogger.debug('解析格式化JSON出错: $e');
      // 在出错情况下返回空表
    }

    return ClassTable(weekTable: weekTable, xnm: xnm, xqm: xqm);
  }

  /// 从原始API返回的数据创建课表对象
  factory ClassTable.fromRawJson(dynamic rawData) {
    final weekTable = <int, Map<int, List<Course>>>{};
    String xnm = '';
    String xqm = '';

    try {
      // 确保rawData是Map类型
      final Map<String, dynamic> rawJson;
      if (rawData is String) {
        // 如果是字符串，尝试解析为JSON
        AppLogger.debug(
          '尝试解析JSON字符串: ${rawData.substring(0, min(100, rawData.length))}...',
        );
        rawJson = jsonDecode(rawData) as Map<String, dynamic>;
      } else if (rawData is Map<String, dynamic>) {
        rawJson = rawData;
      } else {
        AppLogger.debug('原始数据类型不是Map或String: ${rawData.runtimeType}');
        return ClassTable(weekTable: weekTable, xnm: xnm, xqm: xqm);
      }

      // 打印完整的JSON结构以进行调试
      AppLogger.debug('API响应数据结构: ${rawJson.keys.join(", ")}');

      // 检查响应状态
      final code = rawJson['code'];
      final success = rawJson['success'];
      if (code != 200 || success != true) {
        AppLogger.debug('API响应状态错误: code=$code, success=$success');
        return ClassTable(weekTable: weekTable, xnm: xnm, xqm: xqm);
      }

      // 获取data部分
      final data = rawJson['data'];
      if (data == null) {
        AppLogger.debug('API响应中没有data字段');
        return ClassTable(weekTable: weekTable, xnm: xnm, xqm: xqm);
      }

      // 提取学年学期信息
      if (data['xsxx'] != null) {
        final xsxx = data['xsxx'] as Map<String, dynamic>;
        xnm = xsxx['XNM']?.toString() ?? '';
        xqm = xsxx['XQM']?.toString() ?? '';
        AppLogger.debug('提取到学年学期: xnm=$xnm, xqm=$xqm');
      }

      // 处理常规课程 kbList
      if (data['kbList'] != null) {
        final kbList = data['kbList'] as List? ?? [];
        AppLogger.debug('课程列表数量: ${kbList.length}');

        for (final item in kbList) {
          if (item is! Map<String, dynamic>) continue;

          try {
            final course = Course.fromRawJson(item);
            final weekday = course.weekday;

            // 输出调试信息
            AppLogger.debug(
              '解析课程: ${course.title}, 周${course.weekday}, 第${course.periods.join(",")}节, 周次${course.weeks.join(",")}, kcxz=${course.kcxz}, kclb=${course.kclb}',
            );

            // 遍历课程的每个周次，将课程添加到对应周次和星期的列表中
            for (final week in course.weeks) {
              weekTable.putIfAbsent(week, () => <int, List<Course>>{});
              weekTable[week]!.putIfAbsent(weekday, () => <Course>[]);

              // 检查是否已有相同课程，若有则合并教师信息
              final existingCourseIndex = weekTable[week]![weekday]!.indexWhere(
                (existingCourse) =>
                    existingCourse.id == course.id &&
                    existingCourse.start == course.start &&
                    existingCourse.end == course.end,
              );

              if (existingCourseIndex != -1) {
                // 有相同课程，合并教师信息
                final existingCourse =
                    weekTable[week]![weekday]![existingCourseIndex];
                if (!existingCourse.teacher.contains(course.teacher)) {
                  // 这里不能直接修改existingCourse.teacher，因为Course是不可变的
                  // 创建一个新的Course对象，合并教师信息
                  final updatedCourse = Course(
                    id: existingCourse.id,
                    title: existingCourse.title,
                    classroom: existingCourse.classroom,
                    teacher: '${existingCourse.teacher},${course.teacher}',
                    weekday: existingCourse.weekday,
                    periods: existingCourse.periods,
                    weeks: existingCourse.weeks,
                    kcxz: existingCourse.kcxz,
                    kclb: existingCourse.kclb,
                  );
                  weekTable[week]![weekday]![existingCourseIndex] =
                      updatedCourse;
                }
              } else {
                // 添加新课程
                weekTable[week]![weekday]!.add(course);
              }
            }
          } catch (e) {
            AppLogger.debug('解析课程失败: $e');
          }
        }
      }

      // 处理实践课程 sjkList
      if (data['sjkList'] != null) {
        final sjkList = data['sjkList'] as List? ?? [];
        AppLogger.debug('实践课程数量: ${sjkList.length}');

        for (final item in sjkList) {
          if (item is! Map<String, dynamic>) continue;

          try {
            // 提取实践课程信息
            final title = item['kcmc']?.toString() ?? '未知课程';
            final teacher = item['jsxm']?.toString() ?? '';
            final classroom = item['xqmc']?.toString() ?? '';

            // 解析周次 (如 "19-20周")
            final weeks = <int>[];
            final weekStr = item['qsjsz']?.toString() ?? '';
            if (weekStr.isNotEmpty) {
              AppLogger.debug('解析实践课程周次: $weekStr');

              // 去掉"周"字，分离范围
              final weeksStr = weekStr.replaceAll('周', '');

              if (weeksStr.contains('-')) {
                final parts = weeksStr.split('-');
                if (parts.length == 2) {
                  final start = int.tryParse(parts[0]) ?? 0;
                  final end = int.tryParse(parts[1]) ?? 0;

                  if (start > 0 && end >= start) {
                    for (int i = start; i <= end; i++) {
                      weeks.add(i);
                    }
                  }
                }
              } else {
                final week = int.tryParse(weeksStr) ?? 0;
                if (week > 0) {
                  weeks.add(week);
                }
              }
            }

            // 如果未能解析出周次，默认为第1周
            if (weeks.isEmpty) {
              weeks.add(1);
            }

            // 实践课一般没有固定的星期几和节次
            // 实践课程默认显示在周日（第7天）
            int weekday = 7; // 默认周日
            final day = item['day']?.toString();
            if (day != null && day.isNotEmpty) {
              final parsedDay = int.tryParse(day) ?? 7;
              // 确保weekday在有效范围内（1-7），超出范围的统一放到周日
              weekday = (parsedDay >= 1 && parsedDay <= 7) ? parsedDay : 7;
              AppLogger.debug('实践课程day字段值: $day, 解析后weekday: $weekday');
            }

            // 创建课程对象
            final course = Course(
              id: item['cxbj']?.toString() ?? '',
              title: title,
              classroom: classroom,
              teacher: teacher,
              weekday: weekday,
              periods: [1, 2, 3], // 实践课默认安排在第1-3节
              weeks: weeks,
              kcxz: '实践', // 实践课程的性质
              kclb: item['kclb']?.toString(), // 课程类别
            );

            AppLogger.debug('解析实践课程: $title, 周次${weeks.join(",")}');

            // 添加到课表
            for (final week in weeks) {
              weekTable.putIfAbsent(week, () => <int, List<Course>>{});
              weekTable[week]!.putIfAbsent(weekday, () => <Course>[]);
              weekTable[week]![weekday]!.add(course);
            }
          } catch (e) {
            AppLogger.debug('解析实践课程失败: $e');
          }
        }
      }

      // 输出解析结果
      int totalCourses = 0;
      weekTable.forEach((week, dayMap) {
        dayMap.forEach((day, courses) {
          totalCourses += courses.length;
        });
      });
      AppLogger.debug('课表解析完成: ${weekTable.length}周, $totalCourses门课程');
    } catch (e, stackTrace) {
      AppLogger.debug('解析课表数据时发生异常: $e');
      AppLogger.debug('堆栈跟踪: $stackTrace');
    }

    return ClassTable(weekTable: weekTable, xnm: xnm, xqm: xqm);
  }

  /// 获取指定周次的课表数据
  Map<int, List<Course>>? getWeekSchedule(int week) {
    final schedule = weekTable[week];
    return schedule;
  }

  /// 获取全学期所有课程（扁平化结构）
  Map<int, List<Course>> getAllCourses() {
    final allCourses = <int, List<Course>>{};

    weekTable.forEach((week, weekdayMap) {
      weekdayMap.forEach((weekday, courses) {
        allCourses.putIfAbsent(weekday, () => []).addAll(courses);
      });
    });

    // 去重
    allCourses.forEach((weekday, courses) {
      final seen = <String>{};
      allCourses[weekday] = courses.where((course) {
        final key = '${course.id}-${course.start}-${course.end}';
        if (seen.contains(key)) return false;
        seen.add(key);
        return true;
      }).toList();
    });

    return allCourses;
  }

  /// 转换为JSON格式
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    weekTable.forEach((week, weekdayMap) {
      final weekJson = <String, dynamic>{};
      json['$week'] = weekJson;

      weekdayMap.forEach((weekday, courses) {
        weekJson['$weekday'] = courses
            .map((course) => course.toJson())
            .toList();
      });
    });

    return json;
  }

  /// 获取课表缓存键
  String get cacheKey => 'classTable-$xnm-$xqm';
}

int min(int a, int b) => a < b ? a : b;
