import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_v2_android/main.dart';
import 'package:flutter_v2_android/core/v2ray/v2ray_service.dart';

/// 日志界面
class LogsScreen extends StatefulWidget {
  /// 构造函数
  const LogsScreen({Key? key}) : super(key: key);

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  // 日志内容
  final List<String> _logs = [];
  
  // 滚动控制器
  final ScrollController _scrollController = ScrollController();
  
  // 是否自动滚动到底部
  bool _autoScroll = true;
  
  @override
  void initState() {
    super.initState();
    
    // 获取V2Ray服务实例
    final v2rayService = Provider.of<ServerProvider>(context, listen: false)._serverService;
    
    // 订阅日志流
    v2rayService.getIt<V2RayService>().logStream.listen((log) {
      setState(() {
        _logs.add(log);
        
        // 如果日志太多，保留最新的200条
        if (_logs.length > 200) {
          _logs.removeRange(0, _logs.length - 200);
        }
        
        // 自动滚动到底部
        if (_autoScroll) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
    });
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('运行日志'),
        actions: [
          IconButton(
            icon: Icon(
              _autoScroll ? Icons.vertical_align_bottom : Icons.vertical_align_center,
              color: _autoScroll ? Theme.of(context).primaryColor : Colors.grey,
            ),
            tooltip: _autoScroll ? '自动滚动已开启' : '自动滚动已关闭',
            onPressed: () {
              setState(() {
                _autoScroll = !_autoScroll;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '复制日志',
            onPressed: _copyLogs,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: '清空日志',
            onPressed: _clearLogs,
          ),
        ],
      ),
      body: _logs.isEmpty
          ? _buildEmptyView()
          : _buildLogList(),
    );
  }
  
  /// 构建空视图
  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 80,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            '暂无日志',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '连接后将在此显示运行日志',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
  
  /// 构建日志列表
  Widget _buildLogList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _logs.length,
      itemBuilder: (context, index) {
        final log = _logs[index];
        return _buildLogItem(log, index);
      },
    );
  }
  
  /// 构建日志项
  Widget _buildLogItem(String log, int index) {
    // 根据日志内容设置颜色
    Color textColor = Colors.black87;
    
    if (log.contains('ERROR') || log.contains('错误') || log.contains('失败')) {
      textColor = Colors.red;
    } else if (log.contains('WARNING') || log.contains('警告')) {
      textColor = Colors.orange;
    } else if (log.contains('INFO') || log.contains('信息')) {
      textColor = Colors.blue;
    } else if (log.contains('DEBUG') || log.contains('调试')) {
      textColor = Colors.grey;
    } else if (log.contains('SUCCESS') || log.contains('成功')) {
      textColor = Colors.green;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '${index + 1}. ',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextSpan(
              text: log,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 复制日志
  void _copyLogs() {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没有日志可复制')),
      );
      return;
    }
    
    final text = _logs.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('日志已复制到剪贴板')),
    );
  }
  
  /// 清空日志
  void _clearLogs() {
    if (_logs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('日志已经是空的')),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空日志'),
        content: const Text('确定要清空所有日志吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _logs.clear();
              });
              Navigator.of(context).pop();
            },
            child: const Text('清空'),
          ),
        ],
      ),
    );
  }
} 