// lib/pages/lifeService/providers/expense_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';
import '../models/expense_models.dart';
import '../models/dorm_config.dart';

/// 水电费状态
class ExpenseState {
  final bool isLoading;
  final String? error;
  final bool isBound;
  final ExpenseBalance? currentBalance;
  final ExpensePaymentRecord? paymentRecord;
  final List<ExpenseBalanceHistory> balanceHistory;
  final DateTime? lastUpdateTime;
  final DormInfo? currentDorm;
  final bool isFromCache; // 数据是否来自缓存

  const ExpenseState({
    this.isLoading = false,
    this.error,
    this.isBound = false,
    this.currentBalance,
    this.paymentRecord,
    this.balanceHistory = const [],
    this.lastUpdateTime,
    this.currentDorm,
    this.isFromCache = false,
  });

  ExpenseState copyWith({
    bool? isLoading,
    String? error,
    bool? isBound,
    ExpenseBalance? currentBalance,
    ExpensePaymentRecord? paymentRecord,
    List<ExpenseBalanceHistory>? balanceHistory,
    DateTime? lastUpdateTime,
    DormInfo? currentDorm,
    bool? isFromCache,
  }) {
    return ExpenseState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isBound: isBound ?? this.isBound,
      currentBalance: currentBalance ?? this.currentBalance,
      paymentRecord: paymentRecord ?? this.paymentRecord,
      balanceHistory: balanceHistory ?? this.balanceHistory,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
      currentDorm: currentDorm ?? this.currentDorm,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

/// 水电费状态管理
class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final Ref _ref;

  ExpenseNotifier(this._ref) : super(const ExpenseState()) {
    _loadCachedData();
  }

  /// 加载缓存数据
  void _loadCachedData() {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final buildingId = prefs.getString('buildingId');
      final roomCode = prefs.getString('roomCode');
      
      if (buildingId != null && roomCode != null) {
        final buildingIdInt = int.tryParse(buildingId);
        DormInfo? dormInfo;
        if (buildingIdInt != null) {
          dormInfo = DormConfig.findDormByBuildingId(buildingIdInt);
        }
        
        state = state.copyWith(
          isBound: true,
          currentDorm: dormInfo,
        );
        // 尝试加载缓存的水电费数据
        _loadExpenseFromCache();
      }
    } catch (e) {
      debugPrint('加载缓存数据失败: $e');
    }
  }

