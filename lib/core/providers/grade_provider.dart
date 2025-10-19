// lib/core/providers/grade_provider.dart

import 'dart:convert';

import '../../core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/grade_models.dart';
import '../services/api_service.dart';
import 'core_providers.dart';
import 'auth_provider.dart';

/// 成绩数据状态
class GradeState {
  final List<GradeDetail> gradeDetails;
  final List<GradeSummary> gradeSummaries;
  final List<CalculatedGrade> calculatedGrades;
  final List<SemesterInfo> availableSemesters;
  final SemesterInfo currentSemester;
  final GradeSortBy sortBy;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdateTime;
  final GradeStatistics? statistics;

  const GradeState({
    this.gradeDetails = const [],
    this.gradeSummaries = const [],
    this.calculatedGrades = const [],
    this.availableSemesters = const [],
    required this.currentSemester,
    this.sortBy = GradeSortBy.course,
    this.isLoading = false,
    this.error,
    this.lastUpdateTime,
    this.statistics,
  });

  GradeState copyWith({
    List<GradeDetail>? gradeDetails,
    List<GradeSummary>? gradeSummaries,
    List<CalculatedGrade>? calculatedGrades,
    List<SemesterInfo>? availableSemesters,
    SemesterInfo? currentSemester,
    GradeSortBy? sortBy,
    bool? isLoading,
    String? error,
    DateTime? lastUpdateTime,
    GradeStatistics? statistics,
  }) {
    return GradeState(
      gradeDetails: gradeDetails ?? this.gradeDetails,
      gradeSummaries: gradeSummaries ?? this.gradeSummaries,
      calculatedGrades: calculatedGrades ?? this.calculatedGrades,
      availableSemesters: availableSemesters ?? this.availableSemesters,
      currentSemester: currentSemester ?? this.currentSemester,
      sortBy: sortBy ?? this.sortBy,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      statistics: statistics ?? this.statistics,
    );
  }
}

/// 成绩Provider
class GradeNotifier extends StateNotifier<GradeState> {
  final ApiService _apiService;
  final FlutterSecureStorage _secureStorage;

  GradeNotifier(this._apiService, this._secureStorage)
    : super(
        GradeState(
          currentSemester: _getDefaultSemester(),
          availableSemesters: _generateAvailableSemesters(),
        ),
      ) {
    _loadFromStorage();
  }

  /// 获取默认学期（优先选择第二个学期）
  static SemesterInfo _getDefaultSemester() {
    final availableSemesters = _generateAvailableSemesters();

    // 如果有多个学期，默认选择第二个
    if (availableSemesters.length > 1) {
      AppLogger.debug('🎓 默认选择第二个学期: ${availableSemesters[1].displayName}');
      return availableSemesters[1];
    }

    // 否则选择第一个学期
    if (availableSemesters.isNotEmpty) {
      AppLogger.debug('🎓 默认选择第一个学期: ${availableSemesters[0].displayName}');
      return availableSemesters[0];
    }

    // 如果没有可用学期，回退到当前学期
    return SemesterInfo(
      xnm: getCurrentXnm(),
      xqm: getCurrentSemester(),
      displayName: _getSemesterDisplayName(
        getCurrentXnm(),
        getCurrentSemester(),
      ),
    );
  }

  /// 获取当前学期代码
  static String getCurrentSemester() {
    final month = DateTime.now().month;
    if (month >= 2 && month <= 7) {
      return '12'; // 春季学期
    } else {
      return '3'; // 秋季学期
    }
  }

  /// 获取当前学年代码
  static String getCurrentXnm() {
    final now = DateTime.now();
    final month = now.month;
    if (month >= 8) {
      return now.year.toString(); // 1-7月使用本年
    } else {
      // 8-12月
      return (now.year - 1).toString(); // 8-12月使用本年+1
    }
  }

