// lib/core/user_model.dart
class UserModel {
  final String accountId;
  final String avatarUrl;
  final String bio;
  final String email;
  final String gmtCreate;
  final String gmtModified;
  final int id;
  final String name;
  final bool siteAdmin;
  final String studentId;
  final String college;      // 学院
  final String major;        // 专业
  final String className;    // 班级
  String openId;

  UserModel({
    required this.accountId,
    required this.avatarUrl,
    required this.bio,
    required this.email,
    required this.gmtCreate,
    required this.gmtModified,
    required this.id,
    required this.name,
    required this.siteAdmin,
    required this.studentId,
    required this.college,
    required this.major,
    required this.className,
    required this.openId,
  });

  /// 创建一个空的 UserModel
  factory UserModel.empty() => UserModel(
    accountId: '',
    avatarUrl: '',
    bio: '',
    email: '',
    gmtCreate: '',
    gmtModified: '',
    id: 0,
    name: '',
    siteAdmin: false,
    studentId: '',
    college: '',
    major: '',
    className: '',
    openId: '',
  );

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    accountId: json['accountId'] as String? ?? '',
    avatarUrl: json['avatarUrl'] as String? ?? '',
    bio: json['bio'] as String? ?? '',
    email: json['email'] as String? ?? '',
    gmtCreate: json['gmtCreate'] as String? ?? '',
    gmtModified: json['gmtModified'] as String? ?? '',
    id: json['id'] as int? ?? 0,
    name: json['name'] as String? ?? '',
    siteAdmin: json['siteAdmin'] as bool? ?? false,
    studentId: json['studentId'] as String? ?? '',
    college: json['college'] as String? ?? '',
    major: json['major'] as String? ?? '',
    className: json['className'] as String? ?? '',
    openId: json['openId'] as String? ?? '',
  );

  Map<String, dynamic> toJson() => {
    'accountId': accountId,
    'avatarUrl': avatarUrl,
    'bio': bio,
    'email': email,
    'gmtCreate': gmtCreate,
    'gmtModified': gmtModified,
    'id': id,
    'name': name,
    'siteAdmin': siteAdmin,
    'studentId': studentId,
    'college': college,
    'major': major,
    'className': className,
    'openId': openId,
  };

  /// 创建当前实例的副本并更新指定字段
  UserModel copyWith({
    String? accountId,
    String? avatarUrl,
    String? bio,
    String? email,
    String? gmtCreate,
    String? gmtModified,
    int? id,
    String? name,
    bool? siteAdmin,
    String? studentId,
    String? college,
    String? major,
    String? className,
    String? openId,
  }) {
    return UserModel(
      accountId: accountId ?? this.accountId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      email: email ?? this.email,
      gmtCreate: gmtCreate ?? this.gmtCreate,
      gmtModified: gmtModified ?? this.gmtModified,
      id: id ?? this.id,
      name: name ?? this.name,
      siteAdmin: siteAdmin ?? this.siteAdmin,
      studentId: studentId ?? this.studentId,
      college: college ?? this.college,
      major: major ?? this.major,
      className: className ?? this.className,
      openId: openId ?? this.openId,
    );
  }
}
