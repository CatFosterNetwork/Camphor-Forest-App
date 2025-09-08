// lib/pages/statistics/providers/statistics_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../models/statistics_model.dart';

// 单个课程统计提供者

// 课程统计参数类
class CourseStatisticsParams {
  final String courseId;
  final String? courseName;

  CourseStatisticsParams({required this.courseId, this.courseName});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseStatisticsParams &&
          runtimeType == other.runtimeType &&
          courseId == other.courseId &&
          courseName == other.courseName;

  @override
  int get hashCode => courseId.hashCode ^ courseName.hashCode;
}

// 新增：单个课程统计提供者
final courseStatisticsProvider =
    FutureProvider.family<CourseStatisticsData?, CourseStatisticsParams>((
      ref,
      params,
    ) async {
      final apiService = ref.read(apiServiceProvider);

      try {
        // 从API获取单个课程的统计数据
        final response = await apiService.getCourseStatistics(params.courseId);

        if (response['success'] == true && response['data'] != null) {
          final data = response['data'] as Map<String, dynamic>;
          return CourseStatisticsData.fromApi(
            courseId: params.courseId,
            courseName: params.courseName ?? '未知课程',
            apiData: data,
          );
        }

        return null;
      } catch (e) {
        print('Error getting course statistics for ${params.courseId}: $e');
        return null;
      }
    });

// 学期相关的Provider
// 学期信息类
class SemesterInfo {
  final String xnm; // 学年
  final String xqm; // 学期码
  final String displayName; // 显示名称