  /// 获取学期显示名称
  static String _getSemesterDisplayName(String xnm, String xqm) {
    final year = xqm == '12' ? (int.parse(xnm) + 1).toString() : xnm;
    final season = xqm == '12'
        ? '春'
        : xqm == '3'
        ? '秋'
        : '夏';
    return '$year年$season季学期';
  }

  /// 从存储加载数据
  Future<void> _loadFromStorage() async {
    try {
      // 读取存储的成绩数据
      final gradeDetailsJson = await _secureStorage.read(key: 'grades');
      final gradeSummariesJson = await _secureStorage.read(
        key: 'gradesSummary',
      );
      final semesterJson = await _secureStorage.read(key: 'currentSemester');

      List<GradeDetail> gradeDetails = [];
      List<GradeSummary> gradeSummaries = [];
      SemesterInfo? currentSemester;

      if (gradeDetailsJson != null) {
        final List<dynamic> list = json.decode(gradeDetailsJson);
        gradeDetails = list.map((e) => GradeDetail.fromJson(e)).toList();
      }

      if (gradeSummariesJson != null) {
        final List<dynamic> list = json.decode(gradeSummariesJson);
        gradeSummaries = list.map((e) => GradeSummary.fromJson(e)).toList();
      }

      if (semesterJson != null) {
        final Map<String, dynamic> semesterData = json.decode(semesterJson);
        currentSemester = SemesterInfo(
          xnm: semesterData['xnm'],
          xqm: semesterData['xqm'],
          displayName: semesterData['displayName'],
        );
      }

      // 生成可用学期列表
      final availableSemesters = _generateAvailableSemesters();

      // 如果没有保存的学期选择，默认选择第二个学期（如果存在）
      if (currentSemester == null && availableSemesters.length > 1) {
        currentSemester = availableSemesters[1]; // 选择列表的第二个学期
        AppLogger.debug('🎓 使用默认学期（第二个）: ${currentSemester.displayName}');
      }

      // 计算当前学期成绩
      final calculatedGrades = _calculateCurrentSemesterGrades(
        gradeDetails,
        gradeSummaries,
        currentSemester ?? state.currentSemester,
      );

      // 计算统计信息
      final statistics = _calculateStatistics(gradeSummaries);

      state = state.copyWith(
        gradeDetails: gradeDetails,
        gradeSummaries: gradeSummaries,
        calculatedGrades: calculatedGrades,
        availableSemesters: availableSemesters,
        currentSemester: currentSemester ?? state.currentSemester,
        statistics: statistics,
        lastUpdateTime: DateTime.now(),
      );
    } catch (e) {
      AppLogger.debug('加载成绩数据失败: $e');
    }
  }

  /// 生成可用学期列表
  static List<SemesterInfo> _generateAvailableSemesters() {
    final List<SemesterInfo> semesters = [];
    final currentYear = DateTime.now().year;

    // 生成近4年的学期
    for (int year = currentYear - 3; year <= currentYear; year++) {
      // 秋季学期：xqm=3，xnm=year
      semesters.add(
        SemesterInfo(xnm: year.toString(), xqm: '3', displayName: '$year年秋季学期'),
      );
      // 春季学期：xqm=12，xnm=year-1
      semesters.add(
        SemesterInfo(
          xnm: (year - 1).toString(),
          xqm: '12',
          displayName: '$year年春季学期',
        ),
      );
    }

    return semesters.reversed.toList();
  }

  /// 刷新成绩数据
  Future<void> refreshGrades() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final res = await _apiService.getGrades();

      // 处理API返回的数据
      List<GradeDetail> gradeDetails = [];
      List<GradeSummary> gradeSummaries = [];

      // 根据实际API结构处理数据
      // API返回格式: {"success": true, "data": {"detail": {"items": [...]}, "summary": {"items": [...]}}}
      List<Map<String, dynamic>> summaryItems = [];
      List<Map<String, dynamic>> detailItems = [];