  /// 从缓存加载水电费数据
  void _loadExpenseFromCache() {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final expenseJson = prefs.getString('expense_data');
      final lastUpdate = prefs.getString('expense_last_update');
      
      if (expenseJson != null) {
        // 检查数据是否过期（超过12小时）
        DateTime? lastUpdateTime;
        if (lastUpdate != null) {
          lastUpdateTime = DateTime.tryParse(lastUpdate);
          if (lastUpdateTime != null && 
              DateTime.now().difference(lastUpdateTime).inHours < 12) {
            // 数据未过期，使用缓存数据
            _parseExpenseData(expenseJson, lastUpdateTime, isFromCache: true);
            return;
          }
        }
      }
      
      // 缓存数据不存在或已过期，刷新数据
      refreshExpenseData();
    } catch (e) {
      debugPrint('加载缓存水电费数据失败: $e');
      refreshExpenseData();
    }
  }

  /// 解析水电费数据
  void _parseExpenseData(String jsonData, DateTime updateTime, {bool isFromCache = true}) {
    try {
      // 解析JSON数据
      final data = json.decode(jsonData);
      
      // 使用与_parseApiData相同的逻辑来解析数据，但标记为缓存数据
      _parseApiData(data, updateTime, isFromCache: isFromCache);
    } catch (e) {
      debugPrint('解析缓存数据失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '数据解析失败: $e',
        isFromCache: false,
      );
    }
  }

  /// 刷新水电费数据
  Future<void> refreshExpenseData() async {
    if (!state.isBound) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final buildingId = prefs.getString('buildingId');
      final roomCode = prefs.getString('roomCode');

      if (buildingId == null || roomCode == null) {
        state = state.copyWith(
          isLoading: false,
          isBound: false,
          error: '宿舍信息不完整',
        );
        return;
      }

      // 调用API获取数据
      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.getElectricityExpense(buildingId, roomCode);

      // 解析API响应
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final now = DateTime.now();
        
        // 保存到缓存 - 将data转换为JSON字符串
        await prefs.setString('expense_data', json.encode(data));
        await prefs.setString('expense_last_update', now.toIso8601String());
        
        // 解析数据
        _parseApiData(data, now, isFromCache: false);
      } else {
        throw Exception(response['msg'] ?? '获取数据失败');
      }
    } catch (e) {
      debugPrint('刷新水电费数据失败: $e');
      
      // API请求失败时，尝试使用缓存数据（即使已过期）
      final prefs = _ref.read(sharedPreferencesProvider);
      final expenseJson = prefs.getString('expense_data');
      final lastUpdate = prefs.getString('expense_last_update');
      
      if (expenseJson != null && lastUpdate != null) {
        final lastUpdateTime = DateTime.tryParse(lastUpdate);
        if (lastUpdateTime != null) {
          try {
            debugPrint('API失败，使用缓存数据（${DateTime.now().difference(lastUpdateTime).inHours}小时前）');
            _parseExpenseData(expenseJson, lastUpdateTime, isFromCache: true);
            return;
          } catch (cacheError) {
            debugPrint('解析缓存数据也失败: $cacheError');
          }
        }
      }
      
      // 既没有缓存数据，API也失败了
      state = state.copyWith(
        isLoading: false,
        error: '网络请求失败，且无可用缓存数据: $e',
      );
    }
  }

  /// 解析API数据
  void _parseApiData(Map<String, dynamic> data, DateTime updateTime, {bool isFromCache = false}) {
    try {
      ExpenseBalance? balance;
      ExpensePaymentRecord? payment;
      List<ExpenseBalanceHistory> history = [];

      // 解析余额数据
      if (data['currentBalanceData'] != null) {
        final balanceData = data['currentBalanceData'];
        balance = ExpenseBalance(
          currentRemainingAmount: _parseDouble(balanceData['currentRemainingAmount']),
          remainingAccountBalance: _parseDouble(balanceData['remainingAccountBalance']),
          electricityRate: _parseDouble(balanceData['electricityRate']),
          waterRate: _parseDouble(balanceData['waterRate']),
          availableElectricitySubsidy: _parseDouble(balanceData['availableElectricitySubsidy']),
          availableWaterSubsidy: _parseDouble(balanceData['availableWaterSubsidy']),
          electricityMeterNumber: balanceData['electricityMeterNumber']?.toString(),
          waterMeterNumber: balanceData['waterMeterNumber']?.toString(),
        );
      }

      // 解析缴费记录
      if (data['paymentData'] != null) {
        final paymentData = data['paymentData'];
        payment = ExpensePaymentRecord(
          paymentDate: DateTime.tryParse(paymentData['paymentDate']?.toString() ?? '') ?? DateTime.now(),
          serialNumber: paymentData['serialNumber']?.toString() ?? '',
          accountBalanceToday: _parseDouble(paymentData['accountBalanceToday']),
          paymentAmountThisTime: _parseDouble(paymentData['paymentAmountThisTime']),
          currentAccountBalance: _parseDouble(paymentData['currentAccountBalance']),
        );
      }

      // 解析流水记录
      if (data['balanceData'] != null && data['balanceData'] is List) {
        history = (data['balanceData'] as List).map((item) {
          return ExpenseBalanceHistory(
            settlementDate: DateTime.tryParse(item['settlementDate']?.toString() ?? '') ?? DateTime.now(),
            previousDayRemainingAmount: _parseDouble(item['previousDayRemainingAmount']),
            currentDayRemainingAmount: _parseDouble(item['currentDayRemainingAmount']),
            electricityFee: _parseDouble(item['electricityFee']),
            waterFee: _parseDouble(item['waterFee']),
            todayPaymentAmount: _parseDouble(item['todayPaymentAmount']),
            totalAmount: _parseDouble(item['totalAmount']),
          );
        }).toList();
      }

      state = state.copyWith(
        isLoading: false,
        error: null,
        isBound: true,
        currentBalance: balance,
        paymentRecord: payment,
        balanceHistory: history,
        lastUpdateTime: updateTime,
        isFromCache: isFromCache,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '数据解析失败: $e',
        isFromCache: false,
      );
    }
  }

  /// 绑定宿舍
  Future<void> bindDormitory(String buildingId, String roomCode) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      debugPrint('开始绑定宿舍: buildingId=$buildingId, roomCode=$roomCode');
      
      // 保存绑定信息
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.setString('buildingId', buildingId);
      await prefs.setString('roomCode', roomCode);
      debugPrint('绑定信息已保存到SharedPreferences');

      // 解析宿舍信息
      final buildingIdInt = int.tryParse(buildingId);
      DormInfo? dormInfo;
      if (buildingIdInt != null) {
        dormInfo = DormConfig.findDormByBuildingId(buildingIdInt);
        debugPrint('解析宿舍信息: ${dormInfo?.toString()}');
      }

      // 更新绑定状态
      state = state.copyWith(
        isBound: true,
        currentDorm: dormInfo,
        isLoading: false, // 先设置为false，避免在数据获取时保持loading状态
      );
      debugPrint('绑定状态已更新');

      // 异步获取水电费数据，不阻塞绑定流程
      try {
        debugPrint('开始获取水电费数据');
        await refreshExpenseData();
        debugPrint('水电费数据获取完成');
      } catch (dataError) {
        debugPrint('获取水电费数据失败，但绑定已成功: $dataError');
        // 数据获取失败不影响绑定成功状态
        state = state.copyWith(
          isLoading: false,
          error: '绑定成功，但获取数据失败: $dataError',
        );
      }
    } catch (e) {
      debugPrint('绑定宿舍失败: $e');
      state = state.copyWith(
        isLoading: false,
        error: '绑定失败: $e',
        isBound: false, // 确保绑定失败时重置状态
      );
      rethrow; // 重新抛出异常，让UI层处理
    }
  }

  /// 解除绑定
  Future<void> unbindDormitory() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.remove('buildingId');
      await prefs.remove('roomCode');
      await prefs.remove('expense_data');
      await prefs.remove('expense_last_update');

      state = const ExpenseState();
    } catch (e) {
      state = state.copyWith(error: '解除绑定失败: $e');
    }
  }

  /// 初始化数据加载（使用缓存策略）
  void initializeData() {
    if (state.isBound && !state.isLoading && state.currentBalance == null && state.error == null) {
      // 只有在已绑定、未加载中、无数据、无错误的情况下才加载
      _loadExpenseFromCache();
    }
  }

  /// 清除缓存数据（用于测试）
  Future<void> clearCache() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      await prefs.remove('expense_data');
      await prefs.remove('expense_last_update');
      debugPrint('水电费缓存数据已清除');
    } catch (e) {
      debugPrint('清除缓存失败: $e');
    }
  }

  /// 解析数字字符串
  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      // 移除货币符号和单位
      final cleaned = value.replaceAll(RegExp(r'[￥元度吨]'), '').trim();
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }

  /// 获取简要数据（用于主页小组件）
  ExpenseBriefData? get briefData {
    try {
      // 安全检查：确保状态完整
      if (!state.isBound || state.currentBalance == null || state.isLoading) {
        debugPrint('briefData: 状态不完整，返回null - isBound: ${state.isBound}, hasBalance: ${state.currentBalance != null}, isLoading: ${state.isLoading}');
        return null;
      }
      
      final balance = state.currentBalance!;
      
      // 安全访问历史数据
      final historyList = state.balanceHistory;
      final todayHistory = historyList.isNotEmpty ? historyList.first : null;
      final yesterdayHistory = historyList.length > 1 ? historyList[1] : null;
      
      debugPrint('briefData: 创建简要数据 - balance: ${balance.currentRemainingAmount}, historyCount: ${historyList.length}');
      
      return ExpenseBriefData(
        currentBalance: balance.currentRemainingAmount,
        electricityFee: todayHistory?.electricityFee ?? 0.0,
        waterFee: todayHistory?.waterFee ?? 0.0,
        yesterdayTotal: yesterdayHistory?.totalAmount ?? 0.0,
        todayTotal: todayHistory?.totalAmount ?? 0.0,
        updateTime: state.lastUpdateTime,
      );
    } catch (e, stackTrace) {
      debugPrint('briefData error: $e');
      debugPrint('StackTrace: $stackTrace');
      return null; // 发生任何错误都返回null，避免崩溃
    }
  }
}

/// 水电费Provider
final expenseProvider = StateNotifierProvider<ExpenseNotifier, ExpenseState>((ref) {
  return ExpenseNotifier(ref);
});

/// 水电费简要数据Provider（用于主页小组件）
final expenseBriefProvider = Provider<ExpenseBriefData?>((ref) {
  final expenseState = ref.watch(expenseProvider);
  final expenseNotifier = ref.watch(expenseProvider.notifier);
  
  // 只有在关键状态变化时才重新计算
  if (!expenseState.isBound || expenseState.isLoading) {
    debugPrint('expenseBriefProvider: 状态未就绪，返回null');
    return null;
  }
  
  try {
    final briefData = expenseNotifier.briefData;
    debugPrint('expenseBriefProvider: 返回简要数据 - hasData: ${briefData != null}');
    return briefData;
  } catch (e) {
    debugPrint('expenseBriefProvider error: $e');
    return null;
  }
});