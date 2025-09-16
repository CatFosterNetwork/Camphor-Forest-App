// lib/pages/feedback/providers/feedback_provider.dart

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/api_service.dart';
import '../../../core/providers/core_providers.dart';
import '../models/feedback_models.dart';

/// Feedback state
class FeedbackState {
  final List<Feedback> feedbacks;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String currentStatus;
  final String searchQuery;
  final String? error;

  FeedbackState({
    this.feedbacks = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.currentStatus = 'PENDING', // 默认为"已提交"状态
    this.searchQuery = '',
    this.error,
  });

  FeedbackState copyWith({
    List<Feedback>? feedbacks,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? currentStatus,
    String? searchQuery,
    String? error,
  }) {
    return FeedbackState(
      feedbacks: feedbacks ?? this.feedbacks,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      currentStatus: currentStatus ?? this.currentStatus,
      searchQuery: searchQuery ?? this.searchQuery,
      error: error,
    );
  }
}

/// Feedback provider
class FeedbackNotifier extends StateNotifier<FeedbackState> {
  final ApiService _apiService;

  FeedbackNotifier(this._apiService) : super(FeedbackState());

  /// Load feedbacks
  Future<void> loadFeedbacks({
    bool refresh = false,
    String? status,
    String? query,
  }) async {
    debugPrint('[Feedback] === 开始加载反馈列表 ===');
    debugPrint('[Feedback] 参数: refresh=$refresh, status=$status, query=$query');
    debugPrint(
      '[Feedback] 当前状态: currentPage=${state.currentPage}, hasMore=${state.hasMore}, isLoading=${state.isLoading}, feedbackCount=${state.feedbacks.length}',
    );

    if (state.isLoading) {
      debugPrint('[Feedback] 已在加载中，提前返回');
      return;
    }

    // If refreshing or changing filters, reset state
    if (refresh ||
        status != state.currentStatus ||
        query != state.searchQuery) {
      debugPrint(
        '[Feedback] 重置状态: refresh=$refresh, statusChanged=${status != state.currentStatus}, queryChanged=${query != state.searchQuery}',
      );
      state = state.copyWith(
        feedbacks: [],
        currentPage: 1,
        hasMore: true,
        currentStatus: status ?? state.currentStatus,
        searchQuery: query ?? state.searchQuery,
        error: null,
      );
      debugPrint(
        '[Feedback] 状态重置后: currentPage=${state.currentPage}, hasMore=${state.hasMore}, feedbackCount=${state.feedbacks.length}',
      );
    }

    // Don't load more if no more data
    if (!state.hasMore && !refresh) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Use current page for request, then increment after success
      final pageToRequest = refresh ? 1 : state.currentPage;

      debugPrint(
        '[Feedback] 加载反馈: refresh=$refresh, page=$pageToRequest, hasMore=${state.hasMore}',
      );

      final response = await _apiService.getFeedback(
        query: state.searchQuery,
        pageNo: pageToRequest,
        status: state.currentStatus,
      );

      debugPrint(
        '[Feedback] API响应已接收: ${response.toString().length > 200 ? "${response.toString().substring(0, 200)}..." : response.toString()}',
      );

      final feedbackResponse = FeedbackListResponse.fromJson(response);

      debugPrint(
        '[Feedback] 解析响应: listCount=${feedbackResponse.list.length}, page=${feedbackResponse.page}, total=${feedbackResponse.total}, hasMore=${feedbackResponse.hasMore}',
      );

      // Sort by creation date (newest first)
      final sortedFeedbacks = feedbackResponse.list
        ..sort((a, b) => b.gmtCreate.compareTo(a.gmtCreate));

      final allFeedbacks = refresh
          ? sortedFeedbacks
          : [...state.feedbacks, ...sortedFeedbacks];

      debugPrint(
        '[Feedback] 数据合并: refresh=$refresh, existing=${state.feedbacks.length}, new=${sortedFeedbacks.length}, total=${allFeedbacks.length}',
      );

      state = state.copyWith(
        feedbacks: allFeedbacks,
        isLoading: false,
        hasMore: feedbackResponse.hasMore,
        currentPage: pageToRequest + 1,
      );

      debugPrint(
        '[Feedback] 状态已更新: currentPage=${state.currentPage}, hasMore=${state.hasMore}, totalFeedbacks=${state.feedbacks.length}',
      );
      debugPrint('[Feedback] === 反馈列表加载完成 ===');
    } catch (e) {
      debugPrint('[Feedback] 加载反馈列表错误: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      debugPrint('[Feedback] === 反馈列表加载完成 (错误) ===');
    }
  }

  /// Load more feedbacks
  Future<void> loadMore() async {
    debugPrint('[Feedback] === 开始加载更多 ===');
    if (state.hasMore && !state.isLoading) {
      debugPrint(
        '[Feedback] 加载更多反馈: currentPage=${state.currentPage}, hasMore=${state.hasMore}',
      );
      // Use current state values to avoid triggering reset
      await loadFeedbacks(
        refresh: false,
        status: state.currentStatus,
        query: state.searchQuery,
      );
    } else {
      debugPrint(
        '[Feedback] 跳过加载更多: hasMore=${state.hasMore}, isLoading=${state.isLoading}',
      );
    }
    debugPrint('[Feedback] === 加载更多结束 ===');
  }