      final data = res['data'];
      if (data is Map<String, dynamic>) {
        // 处理汇总数据
        final summary = data['summary'];
        if (summary is Map<String, dynamic>) {
          final items = summary['items'];
          if (items is List) {
            summaryItems = items.cast<Map<String, dynamic>>();
          }
        }

        // 处理详情数据
        List<Map<String, dynamic>>? detailData;

        // 方式1: data.detail.items
        final detail = data['detail'];
        if (detail is Map<String, dynamic>) {
          final items = detail['items'];
          if (items is List) {
            detailData = items.cast<Map<String, dynamic>>();
          }
        }

        // 方式2: data.items（微信版本normal.vue中的方式）
        if (detailData == null || detailData.isEmpty) {
          final items = data['items'];
          if (items is List) {
            detailData = items.cast<Map<String, dynamic>>();
          }
        }

        // 方式3: 如果详情数据为空，使用汇总数据作为详情数据
        if (detailData == null || detailData.isEmpty) {
          if (summaryItems.isNotEmpty) {
            detailData = summaryItems;
            AppLogger.debug('🎓 使用汇总数据作为详情数据，条数: ${detailData.length}');
          }
        }

        detailItems = detailData ?? [];
      }

      // 获取已存储的成绩汇总数据用于比较
      final existingSummariesJson = await _secureStorage.read(
        key: 'gradesSummary',
      );
      List<GradeSummary> existingSummaries = [];
      if (existingSummariesJson != null) {
        final List<dynamic> list = json.decode(existingSummariesJson);
        existingSummaries = list.map((e) => GradeSummary.fromJson(e)).toList();
      }

      final today = DateTime.now().toIso8601String().split(
        'T',
      )[0]; // 格式: YYYY-MM-DD

      // 处理成绩汇总数据，检测新成绩并设置获取日期
      AppLogger.debug('🎓 解析成绩汇总数据，条数: ${summaryItems.length}');
      for (final item in summaryItems) {
        try {
          final newGrade = GradeSummary.fromJson(item);

          // 如果是首次获取成绩（没有已存储的成绩），所有成绩都标记为今天获取
          if (existingSummaries.isEmpty) {
            gradeSummaries.add(newGrade.copyWith(fetchDate: today));
          } else {
            // 检查是否为新成绩（在已有成绩中找不到相同的成绩）
            final existingGrade = existingSummaries.firstWhere(
              (existing) =>
                  existing.kchId == newGrade.kchId &&
                  existing.cj == newGrade.cj &&
                  existing.ksxz == newGrade.ksxz,
              orElse: () => GradeSummary(
                bfzcj: '',
                bh: '',
                bhId: '',
                bj: '',
                cj: '',
                cjsfzf: '',
                date: '',
                dateDigit: '',
                dateDigitSeparator: '',
                day: '',
                jd: '',
                jgId: '',
                jgmc: '',
                jgpxzd: '',
                jsxm: '',
                jxbId: '',
                jxbmc: '',
                kcbj: '',
                kch: '',
                kchId: '',
                kclbmc: '',
                kcmc: '',
                kcxzdm: '',
                kcxzmc: '',
                key: '',
                kkbmmc: '',
                kklxdm: '',
                ksxz: '',
                ksxzdm: '',
                listnav: '',
                localeKey: '',
                month: '',
                njdmId: '',
                njmc: '',
                pageTotal: 0,
                pageable: false,
                queryModel: {},
                queryTime: '',
                rangeable: false,
                rowId: '',
                rwzxs: '',
                sfdkbcx: '',
                sfkj: '',
                sfpk: '',
                sfxwkc: '',
                sfzh: '',
                sfzx: '',
                tjrxm: '',
                tjsj: '',
                totalResult: '',
                userModel: {},
                xb: '',
                xbm: '',
                xf: '',
                xfjd: '',
                xh: '',
                xhId: '',
                xm: '',
                xnm: '',
                xnmmc: '',
                xqm: '',
                xqmmc: '',
                xsbjmc: '',
                xslb: '',
                xz: '',
                year: '',
                zsxymc: '',
                zxs: '',
                zyhId: '',
                zymc: '',
                fetchDate: null,
              ),
            );

            if (existingGrade.kchId.isEmpty) {
              // 新成绩，设置获取日期为今天
              gradeSummaries.add(newGrade.copyWith(fetchDate: today));
            } else {
              // 已有成绩，保持原有的获取日期
              gradeSummaries.add(
                newGrade.copyWith(fetchDate: existingGrade.fetchDate),
              );
            }
          }
        } catch (e) {
          AppLogger.debug('解析成绩汇总数据失败: $e');
          AppLogger.debug('原始数据: $item');
        }
      }

