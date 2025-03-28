import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_v2_android/main.dart';
import 'package:flutter_v2_android/models/server/server_config.dart';
import 'package:flutter_v2_android/services/connection/connection_service.dart';

/// 服务器列表界面
class ServerListScreen extends StatelessWidget {
  /// 构造函数
  const ServerListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('服务器列表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '测试延迟',
            onPressed: () => _testAllLatency(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加服务器',
            onPressed: () => _addServer(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(context, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import_clipboard',
                child: Text('从剪贴板导入'),
              ),
              const PopupMenuItem(
                value: 'import_subscription',
                child: Text('从订阅导入'),
              ),
              const PopupMenuItem(
                value: 'export_all',
                child: Text('导出全部服务器'),
              ),
              const PopupMenuItem(
                value: 'delete_all',
                child: Text('删除全部服务器'),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<ServerProvider>(
        builder: (context, serverProvider, child) {
          final servers = serverProvider.servers;
          
          if (servers.isEmpty) {
            return _buildEmptyView();
          }
          
          return ListView.builder(
            itemCount: servers.length,
            itemBuilder: (context, index) {
              final server = servers[index];
              final isSelected = server.id == serverProvider.selectedServer?.id;
              
              return _buildServerItem(context, server, isSelected);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _connectToSelectedServer(context),
        child: const Icon(Icons.play_arrow),
        tooltip: '连接',
      ),
    );
  }
  
  /// 构建空视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.dns_outlined,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            '没有服务器配置',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右上角的加号添加服务器',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建服务器列表项
  Widget _buildServerItem(BuildContext context, ServerConfig server, bool isSelected) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
      elevation: isSelected ? 2 : 1,
      child: ListTile(
        leading: _buildServerTypeIcon(server.protocol),
        title: Text(
          server.remarks.isNotEmpty ? server.remarks : server.address,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text('${server.address}:${server.port}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (server.latency != null) ...[
              _buildLatencyIndicator(server.latency!),
              const SizedBox(width: 8),
            ],
            PopupMenuButton<String>(
              onSelected: (value) => _handleServerAction(context, server, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('编辑'),
                ),
                const PopupMenuItem(
                  value: 'test',
                  child: Text('测试延迟'),
                ),
                const PopupMenuItem(
                  value: 'qrcode',
                  child: Text('显示二维码'),
                ),
                const PopupMenuItem(
                  value: 'copy',
                  child: Text('复制分享链接'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('删除'),
                ),
              ],
            ),
          ],
        ),
        selected: isSelected,
        onTap: () => _selectServer(context, server),
      ),
    );
  }
  
  /// 构建服务器类型图标
  Widget _buildServerTypeIcon(String protocol) {
    IconData iconData;
    Color iconColor;
    
    switch (protocol.toLowerCase()) {
      case 'vmess':
        iconData = Icons.security;
        iconColor = Colors.blue;
        break;
      case 'vless':
        iconData = Icons.enhanced_encryption;
        iconColor = Colors.indigo;
        break;
      case 'shadowsocks':
        iconData = Icons.vpn_key;
        iconColor = Colors.purple;
        break;
      case 'trojan':
        iconData = Icons.shield;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.public;
        iconColor = Colors.grey;
    }
    
    return CircleAvatar(
      backgroundColor: iconColor.withOpacity(0.2),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }
  
  /// 构建延迟指示器
  Widget _buildLatencyIndicator(int latency) {
    Color color;
    String text;
    
    if (latency < 0) {
      color = Colors.grey;
      text = '超时';
    } else if (latency < 200) {
      color = Colors.green;
      text = '$latency ms';
    } else if (latency < 500) {
      color = Colors.orange;
      text = '$latency ms';
    } else {
      color = Colors.red;
      text = '$latency ms';
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  /// 处理服务器列表菜单动作
  void _handleMenuAction(BuildContext context, String action) {
    final serverProvider = Provider.of<ServerProvider>(context, listen: false);
    
    switch (action) {
      case 'import_clipboard':
        // 从剪贴板导入
        _importFromClipboard(context);
        break;
      case 'import_subscription':
        // 从订阅导入
        _importFromSubscription(context);
        break;
      case 'export_all':
        // 导出全部服务器
        _exportAllServers(context);
        break;
      case 'delete_all':
        // 删除全部服务器
        _showDeleteAllConfirmDialog(context);
        break;
    }
  }
  
  /// 处理服务器操作
  void _handleServerAction(BuildContext context, ServerConfig server, String action) {
    final serverProvider = Provider.of<ServerProvider>(context, listen: false);
    
    switch (action) {
      case 'edit':
        // 编辑服务器
        _editServer(context, server);
        break;
      case 'test':
        // 测试延迟
        _testServerLatency(context, server);
        break;
      case 'qrcode':
        // 显示二维码
        _showQrCode(context, server);
        break;
      case 'copy':
        // 复制分享链接
        _copyShareLink(context, server);
        break;
      case 'delete':
        // 删除服务器
        _showDeleteConfirmDialog(context, server);
        break;
    }
  }
  
  /// 添加服务器
  void _addServer(BuildContext context) {
    // TODO: 实现添加服务器功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('添加服务器功能尚未实现')),
    );
  }
  
  /// 编辑服务器
  void _editServer(BuildContext context, ServerConfig server) {
    // TODO: 实现编辑服务器功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑服务器功能尚未实现')),
    );
  }
  
  /// 测试服务器延迟
  Future<void> _testServerLatency(BuildContext context, ServerConfig server) async {
    try {
      // 显示加载指示器
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在测试延迟...')),
      );
      
      final connectionService = Provider.of<ConnectionProvider>(context, listen: false)._connectionService;
      final latency = await connectionService.testServerLatency(server);
      
      if (latency != null) {
        // 更新延迟
        Provider.of<ServerProvider>(context, listen: false)
            .updateServerLatency(server.id, latency);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('测试延迟失败: $e')),
      );
    }
  }
  
  /// 测试所有服务器延迟
  Future<void> _testAllLatency(BuildContext context) async {
    try {
      // 显示加载指示器
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正在测试所有服务器延迟...')),
      );
      
      final connectionService = Provider.of<ConnectionProvider>(context, listen: false)._connectionService;
      await connectionService.testAllServersLatency();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('测试延迟失败: $e')),
      );
    }
  }
  
  /// 显示二维码
  void _showQrCode(BuildContext context, ServerConfig server) {
    // TODO: 实现显示二维码功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('显示二维码功能尚未实现')),
    );
  }
  
  /// 复制分享链接
  void _copyShareLink(BuildContext context, ServerConfig server) {
    // TODO: 实现复制分享链接功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('复制分享链接功能尚未实现')),
    );
  }
  
  /// 显示删除确认对话框
  void _showDeleteConfirmDialog(BuildContext context, ServerConfig server) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除服务器'),
        content: Text('确定要删除服务器 "${server.remarks.isNotEmpty ? server.remarks : server.address}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Provider.of<ServerProvider>(context, listen: false)
                  .deleteServer(server.id);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  /// 显示删除所有确认对话框
  void _showDeleteAllConfirmDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除所有服务器'),
        content: const Text('确定要删除所有服务器吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: 实现删除所有服务器功能
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('删除所有服务器功能尚未实现')),
              );
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  /// 从剪贴板导入
  void _importFromClipboard(BuildContext context) {
    // TODO: 实现从剪贴板导入功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('从剪贴板导入功能尚未实现')),
    );
  }
  
  /// 从订阅导入
  void _importFromSubscription(BuildContext context) {
    // TODO: 实现从订阅导入功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('从订阅导入功能尚未实现')),
    );
  }
  
  /// 导出所有服务器
  void _exportAllServers(BuildContext context) {
    // TODO: 实现导出所有服务器功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出所有服务器功能尚未实现')),
    );
  }
  
  /// 选择服务器
  void _selectServer(BuildContext context, ServerConfig server) {
    Provider.of<ServerProvider>(context, listen: false)
        .selectServer(server.id);
  }
  
  /// 连接到选中的服务器
  void _connectToSelectedServer(BuildContext context) {
    final selectedServer = Provider.of<ServerProvider>(context, listen: false).selectedServer;
    if (selectedServer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一个服务器')),
      );
      return;
    }
    
    final connectionProvider = Provider.of<ConnectionProvider>(context, listen: false);
    final settings = Provider.of<AppSettingsProvider>(context, listen: false).settings;
    
    if (connectionProvider.status == ConnectionStatus.connected) {
      // 已连接，断开连接
      connectionProvider.disconnect();
    } else {
      // 未连接，建立连接
      connectionProvider.connect(settings);
    }
  }
} 