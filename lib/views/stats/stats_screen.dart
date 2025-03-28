import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_v2_android/core/vpn/vpn_service.dart';
import 'package:flutter_v2_android/main.dart';
import 'package:flutter_v2_android/services/connection/connection_service.dart';

/// 统计界面
class StatsScreen extends StatelessWidget {
  /// 构造函数
  const StatsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('流量统计'),
      ),
      body: Consumer<ConnectionProvider>(
        builder: (context, connectionProvider, child) {
          final status = connectionProvider.status;
          final stats = connectionProvider.trafficStats;
          
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatusIndicator(status),
                const SizedBox(height: 32),
                if (status == ConnectionStatus.connected) ...[
                  _buildTrafficStats(stats),
                ] else ...[
                  const Text(
                    '未连接',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
  
  /// 构建状态指示器
  Widget _buildStatusIndicator(ConnectionStatus status) {
    IconData iconData;
    Color color;
    String text;
    
    switch (status) {
      case ConnectionStatus.connected:
        iconData = Icons.check_circle;
        color = Colors.green;
        text = '已连接';
        break;
      case ConnectionStatus.connecting:
        iconData = Icons.sync;
        color = Colors.orange;
        text = '连接中';
        break;
      case ConnectionStatus.disconnecting:
        iconData = Icons.sync_disabled;
        color = Colors.orange;
        text = '断开中';
        break;
      case ConnectionStatus.error:
        iconData = Icons.error;
        color = Colors.red;
        text = '连接错误';
        break;
      case ConnectionStatus.disconnected:
      default:
        iconData = Icons.cancel;
        color = Colors.grey;
        text = '未连接';
        break;
    }
    
    return Column(
      children: [
        Icon(
          iconData,
          color: color,
          size: 48,
        ),
        const SizedBox(height: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
  
  /// 构建流量统计卡片
  Widget _buildTrafficStats(TrafficStats stats) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTrafficCard(
              icon: Icons.arrow_upward,
              title: '上传速度',
              value: _formatSpeed(stats.uploadSpeed),
              color: Colors.blue,
            ),
            const SizedBox(width: 16),
            _buildTrafficCard(
              icon: Icons.arrow_downward,
              title: '下载速度',
              value: _formatSpeed(stats.downloadSpeed),
              color: Colors.green,
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildTrafficCard(
              icon: Icons.upload_file,
              title: '总上传',
              value: _formatBytes(stats.totalUpload),
              color: Colors.indigo,
            ),
            const SizedBox(width: 16),
            _buildTrafficCard(
              icon: Icons.download,
              title: '总下载',
              value: _formatBytes(stats.totalDownload),
              color: Colors.teal,
            ),
          ],
        ),
      ],
    );
  }
  
  /// 构建流量卡片
  Widget _buildTrafficCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 格式化速度
  String _formatSpeed(int bytesPerSecond) {
    if (bytesPerSecond < 1024) {
      return '$bytesPerSecond B/s';
    } else if (bytesPerSecond < 1024 * 1024) {
      final kb = bytesPerSecond / 1024;
      return '${kb.toStringAsFixed(1)} KB/s';
    } else {
      final mb = bytesPerSecond / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB/s';
    }
  }
  
  /// 格式化字节数
  String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      final kb = bytes / 1024;
      return '${kb.toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      final mb = bytes / (1024 * 1024);
      return '${mb.toStringAsFixed(1)} MB';
    } else {
      final gb = bytes / (1024 * 1024 * 1024);
      return '${gb.toStringAsFixed(1)} GB';
    }
  }
} 