      // 处理成绩详情数据
      AppLogger.debug('🎓 解析成绩详情数据，条数: ${detailItems.length}');
      for (final item in detailItems) {
        try {
          gradeDetails.add(GradeDetail.fromJson(item));
        } catch (e) {
          AppLogger.debug('解析成绩详情数据失败: $e');
          AppLogger.debug('原始数据: $item');
        }
      }

      // 保存处理后的数据（包含fetchDate）
      if (detailItems.isNotEmpty) {
        await _secureStorage.write(
          key: 'grades',
          value: json.encode(detailItems),
        );
      }
      if (gradeSummaries.isNotEmpty) {
        // 将处理后的GradeSummary转换为JSON格式保存
        final summaryJsonList = gradeSummaries
            .map(
              (summary) => {
                'bfzcj': summary.bfzcj,
                'bh': summary.bh,
                'bh_id': summary.bhId,
                'bj': summary.bj,
                'cj': summary.cj,
                'cjsfzf': summary.cjsfzf,
                'date': summary.date,
                'dateDigit': summary.dateDigit,
                'dateDigitSeparator': summary.dateDigitSeparator,
                'day': summary.day,
                'jd': summary.jd,
                'jg_id': summary.jgId,
                'jgmc': summary.jgmc,
                'jgpxzd': summary.jgpxzd,
                'jsxm': summary.jsxm,
                'jxb_id': summary.jxbId,
                'jxbmc': summary.jxbmc,
                'kcbj': summary.kcbj,
                'kch': summary.kch,
                'kch_id': summary.kchId,
                'kclbmc': summary.kclbmc,
                'kcmc': summary.kcmc,
                'kcxzdm': summary.kcxzdm,
                'kcxzmc': summary.kcxzmc,
                'key': summary.key,
                'kkbmmc': summary.kkbmmc,
                'kklxdm': summary.kklxdm,
                'ksxz': summary.ksxz,
                'ksxzdm': summary.ksxzdm,
                'listnav': summary.listnav,
                'localeKey': summary.localeKey,
                'month': summary.month,
                'njdm_id': summary.njdmId,
                'njmc': summary.njmc,
                'pageTotal': summary.pageTotal,
                'pageable': summary.pageable,
                'queryModel': summary.queryModel,
                'queryTime': summary.queryTime,
                'rangeable': summary.rangeable,
                'row_id': summary.rowId,
                'rwzxs': summary.rwzxs,
                'sfdkbcx': summary.sfdkbcx,
                'sfkj': summary.sfkj,
                'sfpk': summary.sfpk,
                'sfxwkc': summary.sfxwkc,
                'sfzh': summary.sfzh,
                'sfzx': summary.sfzx,
                'tjrxm': summary.tjrxm,
                'tjsj': summary.tjsj,
                'totalResult': summary.totalResult,
                'userModel': summary.userModel,
                'xb': summary.xb,
                'xbm': summary.xbm,
                'xf': summary.xf,
                'xfjd': summary.xfjd,
                'xh': summary.xh,
                'xh_id': summary.xhId,
                'xm': summary.xm,
                'xnm': summary.xnm,
                'xnmmc': summary.xnmmc,
                'xqm': summary.xqm,
                'xqmmc': summary.xqmmc,
                'xsbjmc': summary.xsbjmc,
                'xslb': summary.xslb,
                'xz': summary.xz,
                'year': summary.year,
                'zsxymc': summary.zsxymc,
                'zxs': summary.zxs,
                'zyh_id': summary.zyhId,
                'zymc': summary.zymc,
                'fetchDate': summary.fetchDate,
              },
            )
            .toList();

        await _secureStorage.write(
          key: 'gradesSummary',
          value: json.encode(summaryJsonList),
        );
      }

