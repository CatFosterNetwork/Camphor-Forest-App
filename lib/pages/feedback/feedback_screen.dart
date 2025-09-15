// lib/pages/feedback/feedback_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/route_constants.dart';
import '../../core/config/providers/theme_config_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';
import 'providers/feedback_provider.dart';
import 'widgets/feedback_list_item.dart';
import 'widgets/feedback_filter_dropdown.dart';

/// Feedback main screen
class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _selectedStatus = '';

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(feedbackProvider.notifier).loadFeedbacks(refresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent) {
      ref.read(feedbackProvider.notifier).loadMore();
    }
  }

  void _onSearch() {
    if (!mounted) return;
    ref.read(feedbackProvider.notifier).search(_searchController.text);
  }

  void _onStatusFilter(String status, String displayName) {
    if (!mounted) return;

    setState(() {
      _selectedStatus = displayName;
    });
    ref.read(feedbackProvider.notifier).filterByStatus(status);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final feedbackState = ref.watch(feedbackProvider);

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: false,
      appBar: ThemeAwareAppBar(title: '反馈改进'),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(RouteConstants.feedbackAdd),
        backgroundColor: Colors.blue.withAlpha(isDarkMode ? 204 : 255),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // Search and filter bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Filter dropdown
                Expanded(
                  flex: 1,
                  child: FeedbackFilterDropdown(
                    selectedStatus: _selectedStatus,
                    onStatusSelected: _onStatusFilter,
                  ),
                ),
                const SizedBox(width: 12),

                // Search bar
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF202125)
                          : const Color(0xFFF2F2F2),
                      borderRadius: BorderRadius.circular(24),
                      border: isDarkMode
                          ? Border.all(color: const Color(0xFF606265))
                          : null,
                    ),
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (_) => _onSearch(),
                      style: TextStyle(
                        color: isDarkMode
                            ? Colors.white
                            : const Color(0xFF606266),
                      ),
                      decoration: InputDecoration(
                        hintText: '查找标题',
                        hintStyle: TextStyle(
                          color: isDarkMode
                              ? const Color(0xFFA9AAAC)
                              : const Color(0xFF909399),
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  color: isDarkMode
                                      ? Colors.white70
                                      : Colors.grey[600],
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearch();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(child: _buildContent(feedbackState, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildContent(FeedbackState state, bool isDarkMode) {
    if (state.feedbacks.isEmpty && state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.feedbacks.isEmpty && !state.isLoading) {
      return _buildEmptyState(isDarkMode);
    }

    return _buildFeedbackList(state, isDarkMode);
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF2A2A2A).withAlpha(217)
              : Colors.white.withAlpha(128),
          borderRadius: BorderRadius.circular(16),
          border: isDarkMode
              ? Border.all(color: Colors.white.withAlpha(26), width: 1)
              : null,
          boxShadow: isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.grey.withAlpha(51),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '欢迎来到反馈',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '问题用于跟踪待办事项、错误、功能请求等。随着问题的创建，它们将出现在此处形成一个可搜索和可过滤的列表。要开始使用，您应该',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.push(RouteConstants.feedbackAdd),
              child: const Text(
                '创建一个问题',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Text('。', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackList(FeedbackState state, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? const Color(0xFF2A2A2A).withAlpha(217)
            : Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(16),
        border: isDarkMode
            ? Border.all(color: Colors.white.withAlpha(26), width: 1)
            : null,
        boxShadow: isDarkMode
            ? null
            : [
                BoxShadow(
                  color: Colors.grey.withAlpha(51),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(8),
        itemCount:
            state.feedbacks.length + (state.isLoading && state.hasMore ? 1 : 0),
        separatorBuilder: (context, index) => Container(
          height: 1,
          color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
        itemBuilder: (context, index) {
          if (index == state.feedbacks.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final feedback = state.feedbacks[index];
          return FeedbackListItem(
            feedback: feedback,
            onTap: () => context.push(
              '${RouteConstants.feedbackDetail}?id=${feedback.id}',
            ),
          );
        },
      ),
    );
  }
}
