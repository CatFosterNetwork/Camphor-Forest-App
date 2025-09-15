// lib/pages/feedback/widgets/feedback_filter_dropdown.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers/theme_config_provider.dart';

/// Feedback filter dropdown widget
class FeedbackFilterDropdown extends ConsumerStatefulWidget {
  final String selectedStatus;
  final Function(String status, String displayName) onStatusSelected;

  const FeedbackFilterDropdown({
    super.key,
    required this.selectedStatus,
    required this.onStatusSelected,
  });

  @override
  ConsumerState<FeedbackFilterDropdown> createState() =>
      _FeedbackFilterDropdownState();
}

class _FeedbackFilterDropdownState
    extends ConsumerState<FeedbackFilterDropdown> {
  bool _isExpanded = false;

  final List<Map<String, dynamic>> _filterOptions = [
    {
      'status': 'PENDING',
      'displayName': '已提交',
      'icon': Icons.visibility,
      'color': Colors.green,
    },
    {
      'status': 'RESOLVED',
      'displayName': '已解决',
      'icon': Icons.check_circle,
      'color': Colors.purple,
    },
    {
      'status': 'REJECTED',
      'displayName': '已关闭',
      'icon': Icons.cancel,
      'color': Colors.grey,
    },
    {
      'status': '',
      'displayName': '全部',
      'icon': Icons.info,
      'color': Colors.blue,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final displayName = widget.selectedStatus.isEmpty
        ? '已提交'
        : widget.selectedStatus;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2A2A2A).withAlpha(217)
            : Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(8),
        border: isDarkMode
            ? Border.all(color: Colors.white.withAlpha(26), width: 1)
            : Border.all(color: Colors.grey.shade300),
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withAlpha(25),
                  blurRadius: 4,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
            _showFilterMenu(context, isDarkMode);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFilterMenu(BuildContext context, bool isDarkMode) {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<Map<String, dynamic>>(
      context: context,
      position: position,
      color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDarkMode ? Colors.white.withAlpha(26) : Colors.grey.shade300,
        ),
      ),
      items: _filterOptions.map((option) {
        return PopupMenuItem<Map<String, dynamic>>(
          value: option,
          child: Row(
            children: [
              Icon(
                option['icon'] as IconData,
                color: option['color'] as Color,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                option['displayName'] as String,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((selectedOption) {
      setState(() {
        _isExpanded = false;
      });

      if (selectedOption != null) {
        widget.onStatusSelected(
          selectedOption['status'] as String,
          selectedOption['displayName'] as String,
        );
      }
    });
  }
}
