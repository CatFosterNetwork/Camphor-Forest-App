import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../../../core/providers/grade_provider.dart';
import '../repositories/class_table_repository.dart';
import '../repositories/api_class_table_repository.dart';
import '../models/class_table.dart';
import '../models/course.dart';
import '../models/custom_course_model.dart';
import 'classtable_settings_provider.dart';

/// Repository 提供器：依赖 ApiService + SharedPreferences
final classTableRepositoryProvider = Provider<ClassTableRepository>((ref) {
  final api = ref.watch(apiServiceProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return ApiClassTableRepository(api, prefs);
});

/// 基础课表数据 Provider
/// 使用 record 传参：({'xnm': '2024', 'xqm': '12'})
final _baseClassTableProvider =
    FutureProvider.family<ClassTable, ({String xnm, String xqm})>((
      ref,
      params,
    ) async {
      final repo = ref.watch(classTableRepositoryProvider);
      return await repo.loadLocal(params.xnm, params.xqm) ??
          await repo.fetchRemote(params.xnm, params.xqm);
    });

/// 强制从远程刷新课表数据的 Provider.
final forceRefreshClassTableProvider =
    FutureProvider.family<ClassTable, ({String xnm, String xqm})>((
      ref,
      params,
    ) async {
      final repo = ref.watch(classTableRepositoryProvider);
      final baseTable = await repo.fetchRemote(params.xnm, params.xqm);

      return await _enhanceClassTableWithGradeAndCustomData(
        ref,
        baseTable,
        params,
      );
    });

/// 增强课表数据 Provider
final classTableProvider =
    FutureProvider.family<ClassTable, ({String xnm, String xqm})>((
      ref,
      params,
    ) async {
      // 获取基础课表数据
      final baseTable = await ref.watch(_baseClassTableProvider(params).future);

      return await _enhanceClassTableWithGradeAndCustomData(
        ref,
        baseTable,
        params,
      );
    });

/// 提取公共的课表增强逻辑
Future<ClassTable> _enhanceClassTableWithGradeAndCustomData(
  FutureProviderRef<ClassTable> ref,
  ClassTable baseTable,
  ({String xnm, String xqm}) params,
) async {
  // 获取成绩数据用于补充课程属性
  final gradeState = ref.watch(gradeProvider);

  // 从成绩数据中提取课程属性
  final courseAttributesMap = <String, ({String? kcxz, String? kclb})>{};
  for (final detail in gradeState.gradeDetails) {
    if (detail.kch.isNotEmpty) {
      courseAttributesMap[detail.kch] = (
        kcxz: detail.ksxz != null && detail.ksxz!.isNotEmpty
            ? detail.ksxz
            : null,
        kclb: detail.xmblmc.isNotEmpty ? detail.xmblmc : null,
      );
    }
  }
  for (final summary in gradeState.gradeSummaries) {
    if (summary.kch.isNotEmpty) {
      courseAttributesMap[summary.kch] = (
        kcxz: summary.kcxzmc.isNotEmpty ? summary.kcxzmc : null,
        kclb: summary.kclbmc.isNotEmpty ? summary.kclbmc : null,
      );
    }
  }

  // 用成绩数据补充课表课程的属性
  final enhancedTableWithAttributes = _enhanceWithGradeAttributes(
    baseTable,
    courseAttributesMap,
  );

  // 获取当前学期的自定义课程
  final settings = ref.watch(classTableSettingsProvider);
  final customCourses = settings.customCourses
      .where((course) => course.xnm == params.xnm && course.xqm == params.xqm)
      .toList();

  // 如果没有自定义课程，返回已增强属性的课表
  if (customCourses.isEmpty) {
    return enhancedTableWithAttributes;
  }

  // 合并自定义课程到课表中
  final finalTable = _mergeCustomCourses(
    enhancedTableWithAttributes,
    customCourses,
  );
  return finalTable;
}

/// 用成绩数据增强课表课程的属性
ClassTable _enhanceWithGradeAttributes(
  ClassTable baseTable,
  Map<String, ({String? kcxz, String? kclb})> courseAttributesMap,
) {
  final enhancedWeekTable = <int, Map<int, List<Course>>>{};

  baseTable.weekTable.forEach((week, dayMap) {
    final enhancedDayMap = <int, List<Course>>{};
    enhancedWeekTable[week] = enhancedDayMap;

    dayMap.forEach((weekday, courses) {
      final enhancedCourses = courses.map((course) {
        // 如果课程已经有属性，保持不变
        if ((course.kcxz?.isNotEmpty == true) ||
            (course.kclb?.isNotEmpty == true)) {
          return course;
        }

        // 从成绩数据中查找对应的课程属性
        final attributes = courseAttributesMap[course.id];
        if (attributes != null) {
          return Course(
            id: course.id,
            title: course.title,
            classroom: course.classroom,
            teacher: course.teacher,
            weekday: course.weekday,
            periods: course.periods,
            weeks: course.weeks,
            isCustom: course.isCustom,
            courseType: course.courseType,
            kcxz: attributes.kcxz ?? course.kcxz,
            kclb: attributes.kclb ?? course.kclb,
          );
        }

        return course;
      }).toList();

      enhancedDayMap[weekday] = enhancedCourses;
    });
  });

  return ClassTable(
    weekTable: enhancedWeekTable,
    xnm: baseTable.xnm,
    xqm: baseTable.xqm,
  );
}

/// 将自定义课程合并到课表中
ClassTable _mergeCustomCourses(
  ClassTable baseTable,
  List<CustomCourse> customCourses,
) {
  final weekTable = Map<int, Map<int, List<Course>>>.from(baseTable.weekTable);

  for (final customCourse in customCourses) {
    // 将自定义课程转换为Course对象
    final periods = List.generate(
      customCourse.endTime - customCourse.startTime + 1,
      (index) => customCourse.startTime + index,
    );

    final course = Course(
      id: 'custom_${customCourse.id}',
      title: customCourse.title,
      teacher: customCourse.teacher ?? '',
      classroom: customCourse.classroom ?? '',
      weekday: customCourse.weekday,
      periods: periods,
      weeks: customCourse.weeks,
      isCustom: true, // 标记为自定义课程
      courseType: customCourse.courseType,
    );

    // 将自定义课程添加到对应的周次和星期
    for (final week in customCourse.weeks) {
      // 确保周次存在
      if (weekTable[week] == null) {
        weekTable[week] = <int, List<Course>>{};
      }

      // 确保星期存在
      if (weekTable[week]![customCourse.weekday] == null) {
        weekTable[week]![customCourse.weekday] = [];
      }

      // 添加课程
      weekTable[week]![customCourse.weekday]!.add(course);

      // 按时间排序
      weekTable[week]![customCourse.weekday]!.sort(
        (a, b) => a.start.compareTo(b.start),
      );
    }
  }

  return ClassTable(
    weekTable: weekTable,
    xnm: baseTable.xnm,
    xqm: baseTable.xqm,
  );
}
