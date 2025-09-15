// lib/pages/feedback/models/feedback_models.dart

import 'dart:convert';

/// Feedback user model
class FeedbackUser {
  final int id;
  final String name;
  final String accountId;
  final String studentId;
  final DateTime gmtCreate;
  final DateTime gmtModified;
  final bool siteAdmin;
  final String avatarUrl;
  final String bio;
  final String email;

  FeedbackUser({
    required this.id,
    required this.name,
    required this.accountId,
    required this.studentId,
    required this.gmtCreate,
    required this.gmtModified,
    required this.siteAdmin,
    required this.avatarUrl,
    required this.bio,
    required this.email,
  });

  factory FeedbackUser.fromJson(Map<String, dynamic> json) {
    return FeedbackUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      accountId: json['accountId'] ?? '',
      studentId: json['studentId'] ?? '',
      gmtCreate: DateTime.tryParse(json['gmtCreate'] ?? '') ?? DateTime.now(),
      gmtModified:
          DateTime.tryParse(json['gmtModified'] ?? '') ?? DateTime.now(),
      siteAdmin: json['siteAdmin'] ?? false,
      avatarUrl: json['avatarUrl'] ?? '',
      bio: json['bio'] ?? '',
      email: json['email'] ?? '',
    );
  }
}

/// Feedback status enum
enum FeedbackStatus {
  pending(0, '已提交', '待处理'),
  resolved(1, '已解决', '已解决'),
  rejected(2, '已关闭', '已关闭');

  const FeedbackStatus(this.value, this.displayName, this.description);

  final int value;
  final String displayName;
  final String description;

  static FeedbackStatus fromValue(int value) {
    switch (value) {
      case 0:
        return FeedbackStatus.pending;
      case 1:
        return FeedbackStatus.resolved;
      case 2:
        return FeedbackStatus.rejected;
      default:
        return FeedbackStatus.pending;
    }
  }
}

/// Feedback model
class Feedback {
  final int id;
  final FeedbackUser user;
  final String replyEmail;
  final String title;
  final String content;
  final DateTime gmtCreate;
  final DateTime gmtModified;
  final FeedbackStatus status;
  final int type;
  final DateTime? resolvedTime;
  final FeedbackUser? resolver;
  final String? resourceUrl;
  final bool visibility;

  Feedback({
    required this.id,
    required this.user,
    required this.replyEmail,
    required this.title,
    required this.content,
    required this.gmtCreate,
    required this.gmtModified,
    required this.status,
    required this.type,
    this.resolvedTime,
    this.resolver,
    this.resourceUrl,
    required this.visibility,
  });

  factory Feedback.fromJson(Map<String, dynamic> json) {
    return Feedback(
      id: json['id'] ?? 0,
      user: FeedbackUser.fromJson(json['user'] ?? {}),
      replyEmail: json['replyEmail'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      gmtCreate: DateTime.tryParse(json['gmtCreate'] ?? '') ?? DateTime.now(),
      gmtModified:
          DateTime.tryParse(json['gmtModified'] ?? '') ?? DateTime.now(),
      status: FeedbackStatus.fromValue(json['status'] ?? 0),
      type: json['type'] ?? 0,
      resolvedTime: json['resolvedTime'] != null
          ? DateTime.tryParse(json['resolvedTime'])
          : null,
      resolver: json['resolver'] != null
          ? FeedbackUser.fromJson(json['resolver'])
          : null,
      resourceUrl: json['resourceUrl'],
      visibility: json['visibility'] ?? true,
    );
  }

  /// Get images from resourceUrl JSON
  List<String> get images {
    if (resourceUrl == null || resourceUrl!.isEmpty) return [];

    try {
      final Map<String, dynamic> urls = Map<String, dynamic>.from(
        jsonDecode(resourceUrl!) as Map,
      );
      return urls.values.cast<String>().toList();
    } catch (e) {
      return [];
    }
  }
}

/// Feedback reply model
class FeedbackReply {
  final int id;
  final FeedbackUser author;
  final String content;
  final DateTime gmtCreate;
  final DateTime gmtModified;
  final FeedbackStatus? statusChangeType;

  FeedbackReply({
    required this.id,
    required this.author,
    required this.content,
    required this.gmtCreate,
    required this.gmtModified,
    this.statusChangeType,
  });