      // 计算当前学期成绩
      AppLogger.debug('🎓 计算当前学期成绩，学期: ${state.currentSemester.displayName}');
      AppLogger.debug('🎓 成绩详情数据: ${gradeDetails.length} 条');
      AppLogger.debug('🎓 成绩汇总数据: ${gradeSummaries.length} 条');

      final calculatedGrades = _calculateCurrentSemesterGrades(
        gradeDetails,
        gradeSummaries,
        state.currentSemester,
      );

      AppLogger.debug('🎓 计算得到 ${calculatedGrades.length} 条成绩');

      // 计算统计信息
      final statistics = _calculateStatistics(gradeSummaries);

      state = state.copyWith(
        gradeDetails: gradeDetails,
        gradeSummaries: gradeSummaries,
        calculatedGrades: calculatedGrades,
        statistics: statistics,
        isLoading: false,
        lastUpdateTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 切换学期
  void changeSemester(SemesterInfo semester) {
    if (semester.xnm == state.currentSemester.xnm &&
        semester.xqm == state.currentSemester.xqm) {
      return;
    }

    // 保存当前学期到存储
    _secureStorage.write(
      key: 'currentSemester',
      value: json.encode({
        'xnm': semester.xnm,
        'xqm': semester.xqm,
        'displayName': semester.displayName,
      }),
    );

    // 重新计算当前学期成绩
    final calculatedGrades = _calculateCurrentSemesterGrades(
      state.gradeDetails,
      state.gradeSummaries,
      semester,
    );

    state = state.copyWith(
      currentSemester: semester,
      calculatedGrades: calculatedGrades,
    );
  }

  /// 改变排序方式
  void changeSortBy(GradeSortBy sortBy) {
    if (sortBy == state.sortBy) return;

    state = state.copyWith(sortBy: sortBy);
  }

  /// 清理成绩数据（退出登录时调用）
  Future<void> clearGrades() async {
    AppLogger.debug('🎓 清理成绩数据');

    // 清理存储中的数据
    await Future.wait([
      _secureStorage.delete(key: 'grades'),
      _secureStorage.delete(key: 'gradesSummary'),
      _secureStorage.delete(key: 'currentSemester'),
    ]);

    // 重置状态到初始状态，但保留可用学期列表
    final availableSemesters = _generateAvailableSemesters();
    state = GradeState(
      currentSemester: SemesterInfo(
        xnm: getCurrentXnm(),
        xqm: getCurrentSemester(),
        displayName: _getSemesterDisplayName(
          getCurrentXnm(),
          getCurrentSemester(),
        ),
      ),
      availableSemesters: availableSemesters,
    );
  }

  /// 计算当前学期成绩
  List<CalculatedGrade> _calculateCurrentSemesterGrades(
    List<GradeDetail> gradeDetails,
    List<GradeSummary> gradeSummaries,
    SemesterInfo semester,
  ) {
    AppLogger.debug(
      '🎓 开始计算学期成绩，目标学期: ${semester.xnm}-${semester.xqm} (${semester.displayName})',
    );
    final Map<String, CalculatedGrade> gradeMap = {};

    // 主要从gradeSummaries构建成绩，因为API主要返回summary数据
    int matchedCount = 0;
    for (final summary in gradeSummaries) {
      AppLogger.debug(
        '🎓 检查成绩: ${summary.kcmc} (${summary.xnm}-${summary.xqm})',
      );
      if (summary.xnm == semester.xnm && summary.xqm == semester.xqm) {
        matchedCount++;
        AppLogger.debug('🎓 学期匹配: ${summary.kcmc}, 成绩: ${summary.bfzcj}');

        // 过滤掉缓考的成绩
        if (summary.cj == '缓考') {
          AppLogger.debug('🎓 跳过缓考成绩: ${summary.kcmc}');
          continue;
        }

        final jd = _calculateGPA(
          summary.bfzcj,
          double.tryParse(summary.xf) ?? 0,
        );

        gradeMap[summary.kchId] = CalculatedGrade(
          kcmc: summary.kcmc,
          kch: summary.kch,
          kchId: summary.kchId,
          xf: summary.xf,
          zcj: summary.bfzcj, // 使用百分制成绩
          jd: jd.toStringAsFixed(2),
          teacher: summary.jsxm,
          kcxzmc: summary.kcxzmc,
          kclbmc: summary.kclbmc,
          ksxz: summary.ksxz,
        );
      }
    }

    AppLogger.debug('🎓 匹配到 $matchedCount 条该学期成绩，生成 ${gradeMap.length} 条有效成绩');

    // 如果没有匹配的成绩，尝试显示所有学期的成绩供调试
    if (matchedCount == 0 && gradeSummaries.isNotEmpty) {
      AppLogger.debug('🎓 调试：可用的学期数据：');
      final availableTerms = gradeSummaries
          .map((s) => '${s.xnm}-${s.xqm}')
          .toSet();
      for (final term in availableTerms) {
        AppLogger.debug('🎓   - $term');
      }
    }

    // 将gradeMap转换为列表并排序
    final result = gradeMap.values.toList();
    return _sortGrades(result, state.sortBy);
  }

  /// 计算GPA
  double _calculateGPA(String score, double credits) {
    // 处理等级成绩
    final gradeMap = {
      '优': 4.6,
      'A': 4.6,
      '良': 3.6,
      'B': 3.6,
      '中': 2.6,
      'C': 2.6,
      '及格': 1.6,
      'D': 1.6,
      '不及格': 0.0,
      'E': 0.0,
    };

    if (gradeMap.containsKey(score)) {
      return gradeMap[score]! * credits;
    }

    // 处理数字成绩
    final numScore = double.tryParse(score);
    if (numScore == null || numScore < 60) return 0.0;
    if (numScore == 60) return 1.0 * credits;

    // 计算绩点
    final gpaRanges = [
      [62, 1.2],
      [64, 1.4],
      [66, 1.6],
      [68, 1.8],
      [71, 2.0],
      [74, 2.3],
      [77, 2.6],
      [80, 3.0],
      [83, 3.3],
      [86, 3.6],
      [89, 4.0],
      [92, 4.3],
      [95, 4.6],
      [98, 4.8],
      [100, 5.0],
    ];

    for (final range in gpaRanges) {
      if (numScore <= range[0]) {
        return range[1] * credits;
      }
    }

    return 0.0;
  }

  /// 排序成绩
  List<CalculatedGrade> _sortGrades(
    List<CalculatedGrade> grades,
    GradeSortBy sortBy,
  ) {
    final List<CalculatedGrade> sortedGrades = List.from(grades);

    switch (sortBy) {
      case GradeSortBy.course:
        sortedGrades.sort((a, b) => b.kchId.compareTo(a.kchId));
        break;
      case GradeSortBy.credit:
        sortedGrades.sort(
          (a, b) => double.parse(b.xf).compareTo(double.parse(a.xf)),
        );
        break;
      case GradeSortBy.score:
        sortedGrades.sort((a, b) => _compareScore(b.zcj, a.zcj));
        break;
      case GradeSortBy.gpa:
        sortedGrades.sort(
          (a, b) => double.parse(b.jd).compareTo(double.parse(a.jd)),
        );
        break;
    }

    return sortedGrades;
  }

  /// 比较成绩
  int _compareScore(dynamic a, dynamic b) {
    final numA = _getNumericScore(a);
    final numB = _getNumericScore(b);
    return numA.compareTo(numB);
  }

  /// 获取数字形式的成绩
  double _getNumericScore(dynamic score) {
    if (score is num) return score.toDouble();

    final gradeMap = {
      '优': 95.0,
      'A': 95.0,
      '良': 85.0,
      'B': 85.0,
      '中': 75.0,
      'C': 75.0,
      '及格': 65.0,
      'D': 65.0,
      '不及格': 55.0,
      'E': 55.0,
    };

    if (gradeMap.containsKey(score)) {
      return gradeMap[score]!;
    }

    return double.tryParse(score.toString()) ?? 0.0;
  }

  /// 计算统计信息
  GradeStatistics _calculateStatistics(List<GradeSummary> gradeSummaries) {
    double totalComGrade = 0;
    double totalComCredits = 0;
    double compulsoryGpa = 0;
    final Set<String> compulsoryKch = {};

    double totalAllGrade = 0;
    double totalAllCredits = 0;
    double totalGpa = 0;
    final Map<String, GradeSummary> bestGrades = {};

    // 找出每门课的最佳成绩
    for (final grade in gradeSummaries) {
      final score = double.tryParse(grade.bfzcj);
      final credit = double.tryParse(grade.xf);

      if (score == null || credit == null || grade.cj == '缓考') continue;

      final existing = bestGrades[grade.kch];
      if (existing == null || score > (double.tryParse(existing.bfzcj) ?? 0)) {
        bestGrades[grade.kch] = grade;
      }
    }

    // 计算必修课平均分和GPA
    for (final grade in gradeSummaries) {
      final score = double.tryParse(grade.bfzcj);
      final credit = double.tryParse(grade.xf);

      if (score == null || credit == null || grade.cj == '缓考') continue;

      // 必修课统计（只统计每门课一次）
      if (grade.kcxzmc.contains('必') && !compulsoryKch.contains(grade.kch)) {
        totalComGrade += score * credit;
        totalComCredits += credit;
        compulsoryGpa += _calculateGPA(grade.bfzcj, credit);
        compulsoryKch.add(grade.kch);
      }
    }

    // 计算全科平均分和GPA（使用最佳成绩）
    for (final grade in bestGrades.values) {
      final score = double.tryParse(grade.bfzcj);
      final credit = double.tryParse(grade.xf);

      if (score != null && credit != null) {
        totalAllGrade += score * credit;
        totalAllCredits += credit;
        totalGpa += _calculateGPA(grade.bfzcj, credit);
      }
    }

    return GradeStatistics(
      compulsoryAverage: totalComCredits > 0
          ? totalComGrade / totalComCredits
          : 0,
      totalAverage: totalAllCredits > 0 ? totalAllGrade / totalAllCredits : 0,
      compulsoryGpa: totalComCredits > 0 ? compulsoryGpa / totalComCredits : 0,
      totalGpa: totalAllCredits > 0 ? totalGpa / totalAllCredits : 0,
      totalCredits: totalAllCredits.round(),
      compulsoryCredits: totalComCredits.round(),
    );
  }

  /// 获取课程详情
  GradeDetail? getCourseDetail(String kchId) {
    final details = state.gradeDetails
        .where((detail) => detail.kchId == kchId)
        .toList();
    return details.isEmpty ? null : details.first;
  }

  /// 获取课程的所有考试记录
  List<GradeDetail> getCourseExamHistory(String kchId) {
    return state.gradeDetails.where((detail) => detail.kchId == kchId).toList();
  }
}

/// 成绩Provider - 监听认证状态变化
final gradeProvider = StateNotifierProvider<GradeNotifier, GradeState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final secureStorage = ref.read(secureStorageProvider);
  final notifier = GradeNotifier(apiService, secureStorage);

