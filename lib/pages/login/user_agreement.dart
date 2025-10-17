// lib/pages/login/user_agreement.dart

import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:camphor_forest/core/services/toast_service.dart';

import '../../core/config/providers/theme_config_provider.dart';
import '../../widgets/app_background.dart';

class UserAgreementPage extends ConsumerStatefulWidget {
  const UserAgreementPage({super.key});

  @override
  ConsumerState<UserAgreementPage> createState() => _UserAgreementPageState();
}

class _UserAgreementPageState extends ConsumerState<UserAgreementPage> {
  late WebViewController webViewController;
  String? htmlContent;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    _loadHtmlContent();
  }

  void _initializeWebView() {
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            // 处理邮件链接
            if (request.url.startsWith('mailto:')) {
              _launchEmail(request.url);
              return NavigationDecision.prevent;
            }
            // 处理其他外部链接
            if (request.url.startsWith('http://') ||
                request.url.startsWith('https://')) {
              _launchUrl(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
  }

  Future<void> _loadHtmlContent() async {
    try {
      final content = await rootBundle.loadString(
        'lib/pages/login/userAgreement.txt',
      );
      final isDarkMode = ref.read(effectiveIsDarkModeProvider);
      final processedContent = _processHtmlContent(content, isDarkMode);

      setState(() {
        htmlContent = processedContent;
      });

      await webViewController.loadHtmlString(processedContent);
    } catch (e) {
      debugPrint('Error loading user agreement: $e');
    }
  }

  /// 当主题变化时重新加载内容
  Future<void> _reloadContentWithTheme(bool isDarkMode) async {
    try {
      final content = await rootBundle.loadString(
        'lib/pages/login/userAgreement.txt',
      );
      final processedContent = _processHtmlContent(content, isDarkMode);

      setState(() {
        htmlContent = processedContent;
      });

      await webViewController.loadHtmlString(processedContent);
    } catch (e) {
      debugPrint('Error reloading user agreement with theme: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    // 当深色模式变化时重新加载内容
    ref.listen(effectiveIsDarkModeProvider, (previous, next) {
      if (previous != next && htmlContent != null) {
        _reloadContentWithTheme(next);
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 背景
          const AppBackground(blur: false),
          // 内容
          SafeArea(
            child: Column(
              children: [
                // 导航栏
                _buildAppBar(context, isDarkMode),
                // 协议内容
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? const Color(0xFF1C1C1E) // iOS深色模式背景色
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode 
                              ? Colors.black.withOpacity(0.3)
                              : Colors.black.withOpacity(0.08),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                          spreadRadius: -4,
                        ),
                      ],
                      border: Border.all(
                        color: isDarkMode 
                            ? Colors.white.withOpacity(0.05)
                            : Colors.black.withOpacity(0.04),
                        width: 0.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        children: [
                          if (htmlContent != null)
                            WebViewWidget(controller: webViewController),
                          if (isLoading) _buildLoadingIndicator(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建平台适配的加载指示器
  Widget _buildLoadingIndicator() {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDarkMode 
                ? const Color(0xFF1C1C1E).withOpacity(0.95)
                : Colors.white.withOpacity(0.95),
            isDarkMode 
                ? const Color(0xFF1C1C1E).withOpacity(0.98)
                : Colors.white.withOpacity(0.98),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? const Color(0xFF2C2C2E)
                : Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.4)
                    : Colors.black.withOpacity(0.12),
                blurRadius: 28,
                offset: const Offset(0, 8),
                spreadRadius: -6,
              ),
            ],
            border: Border.all(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.08)
                  : Colors.black.withOpacity(0.06),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 平台分离的加载指示器
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.04)
                      : Colors.blue.withOpacity(0.08),
                ),
                child: Center(
                  child: Platform.isIOS
                      ? const CupertinoActivityIndicator(
                          radius: 14,
                          color: CupertinoColors.activeBlue,
                        )
                      : SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: isDarkMode 
                                ? Colors.blue[400]
                                : Colors.blue[600],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '正在加载用户协议',
                style: TextStyle(
                  fontSize: 15,
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.85)
                      : Colors.black87,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.2,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '请稍候...',
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.5)
                      : Colors.black54,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDarkMode) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDarkMode 
            ? Colors.black.withOpacity(0.8)
            : Colors.white.withOpacity(0.9),
        border: Border(
          bottom: BorderSide(
            color: isDarkMode 
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // 统一设计的返回按钮
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.06),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                borderRadius: BorderRadius.circular(18),
                child: Icon(
                  Platform.isIOS ? CupertinoIcons.back : Icons.arrow_back,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  size: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              '用户协议',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
                letterSpacing: -0.3,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 处理HTML内容，适配深色模式和移动端显示
  String _processHtmlContent(String htmlContent, bool isDarkMode) {
    String processedContent = htmlContent;

    // 添加移动端适配的meta标签和基础样式
    final additionalStyles =
        '''
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <style>
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          font-size: 14px;
          line-height: 1.6;
          margin: 16px;
          padding: 0;
          ${isDarkMode ? 'background-color: #000000; color: #FFFFFF;' : 'background-color: #FFFFFF; color: #333;'}
        }
        
        h1, h2, h3, h4, h5, h6 {
          ${isDarkMode ? 'color: #FFFFFF;' : 'color: #000000;'}
          margin-top: 20px;
          margin-bottom: 10px;
        }
        
        p {
          margin-bottom: 12px;
        }
        
        strong, b {
          ${isDarkMode ? 'color: #FFFFFF;' : 'color: #000000;'}
        }
        
        table {
          width: 100%;
          border-collapse: collapse;
          margin: 12px 0;
        }
        
        td, th {
          border: 1px solid ${isDarkMode ? '#555' : '#ddd'};
          padding: 8px;
          text-align: left;
        }
        
        th {
          ${isDarkMode ? 'background-color: #222; color: #FFFFFF;' : 'background-color: #f5f5f5; color: #000000;'}
          font-weight: bold;
        }
        
        ul, ol {
          padding-left: 20px;
          margin-bottom: 12px;
        }
        
        li {
          margin-bottom: 4px;
        }
        
        /* 处理Word生成的样式 */
        .MsoNormal {
          margin: 0 0 12px 0;
        }
        
        /* 移除不必要的Office样式 */
        o\\:*, v\\:*, w\\:* {
          display: none;
        }
      </style>
    ''';

    // 在head标签中插入额外样式
    if (processedContent.contains('<head>')) {
      processedContent = processedContent.replaceFirst(
        '<head>',
        '<head>$additionalStyles',
      );
    } else {
      // 如果没有head标签，在html标签后添加
      processedContent = processedContent.replaceFirst(
        '<html',
        '$additionalStyles<html',
      );
    }

    if (isDarkMode) {
      // 将深色文字替换为浅色文字
      processedContent = processedContent.replaceAllMapped(
        RegExp(r'color:\s*#([0-9A-Fa-f]{6})', caseSensitive: false),
        (match) {
          final colorHex = match.group(1)!;
          // 如果是深色（接近黑色），替换为白色
          final brightness = _calculateBrightness(colorHex);
          if (brightness < 128) {
            return 'color:#FFFFFF';
          }
          return match.group(0)!;
        },
      );

      // 替换windowtext和black为白色
      processedContent = processedContent.replaceAll(
        RegExp(r'color:\s*(windowtext|black|#000000)', caseSensitive: false),
        'color:#FFFFFF',
      );

      // 替换背景色为黑色
      processedContent = processedContent.replaceAll(
        RegExp(r'background-color:\s*(#FFFFFF|white)', caseSensitive: false),
        'background-color:#000000',
      );

      // 确保任何浅色背景都变成黑色
      processedContent = processedContent.replaceAll(
        RegExp(
          r'background-color:\s*#[fF][0-9a-fA-F]{5}',
          caseSensitive: false,
        ),
        'background-color:#000000',
      );
    }

    return processedContent;
  }

  /// 计算颜色亮度
  int _calculateBrightness(String colorHex) {
    final r = int.parse(colorHex.substring(0, 2), radix: 16);
    final g = int.parse(colorHex.substring(2, 4), radix: 16);
    final b = int.parse(colorHex.substring(4, 6), radix: 16);
    return (r * 299 + g * 587 + b * 114) ~/ 1000;
  }

  /// 启动邮件应用
  Future<void> _launchEmail(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showEmailFallback(url);
      }
    } catch (e) {
      debugPrint('Error launching email: $e');
      _showEmailFallback(url);
    }
  }

  /// 启动外部链接
  Future<void> _launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showUrlFallback(url);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      _showUrlFallback(url);
    }
  }

  /// 邮件链接无法打开时的回退方案
  void _showEmailFallback(String emailUrl) {
    if (!mounted) return;

    // 从 mailto: 链接中提取邮箱地址
    final emailAddress = emailUrl.replaceFirst('mailto:', '').split('?')[0];
    final isDarkMode = ref.read(effectiveIsDarkModeProvider);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? const Color(0xFF2C2C2E)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
                spreadRadius: -8,
              ),
            ],
            border: Border.all(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Text(
                '无法打开邮件应用',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              // 描述
              Text(
                '请手动复制邮箱地址并在您的邮件应用中联系我们：',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // 邮箱地址容器
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.06),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        emailAddress,
                        style: TextStyle(
                          fontFamily: 'SF Mono',
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: emailAddress));
                          Navigator.of(context).pop();
                          ToastService.show(
                            '邮箱地址已复制到剪贴板',
                            backgroundColor: isDarkMode
                                ? const Color(0xFF2C2C2E)
                                : Colors.black87,
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Platform.isIOS 
                                ? CupertinoIcons.doc_on_clipboard
                                : Icons.copy_rounded,
                            size: 18,
                            color: isDarkMode 
                                ? Colors.blue[400]
                                : Colors.blue[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 确定按钮
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                            ? Colors.blue[400]
                            : Colors.blue[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '确定',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// URL链接无法打开时的回退方案
  void _showUrlFallback(String url) {
    if (!mounted) return;

    final isDarkMode = ref.read(effectiveIsDarkModeProvider);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? const Color(0xFF2C2C2E)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.15),
                blurRadius: 32,
                offset: const Offset(0, 12),
                spreadRadius: -8,
              ),
            ],
            border: Border.all(
              color: isDarkMode 
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              width: 0.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题
              Text(
                '无法打开链接',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : Colors.black87,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 16),
              // 描述
              Text(
                '请手动复制链接地址并在浏览器中访问：',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode 
                      ? Colors.white.withOpacity(0.7)
                      : Colors.black54,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // URL容器
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode 
                        ? Colors.white.withOpacity(0.1)
                        : Colors.black.withOpacity(0.06),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        url,
                        style: TextStyle(
                          fontFamily: 'SF Mono',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDarkMode ? Colors.white : Colors.black87,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: url));
                          Navigator.of(context).pop();
                          ToastService.show(
                            '链接已复制到剪贴板',
                            backgroundColor: isDarkMode
                                ? const Color(0xFF2C2C2E)
                                : Colors.black87,
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Platform.isIOS 
                                ? CupertinoIcons.doc_on_clipboard
                                : Icons.copy_rounded,
                            size: 18,
                            color: isDarkMode 
                                ? Colors.blue[400]
                                : Colors.blue[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 确定按钮
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                            ? Colors.blue[400]
                            : Colors.blue[600],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '确定',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
