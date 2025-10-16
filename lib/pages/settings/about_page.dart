// lib/pages/settings/about_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:go_router/go_router.dart';

import '../../core/services/permission_service.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // 暂时不使用SVG
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/config/providers/theme_config_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';
import '../../core/widgets/cached_image.dart';
import '../../core/constants/route_constants.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  String appName = '樟木林Toolbox';
  String version = '1.0.0';
  String buildNumber = '1';
  String packageName = 'social.swu.camphor_forest';

  // 扫描二维码按钮要打开的HTTPS链接
  static const String qrCodeScannerUrl =
      'https://qm.qq.com/cgi-bin/qm/qr?k=C9I3YXZELhwBSgddJo3AoWSpxnZIFjZ0&jump_from=webapi&authKey=KdVybMFYnwGqo7rsBYJBXijgIhLf46UmYzfXe6qICrndvsK/3bOdOhL+X+fMnmah';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      if (mounted) {
        setState(() {
          appName = packageInfo.appName;
          version = packageInfo.version;
          buildNumber = packageInfo.buildNumber;
          packageName = packageInfo.packageName;
        });
      }
    } catch (e) {
      // 使用默认值
      debugPrint('加载包信息失败: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref; // 从ConsumerState获取ref
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: true, // 使用背景
      appBar: ThemeAwareAppBar(title: '关于'),
      body: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.92,
          child: Column(
            children: [
              const SizedBox(height: 80), // 顶部间距
              // SWU Logo - 全尺寸圆角显示
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(
                    80,
                  ), // 100%圆角弧度（半径为容器宽度的一半）
                  color: isDarkMode
                      ? const Color(0xFF202125)
                      : Colors.grey.shade200,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(80), // 100%圆角弧度
                  child: Image.asset(
                    'assets/icons/swulogo.jpg', // 临时使用jpg版本
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover, // 填满整个容器
                  ),
                ),
              ),

              const SizedBox(height: 48), // Logo和卡片间距
              // 信息卡片
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isDarkMode ? const Color(0xFF202125) : Colors.white,
                  border: isDarkMode
                      ? Border.all(color: const Color(0xFF616266), width: 1)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 应用版本
                    _buildInfoRow('应用版本', version, isDarkMode, isFirst: true),

                    // 系统版本（Flutter相当于微信版本）
                    _buildInfoRow(
                      'Flutter版本',
                      _getFlutterVersion(),
                      isDarkMode,
                    ),

                    // Dart版本（相当于SDK版本）
                    _buildInfoRow('Dart版本', _getDartVersion(), isDarkMode),

                    // 用户协议
                    _buildActionRow(
                      '用户协议',
                      isDarkMode,
                      onTap: () => _navigateToUserAgreement(context),
                    ),

                    // 官方Q群
                    _buildActionRow(
                      '官方Q群',
                      isDarkMode,
                      onTap: () => _showOfficialGroup(context),
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32), // 底部间距
            ],
          ),
        ),
      ),
    );
  }

  /// 构建信息行（只显示信息，不可点击）
  Widget _buildInfoRow(
    String title,
    String value,
    bool isDarkMode, {
    bool isFirst = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: isFirst
            ? null
            : Border(
                top: BorderSide(
                  color: isDarkMode
                      ? const Color(0xFF616266)
                      : Colors.grey.shade400.withAlpha(102), // 0.4 * 255 ≈ 102
                  width: 1,
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              color: isDarkMode
                  ? const Color(0xFFA9AAAC)
                  : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建操作行（可点击的项目）
  Widget _buildActionRow(
    String title,
    bool isDarkMode, {
    VoidCallback? onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            )
          : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDarkMode
                  ? const Color(0xFF616266)
                  : Colors.grey.shade400.withAlpha(102), // 0.4 * 255 ≈ 102
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDarkMode ? const Color(0xFFA9ABAC) : Colors.black,
            ),
          ],
        ),
      ),
    );
  }

  /// 获取Flutter版本信息
  String _getFlutterVersion() {
    // 在实际应用中，你可能需要使用其他方法来获取Flutter版本
    // 这里返回一个示例版本
    return '3.24.0';
  }

  /// 获取Dart版本信息
  String _getDartVersion() {
    // 在实际应用中，你可能需要使用其他方法来获取Dart版本
    // 这里返回一个示例版本
    return '3.5.0';
  }

  /// 导航到用户协议页面
  void _navigateToUserAgreement(BuildContext context) {
    context.push(RouteConstants.userAgreement);
  }

  /// 显示官方群二维码
  void _showOfficialGroup(BuildContext context) {
    final isDarkMode = ref.read(effectiveIsDarkModeProvider);

    if (Platform.isIOS) {
      _showIOSOfficialGroup(context, isDarkMode);
    } else {
      _showAndroidOfficialGroup(context, isDarkMode);
    }
  }

  /// iOS 原生样式的官方群对话框 - 使用全屏模态页面
  void _showIOSOfficialGroup(BuildContext context, bool isDarkMode) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => _IOSQRCodeViewer(
          isDarkMode: isDarkMode,
          onOpenQQGroup: _openQQGroup,
          onShowActions: () => _showQRCodeActions(context, isDarkMode),
        ),
      ),
    );
  }

  /// Android 样式的官方群对话框
  void _showAndroidOfficialGroup(BuildContext context, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          '官方Q群',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w500,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 缓存的二维码图片 - 保持原图片比例
            GestureDetector(
              onTap: () => _openQQGroup(),
              onLongPress: () => _showQRCodeActions(context, isDarkMode),
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 250,
                  maxHeight: 250,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(26),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: CachedImage(
                  imageUrl: isDarkMode
                      ? 'https://data.swu.social/service/qrcode_dark.JPG'
                      : 'https://data.swu.social/service/qrcode_light.JPG',
                  fit: BoxFit.contain, // 保持原图片比例
                  borderRadius: BorderRadius.circular(8),
                  placeholder: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '加载失败',
                            style: TextStyle(
                              color: isDarkMode
                                  ? Colors.white70
                                  : Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '点击打开QQ群，长按保存图片或扫描',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode
                    ? Colors.white.withOpacity(0.8)
                    : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Text(
              '关闭',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 打开QQ群
  void _openQQGroup() async {
    try {
      // 根据平台使用不同的链接
      Uri qqGroupUri;
      if (Platform.isIOS) {
        // iOS链接
        qqGroupUri = Uri.parse(
          'mqqapi://card/show_pslcard?src_type=internal&version=1&uin=837036146&authSig=pdyDAMgTDvhpPsOZLl1hT3Fhbrg9ESRHod2SKpMSnjX3zG78xYp9R6LIYeUJjLeK&card_type=group&source=external&jump_from=webapi',
        );
      } else if (Platform.isAndroid) {
        // Android链接
        qqGroupUri = Uri.parse(
          'mqqopensdkapi://bizAgent/qm/qr?url=http%3A%2F%2Fqm.qq.com%2Fcgi-bin%2Fqm%2Fqr%3Ffrom%3Dapp%26p%3Dandroid%26jump_from%3Dwebapi%26k%3DDaJyjtwq2ZzxvMtVmYOMM4i8zgaQCClN',
        );
      } else {
        // 其他平台
        qqGroupUri = Uri.parse(
          'https://qm.qq.com/cgi-bin/qm/qr?k=C9I3YXZELhwBSgddJo3AoWSpxnZIFjZ0&jump_from=webapi&authKey=KdVybMFYnwGqo7rsBYJBXijgIhLf46UmYzfXe6qICrndvsK/3bOdOhL+X+fMnmah',
        );
      }

      // 备用网页链接
      final Uri webUri = Uri.parse(
        'https://qm.qq.com/cgi-bin/qm/qr?k=C9I3YXZELhwBSgddJo3AoWSpxnZIFjZ0&jump_from=webapi&authKey=KdVybMFYnwGqo7rsBYJBXijgIhLf46UmYzfXe6qICrndvsK/3bOdOhL+X+fMnmah',
      );

      bool launched = false;

      // 先尝试打开QQ应用
      if (await canLaunchUrl(qqGroupUri)) {
        await launchUrl(qqGroupUri);
        launched = true;
      }
      // 如果QQ应用不可用，打开浏览器
      else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        launched = true;
      }

      if (!launched) {
        // 如果都无法打开，则复制链接到剪贴板作为备选方案
        await Clipboard.setData(ClipboardData(text: webUri.toString()));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('无法打开QQ群，链接已复制到剪贴板'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // 发生错误时，尝试复制链接作为备选方案
      try {
        await Clipboard.setData(
          ClipboardData(
            text:
                'https://qm.qq.com/cgi-bin/qm/qr?k=C9I3YXZELhwBSgddJo3AoWSpxnZIFjZ0&jump_from=webapi&authKey=KdVybMFYnwGqo7rsBYJBXijgIhLf46UmYzfXe6qICrndvsK/3bOdOhL+X+fMnmah ',
          ),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('打开失败，链接已复制到剪贴板'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (clipboardError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('操作失败: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  /// 显示二维码操作菜单
  void _showQRCodeActions(BuildContext context, bool isDarkMode) {
    if (Platform.isIOS) {
      _showIOSQRCodeActions(context);
    } else {
      _showAndroidQRCodeActions(context, isDarkMode);
    }
  }

  /// iOS 原生样式的二维码操作菜单
  void _showIOSQRCodeActions(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text(
          '二维码操作',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        message: const Text(
          '选择您要执行的操作',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _openQQGroup();
            },
            child: const Text(
              '打开QQ群',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              final isDarkMode = ref.read(effectiveIsDarkModeProvider);
              _saveQRCodeImage(isDarkMode);
            },
            child: const Text(
              '保存图片',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _openSystemScanner();
            },
            child: const Text(
              '扫描二维码',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CupertinoColors.activeBlue,
              ),
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            '取消',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.destructiveRed,
            ),
          ),
        ),
      ),
    );
  }

  /// Android 样式的二维码操作菜单
  void _showAndroidQRCodeActions(BuildContext context, bool isDarkMode) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Text(
              '二维码操作',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 20),

            // 保存图片选项
            ListTile(
              leading: Icon(
                Icons.download,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              title: Text(
                '保存图片',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _saveQRCodeImage(isDarkMode);
              },
            ),

            // 打开QQ群选项
            ListTile(
              leading: Icon(
                Icons.group,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              title: Text(
                '打开QQ群',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _openQQGroup();
              },
            ),

            // 调用系统扫描选项
            ListTile(
              leading: Icon(
                Icons.qr_code_scanner,
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              title: Text(
                '扫描二维码',
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _openSystemScanner();
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  /// 保存二维码图片
  void _saveQRCodeImage(bool isDarkMode) async {
    try {
      // 显示保存进度对话框
      if (Platform.isIOS) {
        showCupertinoDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildSaveProgressDialog(isDarkMode),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildSaveProgressDialog(isDarkMode),
        );
      }

      final String imageUrl = isDarkMode
          ? 'https://data.swu.social/service/qrcode_dark.JPG'
          : 'https://data.swu.social/service/qrcode_light.JPG';

      // 使用新的权限管理器检查存储权限
      final result = await PermissionService.requestStoragePermission(
        context: context,
        showRationale: true,
      );

      if (!result.isGranted) {
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          PermissionService.showErrorSnackBar(
            context,
            result.errorMessage ?? '需要存储权限才能保存图片到相册',
          );
        }
        return;
      }

      // 下载图片
      final Uint8List imageBytes = await _downloadImage(imageUrl);

      // 保存到相册
      await _saveImageToGallery(imageBytes, isDarkMode);

      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        PermissionService.showSuccessSnackBar(context, '二维码已成功保存到相册');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        PermissionService.showErrorSnackBar(context, '保存失败: $e');
      }
    }
  }

  /// 下载图片
  Future<Uint8List> _downloadImage(String url) async {
    final dio = Dio();
    final response = await dio.get(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data);
  }

  /// 保存图片到相册
  Future<void> _saveImageToGallery(
    Uint8List imageBytes,
    bool isDarkMode,
  ) async {
    // 创建临时文件
    final tempDir = await getTemporaryDirectory();
    final fileName =
        'qrcode_${isDarkMode ? 'dark' : 'light'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(imageBytes);

    // 使用gal保存到相册
    await Gal.putImage(file.path);

    // 删除临时文件
    await file.delete();
  }

  /// 构建保存进度对话框
  Widget _buildSaveProgressDialog(bool isDarkMode) {
    if (Platform.isIOS) {
      return CupertinoAlertDialog(
        content: const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CupertinoActivityIndicator(radius: 12),
              SizedBox(height: 16),
              Text(
                '正在保存二维码...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    } else {
      return AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              '正在保存二维码...',
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
          ],
        ),
      );
    }
  }

  /// 打开二维码扫描链接
  void _openSystemScanner() async {
    try {
      // 使用 url_launcher 启动 HTTPS 链接
      final Uri uri = Uri.parse(qrCodeScannerUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(
          uri,
          mode: LaunchMode.externalApplication, // 在外部浏览器中打开
        );
      } else {
        // 如果无法打开链接，尝试复制到剪贴板
        await Clipboard.setData(const ClipboardData(text: qrCodeScannerUrl));
      }
    } catch (e) {
      debugPrint('打开二维码链接失败: $e');

      // 备用方案：复制链接到剪贴板
      try {
        await Clipboard.setData(const ClipboardData(text: qrCodeScannerUrl));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('打开失败，链接已复制到剪贴板'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (clipboardError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('操作失败，请稍后重试'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}

/// iOS 原生风格的二维码查看器
class _IOSQRCodeViewer extends StatelessWidget {
  final bool isDarkMode;
  final VoidCallback onOpenQQGroup;
  final VoidCallback onShowActions;

  const _IOSQRCodeViewer({
    required this.isDarkMode,
    required this.onOpenQQGroup,
    required this.onShowActions,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.8),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            '完成',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.activeBlue,
            ),
          ),
        ),
        middle: const Text(
          '官方Q群',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onShowActions,
          child: const Icon(
            CupertinoIcons.ellipsis_circle,
            color: CupertinoColors.activeBlue,
            size: 24,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 二维码图片
              Center(
                child: Container(
                  constraints: const BoxConstraints(
                    maxWidth: 320,
                    maxHeight: 400,
                  ),
                  child: GestureDetector(
                    onTap: onOpenQQGroup,
                    onLongPress: onShowActions,
                    child: CachedImage(
                      imageUrl: isDarkMode
                          ? 'https://data.swu.social/service/qrcode_dark.JPG'
                          : 'https://data.swu.social/service/qrcode_light.JPG',
                      fit: BoxFit.contain,
                      placeholder: Container(
                        width: 280,
                        height: 350,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CupertinoActivityIndicator(radius: 16),
                              SizedBox(height: 16),
                              Text(
                                '正在加载二维码...',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      errorWidget: Container(
                        width: 280,
                        height: 350,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGrey6,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                CupertinoIcons.exclamationmark_triangle_fill,
                                color: CupertinoColors.systemRed,
                                size: 48,
                              ),
                              SizedBox(height: 16),
                              Text(
                                '二维码加载失败',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: CupertinoColors.label,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '请检查网络连接后重试',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: CupertinoColors.secondaryLabel,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 简洁提示
              Center(
                child: Text(
                  '轻点打开QQ群 · 长按查看选项',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDarkMode
                        ? Colors.white.withOpacity(0.5)
                        : Colors.black.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
