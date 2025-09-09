// lib/pages/lifeService/widgets/expense_bind_dialog.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/providers/theme_config_provider.dart';
import '../models/dorm_config.dart';

/// 宿舍绑定对话框
class ExpenseBindDialog extends ConsumerStatefulWidget {
  final Function(String buildingId, String roomCode)? onBind;
  final Function()? onCancel;
  final String? title;
  final DormInfo? initialDorm;
  final String? initialRoomCode;

  const ExpenseBindDialog({
    super.key,
    this.onBind,
    this.onCancel,
    this.title,
    this.initialDorm,
    this.initialRoomCode,
  });

  @override
  ConsumerState<ExpenseBindDialog> createState() => _ExpenseBindDialogState();
}

class _ExpenseBindDialogState extends ConsumerState<ExpenseBindDialog> {
  final _formKey = GlobalKey<FormState>();
  final _roomController = TextEditingController();

  String? _selectedArea;
  String? _selectedBuilding;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // 初始化数据
    if (widget.initialDorm != null) {
      _selectedArea = widget.initialDorm!.area;
      _selectedBuilding = widget.initialDorm!.building;
    }

    if (widget.initialRoomCode != null) {
      _roomController.text = widget.initialRoomCode!;
    }
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final themeColor = ref.watch(selectedCustomThemeProvider);
    final mainColor = themeColor?.colorList.isNotEmpty == true
        ? themeColor!.colorList[0]
        : Colors.blue;

    final backgroundColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Dialog(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [mainColor.withAlpha(26), mainColor.withAlpha(13)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: mainColor.withAlpha(38),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      color: mainColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title ?? '选择宿舍',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '请选择您的宿舍园区和楼栋',
                          style: TextStyle(fontSize: 14, color: subtitleColor),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleCancel,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.close_rounded,
                          color: subtitleColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 内容区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 园区选择
                      _buildSectionTitle('选择园区', mainColor),
                      const SizedBox(height: 12),
                      _buildAreaSelector(
                        mainColor,
                        textColor,
                        subtitleColor,
                        isDarkMode,
                      ),

                      const SizedBox(height: 24),

                      // 楼栋选择
                      _buildSectionTitle('选择楼栋', mainColor),
                      const SizedBox(height: 12),
                      _buildBuildingSelector(
                        mainColor,
                        textColor,
                        subtitleColor,
                        isDarkMode,
                      ),

                      const SizedBox(height: 24),

                      // 房间号输入
                      _buildSectionTitle('房间号', mainColor),
                      const SizedBox(height: 12),
                      _buildRoomInput(
                        mainColor,
                        textColor,
                        subtitleColor,
                        isDarkMode,
                      ),

                      const SizedBox(height: 24),

                      // 提示信息
                      _buildInfoCard(subtitleColor),

                      const SizedBox(height: 32),

                      // 操作按钮
                      _buildActionButtons(context, mainColor, textColor),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color mainColor) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: mainColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: mainColor,
          ),
        ),
      ],
    );
  }

  Widget _buildAreaSelector(
    Color mainColor,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withAlpha(13)
            : Colors.grey.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择园区',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: DormConfig.areas.map((area) {
              final isSelected = _selectedArea == area;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedArea = area;
                      _selectedBuilding = null; // 重置楼栋选择
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? mainColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? mainColor
                            : subtitleColor.withAlpha(76),
                      ),
                    ),
                    child: Text(
                      area,
                      style: TextStyle(
                        color: isSelected ? Colors.white : textColor,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildingSelector(
    Color mainColor,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode,
  ) {
    final buildings = _selectedArea != null
        ? DormConfig.getBuildingsByArea(_selectedArea!)
        : <String>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withAlpha(13)
            : Colors.grey.withAlpha(13),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择楼栋',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
            ),
          ),
          const SizedBox(height: 12),
          if (buildings.isEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  '请先选择园区',
                  style: TextStyle(color: subtitleColor, fontSize: 14),
                ),
              ),
            ),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: buildings.length,
              itemBuilder: (context, index) {
                final building = buildings[index];
                final isSelected = _selectedBuilding == building;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedBuilding = building;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? mainColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? mainColor
                              : subtitleColor.withAlpha(76),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          building,
                          style: TextStyle(
                            color: isSelected ? Colors.white : textColor,
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoomInput(
    Color mainColor,
    Color textColor,
    Color subtitleColor,
    bool isDarkMode,
  ) {
    return TextFormField(
      controller: _roomController,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: '四位房间号',
        labelStyle: TextStyle(color: subtitleColor),
        hintText: '例如：0101',
        hintStyle: TextStyle(color: subtitleColor.withAlpha(178)),
        prefixIcon: Icon(Icons.door_front_door, color: mainColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: mainColor),
        ),
        filled: true,
        fillColor: isDarkMode
            ? Colors.white.withAlpha(13)
            : Colors.grey.withAlpha(13),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return '请输入房间号';
        }
        return null;
      },
    );
  }

  Widget _buildInfoCard(Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(26),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withAlpha(76)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '温馨提示',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '请确保选择的宿舍信息准确无误，绑定后可在设置中重新绑定',
                  style: TextStyle(color: Colors.blue.shade600, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    Color mainColor,
    Color textColor,
  ) {
    final canBind =
        _selectedArea != null &&
        _selectedBuilding != null &&
        _roomController.text.trim().isNotEmpty;

    return Column(
      children: [
        // 确定按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_isLoading || !canBind) ? null : _handleBind,
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '确定绑定',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 12),

        // 取消按钮
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: _isLoading ? null : _handleCancel,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              '取消',
              style: TextStyle(fontSize: 14, color: textColor.withAlpha(178)),
            ),
          ),
        ),
      ],
    );
  }

  void _handleBind() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedArea == null || _selectedBuilding == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final buildingId = DormConfig.getBuildingId(
        _selectedArea!,
        _selectedBuilding!,
      );
      if (buildingId == null) {
        throw Exception('无效的宿舍配置');
      }

      await widget.onBind?.call(
        buildingId.toString(),
        _roomController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text('宿舍绑定成功！'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('绑定失败：$e')),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleCancel() {
    widget.onCancel?.call();
    Navigator.of(context).pop(false);
  }
}