  /// Refresh feedbacks (full reset)
  Future<void> refresh() async {
    debugPrint('[Feedback] === 开始刷新 ===');
    await loadFeedbacks(refresh: true);
    debugPrint('[Feedback] === 刷新结束 ===');
  }

  /// Search feedbacks
  Future<void> search(String query) async {
    await loadFeedbacks(refresh: true, query: query);
  }

  /// Filter by status
  Future<void> filterByStatus(String status) async {
    await loadFeedbacks(refresh: true, status: status);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Feedback provider
final feedbackProvider = StateNotifierProvider<FeedbackNotifier, FeedbackState>(
  (ref) {
    final apiService = ref.watch(apiServiceProvider);
    return FeedbackNotifier(apiService);
  },
);

/// Feedback detail state
class FeedbackDetailState {
  final Feedback? feedback;
  final List<FeedbackReply> replies;
  final bool isLoading;
  final bool isLoadingReplies;
  final bool hasMoreReplies;
  final int currentReplyPage;
  final String? error;

  FeedbackDetailState({
    this.feedback,
    this.replies = const [],
    this.isLoading = false,
    this.isLoadingReplies = false,
    this.hasMoreReplies = true,
    this.currentReplyPage = 1,
    this.error,
  });

  FeedbackDetailState copyWith({
    Feedback? feedback,
    List<FeedbackReply>? replies,
    bool? isLoading,
    bool? isLoadingReplies,
    bool? hasMoreReplies,
    int? currentReplyPage,
    String? error,
  }) {
    return FeedbackDetailState(
      feedback: feedback ?? this.feedback,
      replies: replies ?? this.replies,
      isLoading: isLoading ?? this.isLoading,
      isLoadingReplies: isLoadingReplies ?? this.isLoadingReplies,
      hasMoreReplies: hasMoreReplies ?? this.hasMoreReplies,
      currentReplyPage: currentReplyPage ?? this.currentReplyPage,
      error: error,
    );
  }
}

/// Feedback detail provider
class FeedbackDetailNotifier extends StateNotifier<FeedbackDetailState> {
  final ApiService _apiService;

  FeedbackDetailNotifier(this._apiService) : super(FeedbackDetailState());

  /// Load feedback detail
  Future<void> loadFeedbackDetail(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiService.getFeedbackDetail(id);
      // Handle both direct response and nested data structure
      final feedbackData = response.containsKey('data')
          ? response['data']
          : response;
      final feedback = Feedback.fromJson(feedbackData as Map<String, dynamic>);

      state = state.copyWith(feedback: feedback, isLoading: false);

      // Load replies
      await loadReplies(id, refresh: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Load replies
  Future<void> loadReplies(int feedbackId, {bool refresh = false}) async {
    if (state.isLoadingReplies) return;

    if (refresh) {
      state = state.copyWith(
        replies: [],
        currentReplyPage: 1,
        hasMoreReplies: true,
      );
    }

    if (!state.hasMoreReplies && !refresh) return;

    state = state.copyWith(isLoadingReplies: true);

    try {
      final response = await _apiService.getFeedbackReplyList(
        id: feedbackId,
        pageNo: state.currentReplyPage,
        pageSize: 10,
      );

      final replyResponse = FeedbackReplyListResponse.fromJson(response);

      final allReplies = refresh
          ? replyResponse.list
          : [...state.replies, ...replyResponse.list];

      state = state.copyWith(
        replies: allReplies,
        isLoadingReplies: false,
        hasMoreReplies: replyResponse.hasMore,
        currentReplyPage: state.currentReplyPage + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoadingReplies: false, error: e.toString());
    }
  }

  /// Add reply
  Future<bool> addReply(int feedbackId, String content) async {
    try {
      await _apiService.addFeedbackReply(id: feedbackId, content: content);

      // Refresh replies after adding
      await loadReplies(feedbackId, refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update feedback status (admin only)
  Future<bool> updateFeedbackStatus(
    int feedbackId,
    FeedbackStatus status,
  ) async {
    try {
      switch (status) {
        case FeedbackStatus.resolved:
          await _apiService.setFeedbackResolved(feedbackId);
          await _apiService.addFeedbackReply(id: feedbackId, content: 'done');
          break;
        case FeedbackStatus.rejected:
          await _apiService.setFeedbackReject(feedbackId);
          await _apiService.addFeedbackReply(id: feedbackId, content: 'close');
          break;
        case FeedbackStatus.pending:
          await _apiService.setFeedbackPend(feedbackId);
          await _apiService.addFeedbackReply(id: feedbackId, content: 'open');
          break;
      }

      // Update local state
      if (state.feedback != null) {
        final updatedFeedback = Feedback(
          id: state.feedback!.id,
          user: state.feedback!.user,
          replyEmail: state.feedback!.replyEmail,
          title: state.feedback!.title,
          content: state.feedback!.content,
          gmtCreate: state.feedback!.gmtCreate,
          gmtModified: DateTime.now(),
          status: status,
          type: state.feedback!.type,
          resolvedTime: status == FeedbackStatus.resolved
              ? DateTime.now()
              : null,
          resolver: state.feedback!.resolver,
          resourceUrl: state.feedback!.resourceUrl,
          visibility: state.feedback!.visibility,
        );

        state = state.copyWith(feedback: updatedFeedback);
      }

      // Refresh replies to show status change
      await loadReplies(feedbackId, refresh: true);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Update feedback visibility (admin only)
  Future<bool> updateFeedbackVisibility(int feedbackId, bool visibility) async {
    try {
      await _apiService.setFeedbackVisibility(feedbackId, visibility);

      // Update the current state immediately
      if (state.feedback != null) {
        final updatedFeedback = Feedback(
          id: state.feedback!.id,
          user: state.feedback!.user,
          replyEmail: state.feedback!.replyEmail,
          title: state.feedback!.title,
          content: state.feedback!.content,
          gmtCreate: state.feedback!.gmtCreate,
          gmtModified: DateTime.now(),
          status: state.feedback!.status,
          type: state.feedback!.type,
          resolvedTime: state.feedback!.resolvedTime,
          resolver: state.feedback!.resolver,
          resourceUrl: state.feedback!.resourceUrl,
          visibility: visibility,
        );

        state = state.copyWith(feedback: updatedFeedback);
      }

      return true;
    } catch (e) {
      debugPrint('[Feedback] 更新反馈可见性失败: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
    state = FeedbackDetailState();
  }
}

/// Feedback detail provider
final feedbackDetailProvider =
    StateNotifierProvider<FeedbackDetailNotifier, FeedbackDetailState>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      return FeedbackDetailNotifier(apiService);
    });

/// Add feedback state
class AddFeedbackState {
  final String title;
  final String email;
  final String content;
  final List<File> images;
  final bool isSubmitting;
  final String? error;
  final bool isSuccess;

  AddFeedbackState({
    this.title = '',
    this.email = '',
    this.content = '',
    this.images = const [],
    this.isSubmitting = false,
    this.error,
    this.isSuccess = false,
  });

  AddFeedbackState copyWith({
    String? title,
    String? email,
    String? content,
    List<File>? images,
    bool? isSubmitting,
    String? error,
    bool? isSuccess,
  }) {
    return AddFeedbackState(
      title: title ?? this.title,
      email: email ?? this.email,
      content: content ?? this.content,
      images: images ?? this.images,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }

  /// Check if form is valid
  bool get isValid {
    return title.isNotEmpty &&
        email.isNotEmpty &&
        content.isNotEmpty &&
        _isValidEmail(email);
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[\w\-.]+@[\w\-.]+\.[A-Z]{2,4}$',
      caseSensitive: false,
    ).hasMatch(email);
  }
}

/// Add feedback provider
class AddFeedbackNotifier extends StateNotifier<AddFeedbackState> {
  final ApiService _apiService;

  AddFeedbackNotifier(this._apiService) : super(AddFeedbackState());

  /// Update title
  void updateTitle(String title) {
    state = state.copyWith(title: title);
  }

  /// Update email
  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  /// Update content
  void updateContent(String content) {
    state = state.copyWith(content: content);
  }

  /// Add image
  void addImage(File image) {
    if (state.images.length < 9) {
      state = state.copyWith(images: [...state.images, image]);
    }
  }

  /// Remove image
  void removeImage(int index) {
    final images = List<File>.from(state.images);
    images.removeAt(index);
    state = state.copyWith(images: images);
  }

  /// Submit feedback
  Future<bool> submitFeedback() async {
    if (!state.isValid || state.isSubmitting) return false;

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      // Upload images first if any
      String? resourceUrl;
      if (state.images.isNotEmpty) {
        final imageUrls = <String, String>{};

        for (int i = 0; i < state.images.length; i++) {
          final file = state.images[i];
          final fileName =
              'feedback_${DateTime.now().millisecondsSinceEpoch}_$i.${file.path.split('.').last}';
          final url = await _apiService.uploadImage(file.path, fileName);
          imageUrls[i.toString()] = url;
        }

        resourceUrl = jsonEncode(imageUrls);
      }

      // Submit feedback
      await _apiService.addFeedback(
        title: state.title,
        replyEmail: state.email,
        content: state.content,
        resourceUrl: resourceUrl,
      );

      state = state.copyWith(isSubmitting: false, isSuccess: true);

      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }

  /// Reset form
  void reset() {
    state = AddFeedbackState();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Add feedback provider
final addFeedbackProvider =
    StateNotifierProvider<AddFeedbackNotifier, AddFeedbackState>((ref) {
      final apiService = ref.watch(apiServiceProvider);
      return AddFeedbackNotifier(apiService);
    });
