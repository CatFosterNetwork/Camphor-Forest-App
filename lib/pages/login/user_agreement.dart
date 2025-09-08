// lib/pages/login/user_agreement.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

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
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors
                                .black // 纯黑背景
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          if (htmlContent != null)
                            WebViewWidget(controller: webViewController),
                          if (isLoading)
                            const Center(child: CircularProgressIndicator()),
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

  Widget _buildAppBar(BuildContext context, bool isDarkMode) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '用户协议',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('无法打开邮件应用'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请手动复制邮箱地址并在您的邮件应用中联系我们：'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      emailAddress,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: emailAddress));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('邮箱地址已复制到剪贴板')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    tooltip: '复制邮箱地址',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// URL链接无法打开时的回退方案
  void _showUrlFallback(String url) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('无法打开链接'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请手动复制链接地址并在浏览器中访问：'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      url,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: url));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('链接已复制到剪贴板')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    tooltip: '复制链接',
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}
