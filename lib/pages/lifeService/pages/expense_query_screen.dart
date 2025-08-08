// lib/pages/lifeService/pages/expense_query_screen.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/widgets/theme_aware_scaffold.dart';
import '../../../core/config/providers/theme_config_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_detail_card.dart';
import '../widgets/expense_bind_dialog.dart';

/// 水电费查询页面
class ExpenseQueryScreen extends ConsumerStatefulWidget {
  const ExpenseQueryScreen({super.key});

  @override
  ConsumerState<ExpenseQueryScreen> createState() => _ExpenseQueryScreenState();
}

class _ExpenseQueryScreenState extends ConsumerState<ExpenseQueryScreen> {
  @override
  void initState() {
    super.initState();
    // 确保数据已加载（使用缓存策略，避免重复请求）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(expenseProvider.notifier).initializeData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final themeColor = ref.watch(selectedCustomThemeProvider);
    final mainColor = themeColor?.colorList.isNotEmpty == true 
        ? themeColor!.colorList[0] 
        : Colors.blue;
    
    final expenseState = ref.watch(expenseProvider);
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;
    
    // 获取亚克力效果设置
    final useAcrylicEffect = themeColor?.indexMessageBoxBlur ?? false;

    return ThemeAwareScaffold(
      pageType: PageType.indexPage,
      useBackground: true,
      appBar: AppBar(
        title: Text(
          '水电费查询',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: textColor),
            onSelected: (value) {
              switch (value) {
                case 'refresh':
                  ref.read(expenseProvider.notifier).refreshExpenseData();
                  break;
                case 'rebind':
                  context.push('/lifeService/dormBind');
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh, color: mainColor, size: 20),
                    const SizedBox(width: 12),
                    const Text('刷新数据'),
                  ],
                ),
              ),
              if (expenseState.isBound)
                PopupMenuItem(
                  value: 'rebind',
                  child: Row(
                    children: [
                      Icon(Icons.edit_location, color: mainColor, size: 20),
                      const SizedBox(width: 12),
                      const Text('重新绑定'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(expenseProvider.notifier).refreshExpenseData(),
        color: mainColor,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          padding: const EdgeInsets.all(16),
          child: !expenseState.isBound && !expenseState.isLoading && expenseState.error == null
              ? SizedBox(
                  height: MediaQuery.of(context).size.height - 
                         MediaQuery.of(context).padding.top - 
                         kToolbarHeight - 32, // 减去状态栏、AppBar和padding
                  child: Center(
                    child: _buildUnboundCard(context, isDarkMode, mainColor, useAcrylicEffect: useAcrylicEffect),
                  ),
                )
              : Column(
                  children: [
                    // 状态处理
                    if (expenseState.isLoading) ...[
                      SizedBox(
                        height: MediaQuery.of(context).size.height - 
                               MediaQuery.of(context).padding.top - 
                               kToolbarHeight - 32,
                        child: Center(
                          child: _buildLoadingCard(isDarkMode, useAcrylicEffect: useAcrylicEffect),
                        ),
                      ),
                    ] else if (expenseState.error != null) ...[
                      SizedBox(
                        height: MediaQuery.of(context).size.height - 
                               MediaQuery.of(context).padding.top - 
                               kToolbarHeight - 32,
                        child: Center(
                          child: _buildErrorCard(expenseState.error!, isDarkMode, mainColor, useAcrylicEffect: useAcrylicEffect),
                        ),
                      ),
                    ] else ...[
                      // 余额总览卡片
                      if (expenseState.currentBalance != null)
                        ExpenseDetailCard(
                          title: '余额总览',
                          subtitle: '更新于 ${_formatUpdateTime(expenseState.lastUpdateTime)}',
                          useAcrylicEffect: useAcrylicEffect,
                          child: _buildBalanceOverview(expenseState, isDarkMode, textColor, subtitleColor, mainColor),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // 近期缴费记录
                      if (expenseState.paymentRecord != null)
                        ExpenseDetailCard(
                          title: '近期缴费记录',
                          subtitle: '缴费于 ${_formatUpdateTime(expenseState.paymentRecord!.paymentDate)}',
                          useAcrylicEffect: useAcrylicEffect,
                          child: _buildPaymentRecord(expenseState, isDarkMode, textColor, subtitleColor, mainColor),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // 近期消费流水
                      if (expenseState.balanceHistory.isNotEmpty)
                        ExpenseDetailCard(
                          title: '近期消费流水',
                          subtitle: '最近 30 天数据',
                          useAcrylicEffect: useAcrylicEffect,
                          child: _buildBalanceHistory(expenseState, isDarkMode, textColor, subtitleColor),
                        ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard(bool isDarkMode, {bool useAcrylicEffect = false}) {
    Widget cardContent = Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            '正在获取水电费信息...',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );

    if (useAcrylicEffect) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: isDarkMode ? Border.all(
                color: Colors.white.withAlpha(26),
                width: 1,
              ) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: cardContent,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: cardContent,
      );
    }
  }

  Widget _buildErrorCard(String error, bool isDarkMode, Color mainColor, {bool useAcrylicEffect = false}) {
    Widget cardContent = Column(
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: Colors.red,
        ),
        const SizedBox(height: 16),
        Text(
          '获取数据失败',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error,
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () => ref.read(expenseProvider.notifier).refreshExpenseData(),
          style: ElevatedButton.styleFrom(
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
          ),
          child: const Text('重试'),
        ),
      ],
    );

    if (useAcrylicEffect) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: isDarkMode ? Border.all(
                color: Colors.white.withAlpha(26),
                width: 1,
              ) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: cardContent,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: cardContent,
      );
    }
  }

  Widget _buildUnboundCard(BuildContext context, bool isDarkMode, Color mainColor, {bool useAcrylicEffect = false}) {
    Widget cardContent = Column(
      children: [
        Icon(
          Icons.home_outlined,
          size: 64,
          color: isDarkMode ? Colors.white54 : Colors.black54,
        ),
        const SizedBox(height: 16),
        Text(
          '未绑定宿舍',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '请先绑定您的宿舍信息以查看水电费',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _showBindDialog(context),
          icon: const Icon(Icons.add_home),
          label: const Text('绑定宿舍'),
          style: ElevatedButton.styleFrom(
            backgroundColor: mainColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );

    if (useAcrylicEffect) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: isDarkMode 
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: isDarkMode ? Border.all(
                color: Colors.white.withAlpha(26),
                width: 1,
              ) : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(26),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: cardContent,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: cardContent,
      );
    }
  }

  Widget _buildBalanceOverview(ExpenseState state, bool isDarkMode, Color textColor, Color subtitleColor, Color mainColor) {
    final balance = state.currentBalance!;
    
    return Column(
      children: [
        // 电表水表号信息
        Row(
          children: [
            Expanded(
              child: _buildInfoItem(
                '电表号',
                balance.electricityMeterNumber ?? '--',
                Icons.bolt,
                Colors.amber,
                subtitleColor,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInfoItem(
                '水表号',
                balance.waterMeterNumber ?? '--',
                Icons.water_drop,
                mainColor,
                subtitleColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        // 余额信息网格
        Row(
          children: [
            Expanded(
              child: _buildBalanceItem(
                '水电总余额',
                '${balance.currentRemainingAmount.toStringAsFixed(2)}元',
                textColor,
                subtitleColor,
                mainColor,
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBalanceItem(
                '当前已用',
                '${(balance.remainingAccountBalance - balance.currentRemainingAmount).toStringAsFixed(2)}元',
                textColor,
                subtitleColor,
                mainColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildBalanceItem(
                '电费费率',
                '${balance.electricityRate}元/度',
                textColor,
                subtitleColor,
                mainColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBalanceItem(
                '水费费率',
                '${balance.waterRate}元/吨',
                textColor,
                subtitleColor,
                mainColor,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildBalanceItem(
                '电补助余额',
                '${balance.availableElectricitySubsidy}度',
                textColor,
                subtitleColor,
                mainColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBalanceItem(
                '水补助余额',
                '${balance.availableWaterSubsidy}吨',
                textColor,
                subtitleColor,
                mainColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPaymentRecord(ExpenseState state, bool isDarkMode, Color textColor, Color subtitleColor, Color mainColor) {
    final payment = state.paymentRecord!;
    
    return Column(
      children: [
        // 流水号
        _buildInfoRow('流水号', payment.serialNumber, subtitleColor),
        
        const SizedBox(height: 16),
        
        // 缴费信息
        Row(
          children: [
            Expanded(
              child: _buildBalanceItem(
                '缴费前余额',
                '${payment.accountBalanceToday.toStringAsFixed(2)}元',
                textColor,
                subtitleColor,
                mainColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBalanceItem(
                '缴费金额',
                '${payment.paymentAmountThisTime.toStringAsFixed(2)}元',
                textColor,
                subtitleColor,
                mainColor,
                isPrimary: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildBalanceItem(
                '缴费后余额',
                '${payment.currentAccountBalance.toStringAsFixed(2)}元',
                textColor,
                subtitleColor,
                mainColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceHistory(ExpenseState state, bool isDarkMode, Color textColor, Color subtitleColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingTextStyle: TextStyle(
          color: subtitleColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        dataTextStyle: TextStyle(
          color: textColor,
          fontSize: 11,
        ),
        columnSpacing: 16,
        horizontalMargin: 0,
        columns: const [
          DataColumn(label: Text('日期')),
          DataColumn(label: Text('昨日剩余')),
          DataColumn(label: Text('今日剩余')),
          DataColumn(label: Text('电费')),
          DataColumn(label: Text('水费')),
          DataColumn(label: Text('总支出')),
        ],
        rows: state.balanceHistory.take(30).map((item) {
          return DataRow(
            cells: [
              DataCell(Text(_formatDate(item.settlementDate))),
              DataCell(Text(item.previousDayRemainingAmount.toStringAsFixed(2))),
              DataCell(Text(item.currentDayRemainingAmount.toStringAsFixed(2))),
              DataCell(Text(item.electricityFee.toStringAsFixed(2))),
              DataCell(Text(item.waterFee.toStringAsFixed(2))),
              DataCell(Text(item.totalAmount.toStringAsFixed(2))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoItem(String title, String value, IconData icon, Color iconColor, Color subtitleColor) {
    return Row(
      children: [
        Icon(icon, size: 16, color: iconColor),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: subtitleColor,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: subtitleColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBalanceItem(String title, String value, Color textColor, Color subtitleColor, Color mainColor, {bool isPrimary = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isPrimary 
            ? mainColor.withAlpha(26)
            : Colors.grey.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: isPrimary 
            ? Border.all(color: mainColor.withAlpha(76))
            : null,
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: subtitleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isPrimary ? mainColor : textColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String title, String value, Color subtitleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: subtitleColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  void _showBindDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ExpenseBindDialog(
        onBind: (buildingId, roomCode) async {
          await ref.read(expenseProvider.notifier).bindDormitory(buildingId, roomCode);
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  String _formatUpdateTime(DateTime? dateTime) {
    if (dateTime == null) return '未知';
    
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} 天前';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} 小时前';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} 分钟前';
    } else {
      return '刚刚';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}