import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_v2_android/main.dart';
import 'package:flutter_v2_android/models/config/subscription.dart';
import 'package:flutter_v2_android/views/subscription/subscription_edit_screen.dart';

/// 订阅列表界面
class SubscriptionListScreen extends StatelessWidget {
  /// 构造函数
  const SubscriptionListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('订阅管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '更新所有订阅',
            onPressed: () => _updateAllSubscriptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: '添加订阅',
            onPressed: () => _navigateToAddSubscription(context),
          ),
        ],
      ),
      body: Consumer<SubscriptionProvider>(
        builder: (context, subscriptionProvider, child) {
          final subscriptions = subscriptionProvider.subscriptions;
          
          if (subscriptions.isEmpty) {
            return _buildEmptyView();
          }
          
          return RefreshIndicator(
            onRefresh: () => _updateAllSubscriptions(context),
            child: ListView.builder(
              itemCount: subscriptions.length,
              itemBuilder: (context, index) {
                final subscription = subscriptions[index];
                return _buildSubscriptionItem(context, subscription);
              },
            ),
          );
        },
      ),
    );
  }
  
  /// 构建空视图
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rss_feed,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          const Text(
            '没有订阅',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '点击右上角添加按钮添加订阅',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('添加订阅'),
            onPressed: (context) => _navigateToAddSubscription(context),
          ),
        ],
      ),
    );
  }
  
  /// 构建订阅项
  Widget _buildSubscriptionItem(BuildContext context, Subscription subscription) {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final isUpdating = subscriptionProvider.isUpdating(subscription.id);
    final lastUpdateStatus = subscriptionProvider.getLastUpdateStatus(subscription.id);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Dismissible(
        key: Key(subscription.id),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) => _confirmDelete(context, subscription),
        onDismissed: (direction) {
          subscriptionProvider.deleteSubscription(subscription.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已删除订阅：${subscription.name}')),
          );
        },
        child: ListTile(
          leading: const Icon(Icons.rss_feed),
          title: Text(subscription.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subscription.url, 
                maxLines: 1, 
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subscription.lastUpdated != null
                    ? '上次更新: ${_formatDate(subscription.lastUpdated!)}'
                    : '从未更新',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              if (lastUpdateStatus != null) ...[
                const SizedBox(height: 4),
                Text(
                  lastUpdateStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: lastUpdateStatus.contains('失败') 
                        ? Colors.red 
                        : Colors.green.shade700,
                  ),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(
                  isUpdating ? Icons.sync : Icons.refresh,
                  color: isUpdating ? Theme.of(context).primaryColor : null,
                ),
                tooltip: '更新订阅',
                onPressed: isUpdating
                    ? null
                    : () => _updateSubscription(context, subscription.id),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: '编辑订阅',
                onPressed: () => _navigateToEditSubscription(context, subscription),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () => _navigateToEditSubscription(context, subscription),
        ),
      ),
    );
  }
  
  /// 确认删除
  Future<bool> _confirmDelete(BuildContext context, Subscription subscription) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除订阅'),
        content: Text('确定要删除订阅 "${subscription.name}" 吗？\n\n'
            '该订阅下的所有服务器也将被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// 导航到添加订阅页面
  void _navigateToAddSubscription(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SubscriptionEditScreen(),
      ),
    );
  }
  
  /// 导航到编辑订阅页面
  void _navigateToEditSubscription(BuildContext context, Subscription subscription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionEditScreen(subscription: subscription),
      ),
    );
  }
  
  /// 更新订阅
  Future<void> _updateSubscription(BuildContext context, String id) async {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    final result = await subscriptionProvider.updateSubscription(id);
    
    if (!result) {
      final errorMessage = subscriptionProvider.getLastUpdateStatus(id) ?? '更新失败';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }
  
  /// 更新所有订阅
  Future<void> _updateAllSubscriptions(BuildContext context) async {
    final subscriptionProvider = Provider.of<SubscriptionProvider>(context, listen: false);
    await subscriptionProvider.updateAllSubscriptions();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已完成所有订阅更新')),
    );
  }
  
  /// 格式化日期
  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return '刚刚';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    }
  }
} 