// lib/pages/lifeService/pages/dorm_bind_screen.dart

import 'package:flutter/material.dart';

import '../../../core/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:camphor_forest/core/services/toast_service.dart';
import '../../../core/widgets/theme_aware_scaffold.dart';
import '../../../core/config/providers/theme_config_provider.dart';
import '../providers/expense_provider.dart';
import '../widgets/expense_bind_dialog.dart';
import '../models/dorm_config.dart';
import '../../../core/providers/core_providers.dart';

/// 宿舍绑定页面
class DormBindScreen extends ConsumerStatefulWidget {
  const DormBindScreen({super.key});

  @override
  ConsumerState<DormBindScreen> createState() => _DormBindScreenState();
}

class _DormBindScreenState extends ConsumerState<DormBindScreen> {
  DormInfo? _currentDormInfo;
  String? _currentRoomCode;

  @override
  void initState() {
    super.initState();
    _loadCurrentDormInfo();
  }

  void _loadCurrentDormInfo() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      final buildingIdStr = prefs.getString('buildingId');
      final roomCode = prefs.getString('roomCode');

      if (buildingIdStr != null && roomCode != null) {
        final buildingId = int.tryParse(buildingIdStr);
        if (buildingId != null) {
          final dormInfo = DormConfig.findDormByBuildingId(buildingId);
          if (mounted) {
            setState(() {
              _currentDormInfo = dormInfo;
              _currentRoomCode = roomCode;
            });
          }
        }
      }
    } catch (e) {
      AppLogger.debug('加载当前宿舍信息失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final themeColor = ref.watch(selectedCustomThemeProvider);
    final mainColor = themeColor.colorList.isNotEmpty == true
        ? themeColor.colorList[0]
        : Colors.blue;

    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: false,
      appBar: AppBar(
        title: Text(
          '宿舍绑定',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前绑定信息卡片
            _buildCurrentBindCard(
              mainColor,
              textColor,
              subtitleColor,
              isDarkMode,
            ),

            const SizedBox(height: 24),

            // 重新绑定说明
            _buildInfoCard(mainColor, textColor, subtitleColor),

            const SizedBox(height: 32),

            // 操作按钮
            _buildActionButtons(context, mainColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBindCard(
    Color mainColor,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDarkMode ? 76 : 20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isDarkMode
            ? Border.all(color: Colors.white.withAlpha(26), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: mainColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.home, color: mainColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '当前绑定宿舍',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      '您的水电费查询宿舍信息',
                      style: TextStyle(fontSize: 14, color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 宿舍信息
          if (_currentDormInfo != null && _currentRoomCode != null) ...[
            _buildInfoRow('园区', _currentDormInfo!.area, mainColor),
            const SizedBox(height: 12),
            _buildInfoRow('楼栋', _currentDormInfo!.building, mainColor),
            const SizedBox(height: 12),
            _buildInfoRow('房间号', _currentRoomCode!, mainColor),
            const SizedBox(height: 12),
            _buildInfoRow(
              '楼栋ID',
              _currentDormInfo!.buildingId.toString(),
              mainColor,
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.home_outlined, size: 48, color: subtitleColor),
                    const SizedBox(height: 12),
                    Text(
                      '暂未绑定宿舍',
                      style: TextStyle(fontSize: 16, color: subtitleColor),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color mainColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mainColor.withAlpha(13),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: mainColor.withAlpha(51)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: mainColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: mainColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(Color mainColor, Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Text(
                '重新绑定说明',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoPoint('• 重新绑定后将清除当前的水电费缓存数据'),
          const SizedBox(height: 8),
          _buildInfoPoint('• 新绑定的宿舍信息将立即生效'),
          const SizedBox(height: 8),
          _buildInfoPoint('• 请确保新宿舍信息的准确性'),
          const SizedBox(height: 8),
          _buildInfoPoint('• 绑定过程中请保持网络连接'),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        color: Colors.orange.shade700,
        height: 1.4,
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Color mainColor) {
    return Column(
      children: [
        // 重新绑定按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showBindDialog(context),
            icon: const Icon(Icons.edit_location),
            label: Text(
              _currentDormInfo != null ? '重新绑定宿舍' : '绑定宿舍',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        if (_currentDormInfo != null) ...[
          const SizedBox(height: 12),

          // 解除绑定按钮
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () => _showUnbindConfirmation(context),
              icon: const Icon(Icons.link_off),
              label: const Text('解除绑定'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _showBindDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExpenseBindDialog(
        title: _currentDormInfo != null ? '重新绑定宿舍' : '绑定宿舍',
        initialDorm: _currentDormInfo,
        initialRoomCode: _currentRoomCode,
        onBind: (buildingId, roomCode) async {
          await ref
              .read(expenseProvider.notifier)
              .bindDormitory(buildingId, roomCode);
          _loadCurrentDormInfo();
        },
        onCancel: () {
          // 如果当前没有绑定宿舍，返回上一页
          if (_currentDormInfo == null) {
            context.pop();
          }
        },
      ),
    );
  }

  void _showUnbindConfirmation(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            const SizedBox(width: 12),
            Text(
              '解除绑定',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          '确定要解除当前宿舍绑定吗？\n\n解除后将无法查看水电费信息，且所有缓存数据将被清除。',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await ref.read(expenseProvider.notifier).unbindDormitory();
              _loadCurrentDormInfo();

              if (mounted) {
                ToastService.show(
                  '已解除宿舍绑定',
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('确定解除'),
          ),
        ],
      ),
    );
  }
}
