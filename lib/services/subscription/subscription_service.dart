import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_v2_android/config/app_config.dart';
import 'package:flutter_v2_android/models/config/server_config.dart';
import 'package:flutter_v2_android/models/config/subscription.dart';
import 'package:flutter_v2_android/services/server/server_service.dart';
import 'package:flutter_v2_android/services/storage/storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

/// 订阅管理服务
class SubscriptionService extends ChangeNotifier {
  /// 存储服务
  final StorageService _storageService;
  
  /// 服务器管理服务
  final ServerService _serverService;
  
  /// 订阅列表
  List<Subscription> _subscriptions = [];
  
  /// 订阅更新状态
  Map<String, bool> _updatingStatus = {};
  
  /// 上次更新状态信息
  Map<String, String> _lastUpdateStatus = {};
  
  /// UUID生成器
  final _uuid = const Uuid();
  
  /// 构造函数
  SubscriptionService(this._storageService, this._serverService);
  
  /// 获取订阅列表
  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  
  /// 获取订阅更新状态
  bool isUpdating(String subscriptionId) => _updatingStatus[subscriptionId] ?? false;
  
  /// 获取上次更新状态信息
  String? getLastUpdateStatus(String subscriptionId) => _lastUpdateStatus[subscriptionId];
  
  /// 初始化
  Future<void> init() async {
    await _loadSubscriptions();
    await _checkAutoUpdate();
  }
  
  /// 加载订阅
  Future<void> _loadSubscriptions() async {
    final subscriptionsJson = await _storageService.getObject(AppConfig.storageKeySubscriptions);
    if (subscriptionsJson != null) {
      final List<dynamic> list = subscriptionsJson;
      _subscriptions = list.map((e) => Subscription.fromJson(e)).toList();
    }
    notifyListeners();
  }
  
  /// 保存订阅
  Future<void> _saveSubscriptions() async {
    await _storageService.setObject(
      AppConfig.storageKeySubscriptions,
      _subscriptions.map((e) => e.toJson()).toList(),
    );
    notifyListeners();
  }
  
  /// 添加订阅
  Future<Subscription> addSubscription(String name, String url) async {
    final subscription = Subscription(
      id: _uuid.v4(),
      name: name,
      url: url,
    );
    
    _subscriptions.add(subscription);
    await _saveSubscriptions();
    
    // 立即更新新添加的订阅
    await updateSubscription(subscription.id);
    
    return subscription;
  }
  
  /// 更新订阅信息
  Future<void> updateSubscriptionInfo(Subscription subscription) async {
    final index = _subscriptions.indexWhere((s) => s.id == subscription.id);
    if (index != -1) {
      _subscriptions[index] = subscription;
      await _saveSubscriptions();
    }
  }
  
  /// 删除订阅
  Future<void> deleteSubscription(String id) async {
    // 找到要删除的订阅
    final subscription = _subscriptions.firstWhere(
      (s) => s.id == id,
      orElse: () => throw Exception('订阅不存在'),
    );
    
    // 删除属于该订阅的服务器
    for (final serverId in subscription.serverIds) {
      await _serverService.deleteServer(serverId);
    }
    
    // 删除订阅
    _subscriptions.removeWhere((s) => s.id == id);
    await _saveSubscriptions();
  }
  
  /// 更新订阅内容
  Future<bool> updateSubscription(String id) async {
    // 找到要更新的订阅
    final subscriptionIndex = _subscriptions.indexWhere((s) => s.id == id);
    if (subscriptionIndex == -1) {
      _lastUpdateStatus[id] = '订阅不存在';
      return false;
    }
    
    final subscription = _subscriptions[subscriptionIndex];
    
    // 设置更新状态
    _updatingStatus[id] = true;
    _lastUpdateStatus[id] = '正在更新...';
    notifyListeners();
    
    try {
      // 下载订阅内容
      final response = await http.get(Uri.parse(subscription.url));
      
      if (response.statusCode != 200) {
        throw Exception('下载失败: HTTP ${response.statusCode}');
      }
      
      // 解析订阅内容
      final content = response.body;
      
      // Base64解码
      final decodedContent = utf8.decode(base64.decode(content.trim()));
      
      // 分割服务器链接
      final links = decodedContent
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      
      // 记录原来的服务器ID
      final oldServerIds = List<String>.from(subscription.serverIds);
      
      // 新的服务器ID列表
      final List<String> newServerIds = [];
      
      // 逐个处理服务器链接
      for (final link in links) {
        try {
          // 尝试导入服务器
          final server = await _serverService.addServerFromShareLink(link);
          if (server != null) {
            newServerIds.add(server.id);
          }
        } catch (e) {
          print('导入服务器失败: $e');
        }
      }
      
      // 删除旧的服务器
      for (final oldId in oldServerIds) {
        if (!newServerIds.contains(oldId)) {
          await _serverService.deleteServer(oldId);
        }
      }
      
      // 更新订阅信息
      final updatedSubscription = subscription.copyWith(
        lastUpdated: DateTime.now(),
        serverIds: newServerIds,
      );
      
      _subscriptions[subscriptionIndex] = updatedSubscription;
      await _saveSubscriptions();
      
      _lastUpdateStatus[id] = '更新成功: ${newServerIds.length} 个服务器';
      return true;
    } catch (e) {
      _lastUpdateStatus[id] = '更新失败: $e';
      return false;
    } finally {
      _updatingStatus[id] = false;
      notifyListeners();
    }
  }
  
  /// 更新所有订阅
  Future<void> updateAllSubscriptions() async {
    for (final subscription in _subscriptions) {
      if (subscription.autoUpdate) {
        await updateSubscription(subscription.id);
      }
    }
  }
  
  /// 检查是否需要自动更新
  Future<void> _checkAutoUpdate() async {
    final now = DateTime.now();
    
    for (final subscription in _subscriptions) {
      if (subscription.autoUpdate && subscription.lastUpdated != null) {
        final lastUpdated = subscription.lastUpdated!;
        final daysSinceLastUpdate = now.difference(lastUpdated).inDays;
        
        // 如果达到更新间隔，则更新
        if (daysSinceLastUpdate >= subscription.updateInterval) {
          await updateSubscription(subscription.id);
        }
      }
    }
  }
  
  /// 清理资源
  void dispose() {
    super.dispose();
  }
} 