  SemesterInfo({
    required this.xnm,
    required this.xqm,
    required this.displayName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SemesterInfo &&
          runtimeType == other.runtimeType &&
          xnm == other.xnm &&
          xqm == other.xqm;

  @override
  int get hashCode => xnm.hashCode ^ xqm.hashCode;
}

// 参考微信小程序的逻辑：getCurrentXnmXqm
final selectedSemesterProvider = StateProvider<SemesterInfo>((ref) {
  final currentYear = DateTime.now().year;
  final currentMonth = DateTime.now().month;

  // 微信小程序逻辑：new Date().getMonth() < 7 ? "12" : "3"
  if (currentMonth < 7) {
    // 1-6月为春季学期，xqm=12，xnm=currentYear-1
    return SemesterInfo(
      xnm: '${currentYear - 1}',
      xqm: '12',
      displayName: '${currentYear}年春季学期',
    );
  } else {
    // 7-12月为秋季学期，xqm=3，xnm=currentYear
    return SemesterInfo(
      xnm: '$currentYear',
      xqm: '3',
      displayName: '$currentYear年秋季学期',
    );
  }
});

final availableSemestersProvider = Provider<List<SemesterInfo>>((ref) {
  final currentYear = DateTime.now().year;
  return [
    // 当前学年秋季学期
    SemesterInfo(
      xnm: '$currentYear',
      xqm: '3',
      displayName: '$currentYear年秋季学期',
    ),
    // 当前学年春季学期
    SemesterInfo(
      xnm: '${currentYear - 1}',
      xqm: '12',
      displayName: '${currentYear}年春季学期',
    ),
    // 上一学年秋季学期
    SemesterInfo(
      xnm: '${currentYear - 1}',
      xqm: '3',
      displayName: '${currentYear - 1}年秋季学期',
    ),
    // 上一学年春季学期
    SemesterInfo(
      xnm: '${currentYear - 2}',
      xqm: '12',
      displayName: '${currentYear - 1}年春季学期',
    ),
    // 前两学年秋季学期
    SemesterInfo(
      xnm: '${currentYear - 2}',
      xqm: '3',
      displayName: '${currentYear - 2}年秋季学期',
    ),
    // 前两学年春季学期
    SemesterInfo(
      xnm: '${currentYear - 3}',
      xqm: '12',
      displayName: '${currentYear - 2}年春季学期',
    ),
  ];
});

// 获取指定学期的课程列表
final semesterCoursesProvider = FutureProvider.family<List<CourseInfo>, SemesterInfo>((
  ref,
  semesterInfo,
) async {
  try {
    final apiService = ref.read(apiServiceProvider);

    // 直接使用学期信息中的xnm和xqm参数
    final xnm = semesterInfo.xnm;
    final xqm = semesterInfo.xqm;

    // 获取该学期的课表数据
    print('🔍 semesterCoursesProvider: 获取课表数据 xnm=$xnm, xqm=$xqm');
    final classTableResponse = await apiService.getClassTable(
      xnm: xnm,
      xqm: xqm,
    );

    // 获取成绩数据
    final gradesResponse = await apiService.getGrades();

    print('📊 课表API响应: ${classTableResponse['success']}');
    print('📊 成绩API响应: ${gradesResponse['success']}');

    if (!classTableResponse['success'] || !gradesResponse['success']) {
      print('❌ API调用失败');
      return [];
    }

    // 解析课表数据，提取课程列表
    final classTableData = classTableResponse['data'] as Map<String, dynamic>?;
    final gradesData = gradesResponse['data'] as List<dynamic>?;

    if (classTableData == null || gradesData == null) {
      print(
        '❌ 数据为空: classTableData=${classTableData != null}, gradesData=${gradesData != null}',
      );
      return [];
    }

    print('📚 成绩数据数量: ${gradesData.length}');
    print('📚 课表数据keys: ${classTableData.keys}');

    // 从课表和成绩中提取课程信息
    final Set<CourseInfo> courseSet = {};

    // 首先从成绩数据中提取该学期的课程
    int matchingGrades = 0;
    for (final grade in gradesData) {
      final gradeMap = grade as Map<String, dynamic>?;
      if (gradeMap == null) continue;

      final gradeXnm = gradeMap['xnm'] as String?;
      final gradeXqm = gradeMap['xqm'] as String?;
      final kch = gradeMap['kch'] as String?;
      final kcmc = gradeMap['kcmc'] as String?;

      print(
        '🔍 检查成绩: $kcmc, xnm=$gradeXnm, xqm=$gradeXqm (目标: xnm=$xnm, xqm=$xqm)',
      );

      // 只提取匹配当前学期的课程
      if (gradeXnm == xnm &&
          gradeXqm == xqm &&
          kch != null &&
          kch.isNotEmpty &&
          kcmc != null &&
          kcmc.isNotEmpty) {
        courseSet.add(CourseInfo(id: kch, name: kcmc));
        matchingGrades++;
        print('✅ 找到匹配课程: $kcmc (kch: $kch)');
      }
    }

    print('🎯 从成绩数据中找到 $matchingGrades 门课程');

    // 如果成绩数据中没有找到课程，再从课表数据中提取
    if (courseSet.isEmpty) {
      final List<Map<String, dynamic>> flatCourses = [];

      // 先将嵌套的课表数据扁平化
      for (final dayEntry in classTableData.entries) {
        final dayData = dayEntry.value as Map<String, dynamic>?;
        if (dayData == null) continue;

        for (final timeEntry in dayData.entries) {
          final timeData = timeEntry.value as Map<String, dynamic>?;
          if (timeData == null) continue;

          for (final courseEntry in timeData.entries) {
            final courseData = courseEntry.value as Map<String, dynamic>?;
            if (courseData == null) continue;

            flatCourses.add(courseData);
          }
        }
      }

      // 处理扁平化的课程数据
      for (final courseData in flatCourses) {
        String? kch = courseData['kch'] as String?;
        final kcmc = courseData['kcmc'] as String?;

        // 如果课表中没有kch，尝试从成绩数据中匹配
        if ((kch == null || kch.isEmpty) && kcmc != null) {
          for (final grade in gradesData) {
            final gradeMap = grade as Map<String, dynamic>?;
            if (gradeMap != null && gradeMap['kcmc'] == kcmc) {
              kch = gradeMap['kch'] as String?;
              break;
            }
          }
        }

        // 使用Map去重，只有有效的kch才添加
        if (kch != null && kch.isNotEmpty && kcmc != null && kcmc.isNotEmpty) {
          courseSet.add(CourseInfo(id: kch, name: kcmc));
        }
      }
    }

    return courseSet.toList()..sort((a, b) => a.name.compareTo(b.name));
  } catch (e) {
    print('Error getting semester courses: $e');
    return [];
  }
});

// 课程信息类
class CourseInfo {
  final String id;
  final String name;

  CourseInfo({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseInfo && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
