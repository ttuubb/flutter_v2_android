import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_v2_android/main.dart';
import 'package:flutter_v2_android/models/config/server_config.dart';
import 'package:flutter_v2_android/views/servers/server_list_screen.dart';
import 'package:flutter_v2_android/views/settings/settings_screen.dart';
import 'package:flutter_v2_android/views/stats/stats_screen.dart';
import 'package:flutter_v2_android/views/logs/logs_screen.dart';
import 'package:flutter_v2_android/views/subscription/subscription_list_screen.dart';

/// 应用主界面
class HomeScreen extends StatefulWidget {
  /// 构造函数
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 当前选中的底部导航索引
  int _currentIndex = 0;
  
  // 页面列表
  late final List<Widget> _pages;
  
  // 页面标题
  final List<String> _titles = [
    '服务器',
    '订阅',
    '统计',
    '日志',
    '设置',
  ];
  
  @override
  void initState() {
    super.initState();
    
    // 初始化页面
    _pages = [
      const ServerListScreen(),
      const SubscriptionListScreen(),
      const StatsScreen(),
      const LogsScreen(),
      const SettingsScreen(),
    ];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.dns, '服务器'),
            _buildNavItem(1, Icons.rss_feed, '订阅'),
            _buildConnectButton(),
            _buildNavItem(3, Icons.article, '日志'),
            _buildNavItem(4, Icons.settings, '设置'),
          ],
        ),
      ),
      floatingActionButton: null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
  
  /// 构建导航项
  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentIndex == index;
    
    return InkWell(
      onTap: () => _onNavItemTapped(index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建连接按钮
  Widget _buildConnectButton() {
    return Consumer<ConnectionStateProvider>(
      builder: (context, connectionProvider, child) {
        final isConnected = connectionProvider.isConnected;
        final error = connectionProvider.connectionError;
        
        Color color;
        IconData icon;
        String text;
        
        if (error != null) {
          color = Colors.red;
          icon = Icons.error;
          text = '错误';
        } else if (isConnected) {
          color = Colors.green;
          icon = Icons.link;
          text = '已连接';
        } else {
          color = Colors.grey;
          icon = Icons.link_off;
          text = '未连接';
        }
        
        return InkWell(
          onTap: _toggleConnection,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
                Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 处理导航项点击
  void _onNavItemTapped(int index) {
    if (index == 2) {
      // 点击统计菜单
      setState(() {
        _currentIndex = 2;
      });
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }
  
  /// 切换连接状态
  void _toggleConnection() async {
    final connectionProvider = Provider.of<ConnectionStateProvider>(context, listen: false);
    final serverProvider = Provider.of<ServerProvider>(context, listen: false);
    
    final servers = serverProvider.servers;
    if (servers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加一个服务器')),
      );
      return;
    }
    
    if (connectionProvider.isConnected) {
      // 断开连接
      await connectionProvider.disconnect();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已断开连接')),
      );
    } else {
      // 建立连接
      // 如果有上次使用的服务器，优先使用，否则使用第一个服务器
      final server = connectionProvider.currentServer ?? servers.first;
      
      // 显示连接中提示
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在连接服务器...')),
      );
      
      // 尝试连接
      final result = await connectionProvider.connect(server);
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('连接成功')),
        );
      } else {
        final error = connectionProvider.connectionError ?? '未知错误';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('连接失败: $error')),
        );
      }
    }
  }
} 