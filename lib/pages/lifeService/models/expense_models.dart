// lib/pages/lifeService/models/expense_models.dart

/// 水电费余额信息
class ExpenseBalance {
  final double currentRemainingAmount; // 当前剩余金额
  final double remainingAccountBalance; // 账户余额
  final double electricityRate; // 电费费率
  final double waterRate; // 水费费率
  final double availableElectricitySubsidy; // 可用电费补助
  final double availableWaterSubsidy; // 可用水费补助
  final String? electricityMeterNumber; // 电表号
  final String? waterMeterNumber; // 水表号

  const ExpenseBalance({
    required this.currentRemainingAmount,
    required this.remainingAccountBalance,
    required this.electricityRate,
    required this.waterRate,
    required this.availableElectricitySubsidy,
    required this.availableWaterSubsidy,
    this.electricityMeterNumber,
    this.waterMeterNumber,
  });

  factory ExpenseBalance.fromJson(Map<String, dynamic> json) {
    return ExpenseBalance(
      currentRemainingAmount: _parseDouble(json['currentRemainingAmount']),
      remainingAccountBalance: _parseDouble(json['remainingAccountBalance']),
      electricityRate: _parseDouble(json['electricityRate']),
      waterRate: _parseDouble(json['waterRate']),
      availableElectricitySubsidy: _parseDouble(
        json['availableElectricitySubsidy'],
      ),
      availableWaterSubsidy: _parseDouble(json['availableWaterSubsidy']),
      electricityMeterNumber: json['electricityMeterNumber']?.toString(),
      waterMeterNumber: json['waterMeterNumber']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentRemainingAmount': currentRemainingAmount,
      'remainingAccountBalance': remainingAccountBalance,
      'electricityRate': electricityRate,
      'waterRate': waterRate,
      'availableElectricitySubsidy': availableElectricitySubsidy,
      'availableWaterSubsidy': availableWaterSubsidy,
      'electricityMeterNumber': electricityMeterNumber,
      'waterMeterNumber': waterMeterNumber,
    };
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[￥元度吨]'), '').trim();
      return double.tryParse(cleaned) ?? 0.0;
    }
    return 0.0;
  }
}

/// 缴费记录
class ExpensePaymentRecord {
  final DateTime paymentDate; // 缴费日期
  final String serialNumber; // 流水号
  final double accountBalanceToday; // 缴费前余额
  final double paymentAmountThisTime; // 本次缴费金额
  final double currentAccountBalance; // 缴费后余额

  const ExpensePaymentRecord({
    required this.paymentDate,
    required this.serialNumber,
    required this.accountBalanceToday,
    required this.paymentAmountThisTime,
    required this.currentAccountBalance,
  });

  factory ExpensePaymentRecord.fromJson(Map<String, dynamic> json) {
    return ExpensePaymentRecord(
      paymentDate:
          DateTime.tryParse(json['paymentDate']?.toString() ?? '') ??
          DateTime.now(),
      serialNumber: json['serialNumber']?.toString() ?? '',
      accountBalanceToday: ExpenseBalance._parseDouble(
        json['accountBalanceToday'],
      ),
      paymentAmountThisTime: ExpenseBalance._parseDouble(
        json['paymentAmountThisTime'],
      ),
      currentAccountBalance: ExpenseBalance._parseDouble(
        json['currentAccountBalance'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'paymentDate': paymentDate.toIso8601String(),
      'serialNumber': serialNumber,
      'accountBalanceToday': accountBalanceToday,
      'paymentAmountThisTime': paymentAmountThisTime,
      'currentAccountBalance': currentAccountBalance,
    };
  }
}

/// 水电费流水记录
class ExpenseBalanceHistory {
  final DateTime settlementDate; // 结算日期
  final double previousDayRemainingAmount; // 上日剩余金额
  final double currentDayRemainingAmount; // 当日剩余金额
  final double electricityFee; // 当日电费
  final double waterFee; // 当日水费
  final double todayPaymentAmount; // 当日缴费金额
  final double totalAmount; // 当日总支出

  const ExpenseBalanceHistory({
    required this.settlementDate,
    required this.previousDayRemainingAmount,
    required this.currentDayRemainingAmount,
    required this.electricityFee,
    required this.waterFee,
    required this.todayPaymentAmount,
    required this.totalAmount,
  });

  factory ExpenseBalanceHistory.fromJson(Map<String, dynamic> json) {
    return ExpenseBalanceHistory(
      settlementDate:
          DateTime.tryParse(json['settlementDate']?.toString() ?? '') ??
          DateTime.now(),
      previousDayRemainingAmount: ExpenseBalance._parseDouble(
        json['previousDayRemainingAmount'],
      ),
      currentDayRemainingAmount: ExpenseBalance._parseDouble(
        json['currentDayRemainingAmount'],
      ),
      electricityFee: ExpenseBalance._parseDouble(json['electricityFee']),
      waterFee: ExpenseBalance._parseDouble(json['waterFee']),
      todayPaymentAmount: ExpenseBalance._parseDouble(
        json['todayPaymentAmount'],
      ),
      totalAmount: ExpenseBalance._parseDouble(json['totalAmount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'settlementDate': settlementDate.toIso8601String(),
      'previousDayRemainingAmount': previousDayRemainingAmount,
      'currentDayRemainingAmount': currentDayRemainingAmount,
      'electricityFee': electricityFee,
      'waterFee': waterFee,
      'todayPaymentAmount': todayPaymentAmount,
      'totalAmount': totalAmount,
    };
  }
}

/// 水电费简要数据（用于主页小组件）
class ExpenseBriefData {
  final double currentBalance; // 当前余额
  final double electricityFee; // 昨日电费
  final double waterFee; // 昨日水费
  final double yesterdayTotal; // 昨日总支出
  final double todayTotal; // 今日总支出
  final DateTime? updateTime; // 更新时间

  const ExpenseBriefData({
    required this.currentBalance,
    required this.electricityFee,
    required this.waterFee,
    required this.yesterdayTotal,
    required this.todayTotal,
    this.updateTime,
  });

  /// 获取与昨日对比的变化率
  double get changeRate {
    if (yesterdayTotal == 0) return 0.0;
    return (todayTotal - yesterdayTotal) / yesterdayTotal;
  }

  /// 获取对比文本
  String get compareText {
    if (changeRate == 0) return '与昨日持平';

    final percentage = (changeRate * 100).abs().toStringAsFixed(1);
    return changeRate > 0 ? '较昨日增长$percentage%' : '较昨日减少$percentage%';
  }

  /// 获取对比颜色
  bool get isIncrease => changeRate > 0;
}