  // 监听认证状态变化
  ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
    AppLogger.debug('🎓 GradeProvider: 认证状态变化 $previous -> $next');
    if (previous == false && next == true) {
      // 登录后自动刷新成绩数据
      AppLogger.debug('🎓 用户登录，开始刷新成绩数据');
      Future.microtask(() => notifier.refreshGrades());
    } else if (previous == true && next == false) {
      // 注销后清理成绩数据
      AppLogger.debug('🎓 用户注销，清理成绩数据');
      notifier.clearGrades();
    }
  });

  return notifier;
});

/// 排序后的成绩列表
final sortedGradesProvider = Provider<List<CalculatedGrade>>((ref) {
  final state = ref.watch(gradeProvider);
  final grades = List<CalculatedGrade>.from(state.calculatedGrades);

  // 根据排序方式排序
  switch (state.sortBy) {
    case GradeSortBy.course:
      grades.sort((a, b) => a.kcmc.compareTo(b.kcmc));
      break;
    case GradeSortBy.credit:
      grades.sort((a, b) {
        final creditA = double.tryParse(a.xf) ?? 0;
        final creditB = double.tryParse(b.xf) ?? 0;
        return creditB.compareTo(creditA); // 降序
      });
      break;
    case GradeSortBy.score:
      grades.sort((a, b) {
        final scoreA = double.tryParse(a.zcj.toString()) ?? 0;
        final scoreB = double.tryParse(b.zcj.toString()) ?? 0;
        return scoreB.compareTo(scoreA); // 降序
      });
      break;
    case GradeSortBy.gpa:
      grades.sort((a, b) {
        final gpaA = double.tryParse(a.jd) ?? 0;
        final gpaB = double.tryParse(b.jd) ?? 0;
        return gpaB.compareTo(gpaA); // 降序
      });
      break;
  }

  return grades;
});

