// lib/pages/settings/about_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gal/gal.dart';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
// import 'package:flutter_svg/flutter_svg.dart'; // 暂时不使用SVG
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:go_router/go_router.dart'; // 暂时不使用

import '../../core/config/providers/theme_config_provider.dart';
import '../../core/widgets/theme_aware_scaffold.dart';
import '../../core/widgets/cached_image.dart';
// import '../../core/constants/route_constants.dart'; // 暂时不使用

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
      forceStatusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark, // 强制状态栏图标适配
      appBar: ThemeAwareAppBar(
        title: '关于',
      ),
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
                  borderRadius: BorderRadius.circular(80), // 100%圆角弧度（半径为容器宽度的一半）
                  color: isDarkMode ? const Color(0xFF202125) : Colors.grey.shade200,
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
                    _buildInfoRow(
                      '应用版本',
                      version,
                      isDarkMode,
                      isFirst: true,
                    ),
                    
                    // 系统版本（Flutter相当于微信版本）
                    _buildInfoRow(
                      'Flutter版本',
                      _getFlutterVersion(),
                      isDarkMode,
                    ),
                    
                    // Dart版本（相当于SDK版本）
                    _buildInfoRow(
                      'Dart版本',
                      _getDartVersion(),
                      isDarkMode,
                    ),
                    
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
    // 如果有用户协议页面路由，可以导航过去
    // context.push(RouteConstants.userAgreement);
    
    // 临时显示提示
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('用户协议功能开发中'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// 显示官方群二维码
  void _showOfficialGroup(BuildContext context) {
    final isDarkMode = ref.read(effectiveIsDarkModeProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
        title: Text(
          '官方Q群',
          style: TextStyle(
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
                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
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
                      color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
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
                              color: isDarkMode ? Colors.white70 : Colors.black54,
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
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '关闭',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
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
      // QQ群号：你需要替换为实际的群号
      const String groupNumber = '837036146'; // 请替换为实际的群号
      
      // 尝试直接打开QQ应用
      final Uri qqGroupUri = Uri.parse('mqqopensdkapi://bizAgent/qm/qr?url=http%3A%2F%2Fqm.qq.com%2Fcgi-bin%2Fqm%2Fqr%3Ffrom%3Dapp%26p%3Dandroid%26jump_from%3Dwebapi%26k%3D$groupNumber');
      final Uri webUri = Uri.parse('https://qm.qq.com/cgi-bin/qm/qr?k=$groupNumber');
      
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
        const String groupNumber = '837036146';
        await Clipboard.setData(ClipboardData(text: 'https://qm.qq.com/cgi-bin/qm/qr?k=$groupNumber'));
        
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _buildSaveProgressDialog(isDarkMode),
      );

      final String imageUrl = isDarkMode 
        ? 'https://data.swu.social/service/qrcode_dark.JPG'
        : 'https://data.swu.social/service/qrcode_light.JPG';
      
      // 检查并请求存储权限
      final bool hasPermission = await _checkAndRequestStoragePermission();
      
      if (!hasPermission) {
        if (mounted) {
          Navigator.of(context).pop(); // 关闭进度对话框
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要存储权限才能保存图片到相册'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('二维码已成功保存到相册'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // 关闭进度对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// 检查并请求存储权限
  Future<bool> _checkAndRequestStoragePermission() async {
    if (Platform.isAndroid) {
      // Android 13+ 使用新的照片权限
      if (await _isAndroid13OrHigher()) {
        final status = await Permission.photos.status;
        if (status.isGranted) {
          return true;
        } else if (status.isDenied) {
          final result = await Permission.photos.request();
          return result.isGranted;
        } else if (status.isPermanentlyDenied) {
          await _showPermissionDeniedDialog();
          return false;
        }
      } else {
        // Android 12 及以下使用存储权限
        final status = await Permission.storage.status;
        if (status.isGranted) {
          return true;
        } else if (status.isDenied) {
          final result = await Permission.storage.request();
          return result.isGranted;
        } else if (status.isPermanentlyDenied) {
          await _showPermissionDeniedDialog();
          return false;
        }
      }
    } else if (Platform.isIOS) {
      // iOS 使用照片权限
      final status = await Permission.photos.status;
      if (status.isGranted) {
        return true;
      } else if (status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted;
      } else if (status.isPermanentlyDenied) {
        await _showPermissionDeniedDialog();
        return false;
      }
    }
    
    return false;
  }

  /// 检查是否为Android 13或更高版本
  Future<bool> _isAndroid13OrHigher() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      return androidInfo.version.sdkInt >= 33;
    }
    return false;
  }

  /// 显示权限被拒绝的对话框
  Future<void> _showPermissionDeniedDialog() async {
    if (!mounted) return;
    
    final isDarkMode = ref.read(effectiveIsDarkModeProvider);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
        title: Text(
          '权限被拒绝',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          '需要相册权限才能保存二维码图片。请在设置中手动开启权限。',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text(
              '去设置',
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
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
  Future<void> _saveImageToGallery(Uint8List imageBytes, bool isDarkMode) async {
    // 创建临时文件
    final tempDir = await getTemporaryDirectory();
    final fileName = 'qrcode_${isDarkMode ? 'dark' : 'light'}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(imageBytes);
    
    // 使用gal保存到相册
    await Gal.putImage(file.path);
    
    // 删除临时文件
    await file.delete();
  }

  /// 构建保存进度对话框
  Widget _buildSaveProgressDialog(bool isDarkMode) {
    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF202125) : Colors.white,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          Text(
            '正在保存二维码...',
            style: TextStyle(
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  /// 打开系统二维码扫描器
  void _openSystemScanner() async {
    try {
      // 尝试打开不同的扫描应用
      final List<String> scannerApps = [
        // ZXing Barcode Scanner
        'intent://scan/#Intent;scheme=zxing;package=com.google.zxing.client.android;end',
        // 通用扫描Intent
        'intent://scan/#Intent;action=com.google.zxing.client.android.SCAN;end',
        // 相机应用扫描
        'intent:#Intent;action=android.media.action.IMAGE_CAPTURE;end',
      ];
      
      bool scannerOpened = false;
      
      for (String intentUrl in scannerApps) {
        try {
          final Uri scannerUri = Uri.parse(intentUrl);
          if (await canLaunchUrl(scannerUri)) {
            await launchUrl(scannerUri);
            scannerOpened = true;
            break;
          }
        } catch (e) {
          // 继续尝试下一个
          continue;
        }
      }
      
      if (!scannerOpened) {
        // 如果无法打开任何扫描器，提示用户手动操作
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('请使用手机相机或其他扫描应用扫描二维码'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('无法打开系统扫描器，请使用其他扫描应用'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}