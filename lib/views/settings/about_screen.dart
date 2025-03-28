import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 关于界面
class AboutScreen extends StatefulWidget {
  /// 构造函数
  const AboutScreen({Key? key}) : super(key: key);

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  /// 加载应用信息
  Future<void> _loadPackageInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('关于'),
      ),
      body: ListView(
        children: [
          // 应用图标和版本
          _buildAppInfo(),
          
          // 分隔线
          const Divider(),
          
          // 项目介绍
          _buildSection(
            title: '项目介绍',
            content: 'Flutter V2ray Android 是一个基于 Flutter 开发的 V2Ray 客户端，'
                '支持多协议，多服务器管理，完全开源。\n\n'
                '本项目遵循 GPL-3.0 开源协议。',
          ),
          
          // 主要特性
          _buildSection(
            title: '主要特性',
            content: '• 支持多种协议（VMess, VLess, Trojan, Shadowsocks等）\n'
                '• 支持服务器订阅\n'
                '• 支持自定义路由规则\n'
                '• 流量统计和速度显示\n'
                '• 日志查看\n'
                '• 完全开源，安全可靠',
          ),
          
          // 贡献者
          _buildSection(
            title: '贡献者',
            content: '感谢所有为本项目做出贡献的开发者。',
          ),
          
          // 项目源码
          _buildSection(
            title: '项目源码',
            content: '本项目源码托管在 GitHub，欢迎 Star 和贡献代码。',
            actions: [
              TextButton(
                onPressed: () => _launchUrl('https://github.com/yourusername/flutter-v2-android'),
                child: const Text('查看源码'),
              ),
              TextButton(
                onPressed: () => _launchUrl('https://github.com/yourusername/flutter-v2-android/issues'),
                child: const Text('反馈问题'),
              ),
            ],
          ),
          
          // 版权信息
          _buildSection(
            title: '版权信息',
            content: '本项目基于 GPL-3.0 协议开源，使用了以下开源项目：\n\n'
                '• V2Ray / Xray Core - 核心代理功能\n'
                '• Flutter - UI框架\n'
                '• Provider - 状态管理\n'
                '• shared_preferences - 数据存储\n'
                '• path_provider - 文件路径\n'
                '• url_launcher - URL 处理\n'
                '• package_info_plus - 包信息',
          ),
          
          // 免责声明
          _buildSection(
            title: '免责声明',
            content: '本软件仅供科研、学习、教育等合法用途使用。使用本软件时，请遵守当地法律法规。'
                '开发者不对任何人使用本软件所产生的任何责任负责。',
          ),
          
          // 鸣谢
          _buildSection(
            title: '鸣谢',
            content: '特别感谢 V2Ray/Xray 项目的所有贡献者。',
            actions: [
              TextButton(
                onPressed: () => _launchUrl('https://www.v2fly.org/'),
                child: const Text('V2Fly 官网'),
              ),
              TextButton(
                onPressed: () => _launchUrl('https://github.com/XTLS/Xray-core'),
                child: const Text('Xray Core'),
              ),
            ],
          ),
          
          // 底部空间
          const SizedBox(height: 20),
        ],
      ),
    );
  }
  
  /// 构建应用信息部分
  Widget _buildAppInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 应用图标
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/images/app_icon.png',
              width: 80,
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: Theme.of(context).primaryColor,
                  child: Icon(
                    Icons.vpn_lock,
                    size: 50,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // 应用名称
          const Text(
            'Flutter V2ray Android',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          // 版本号
          Text(
            '版本 $_version (Build $_buildNumber)',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建信息区块
  Widget _buildSection({
    required String title,
    required String content,
    List<Widget>? actions,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
          if (actions != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions,
            ),
          ],
        ],
      ),
    );
  }
  
  /// 打开URL
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('无法打开链接: $url')),
      );
    }
  }
} 