/// 成绩统计信息
final gradeStatisticsProvider = Provider<GradeStatistics?>((ref) {
  final state = ref.watch(gradeProvider);
  return state.statistics;
});

/// 当前学期信息
final currentSemesterProvider = Provider<SemesterInfo>((ref) {
  final state = ref.watch(gradeProvider);
  return state.currentSemester;
});

/// 可用学期列表
final availableSemestersProvider = Provider<List<SemesterInfo>>((ref) {
  final state = ref.watch(gradeProvider);
  return state.availableSemesters;
});

/// 排序后的可用学期列表（按年份降序，秋季在春季前）
final sortedAvailableSemestersProvider = Provider<List<SemesterInfo>>((ref) {
  final semesters = ref.watch(availableSemestersProvider);

  // 创建一个副本进行排序，避免修改原始列表
  final sortedSemesters = List<SemesterInfo>.from(semesters);

  sortedSemesters.sort((a, b) {
    // 首先按学年排序（较新的年份在前）
    final yearComparison = b.xnm.compareTo(a.xnm);
    if (yearComparison != 0) {
      return yearComparison;
    }

    // 同一学年内，秋季学期（3）在春季学期（12）前
    // 注意：xqm为"3"代表秋季，"12"代表春季
    return a.xqm.compareTo(b.xqm);
  });

  return sortedSemesters;
});

/// 新成绩检测Provider
final hasNewGradesProvider = Provider<bool>((ref) {
  final state = ref.watch(gradeProvider);
  final today = DateTime.now().toIso8601String().split(
    'T',
  )[0]; // 格式: YYYY-MM-DD

  // 检查是否有当天获取的新成绩
  final todayNewGrades = state.gradeSummaries
      .where((grade) => grade.fetchDate == today)
      .toList();

  // 检查是否为首次获取成绩（所有成绩的获取日期都是同一天）
  final allFetchDates = state.gradeSummaries
      .map((grade) => grade.fetchDate)
      .where((date) => date != null)
      .toSet();
  final isFirstTime = allFetchDates.length <= 1;

  // 只有在非首次获取且有当天新成绩时才显示新成绩标记
  return todayNewGrades.isNotEmpty && !isFirstTime;
});