  factory FeedbackReply.fromJson(Map<String, dynamic> json) {
    FeedbackStatus? statusChange;
    final content = json['content'] ?? '';

    // Detect status changes based on content
    if (content.contains('已解决') || content.startsWith('done')) {
      statusChange = FeedbackStatus.resolved;
    } else if (content.contains('已关闭') || content.startsWith('close')) {
      statusChange = FeedbackStatus.rejected;
    } else if (content.contains('已重新打开') || content.startsWith('open')) {
      statusChange = FeedbackStatus.pending;
    }

    return FeedbackReply(
      id: json['id'] ?? 0,
      author: FeedbackUser.fromJson(json['author'] ?? {}),
      content: content,
      gmtCreate: DateTime.tryParse(json['gmtCreate'] ?? '') ?? DateTime.now(),
      gmtModified:
          DateTime.tryParse(json['gmtModified'] ?? '') ?? DateTime.now(),
      statusChangeType: statusChange,
    );
  }

  /// Check if this is a status change reply
  bool get isStatusChange {
    return statusChangeType != null;
  }
}

/// Feedback list response model
class FeedbackListResponse {
  final List<Feedback> list;
  final int page;
  final int total;
  final bool hasMore;

  FeedbackListResponse({
    required this.list,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  factory FeedbackListResponse.fromJson(dynamic json) {
    // Handle both direct list response and nested data structure
    List<dynamic> listData;
    Map<String, dynamic>? pageInfo;

    if (json is Map<String, dynamic>) {
      pageInfo = json;
      if (json.containsKey('data') && json['data'] is Map) {
        // Nested structure: { "data": { "list": [...], "page": 1 } }
        final data = json['data'] as Map<String, dynamic>;
        listData = data['list'] as List? ?? [];
        pageInfo = data;
      } else if (json.containsKey('list')) {
        // Direct structure: { "list": [...], "page": 1 }
        listData = json['list'] as List? ?? [];
      } else {
        // Fallback: empty list
        listData = [];
      }
    } else if (json is List) {
      // Direct list response: [...]
      listData = json;
      pageInfo = null;
    } else {
      // Fallback: empty list
      listData = [];
      pageInfo = null;
    }

    final list = listData
        .map((item) => Feedback.fromJson(item as Map<String, dynamic>))
        .toList();

    final page = pageInfo?['page'] ?? 1;
    final total = pageInfo?['total'] ?? list.length;
    final pageSize = 20; // Default page size

    return FeedbackListResponse(
      list: list,
      page: page,
      total: total,
      hasMore: list.length == pageSize && (page * pageSize) < total,
    );
  }
}

/// Feedback reply list response model
class FeedbackReplyListResponse {
  final List<FeedbackReply> list;
  final int page;
  final int total;
  final bool hasMore;

  FeedbackReplyListResponse({
    required this.list,
    required this.page,
    required this.total,
    required this.hasMore,
  });

  factory FeedbackReplyListResponse.fromJson(dynamic json) {
    // Handle different response structures
    List<dynamic> listData;
    Map<String, dynamic>? pageInfo;

    if (json is List) {
      // Direct list response
      listData = json;
      pageInfo = null;
    } else if (json is Map<String, dynamic>) {
      if (json.containsKey('data')) {
        // Response wrapped in data field
        final data = json['data'];
        if (data is List) {
          listData = data;
        } else if (data is Map<String, dynamic> && data.containsKey('list')) {
          listData = data['list'] as List<dynamic>? ?? [];
          pageInfo = data;
        } else {
          listData = [];
        }
      } else if (json.containsKey('list')) {
        // Direct map with list field
        listData = json['list'] as List<dynamic>? ?? [];
        pageInfo = json;
      } else {
        // Assume the map itself is the data
        listData = [json];
      }
    } else {
      listData = [];
    }

    final list = listData
        .map((item) => FeedbackReply.fromJson(item as Map<String, dynamic>))
        .toList();

    final page = pageInfo?['page'] ?? 1;
    final total = pageInfo?['total'] ?? list.length;
    final pageSize = 10; // Default page size for replies

    return FeedbackReplyListResponse(
      list: list,
      page: page,
      total: total,
      hasMore: list.length == pageSize && (page * pageSize) < total,
    );
  }
}
