import 'package:flutter_v2_android/models/config/server_config.dart';

/// 订阅模型
class Subscription {
  /// 唯一标识符
  final String id;
  
  /// 订阅名称
  final String name;
  
  /// 订阅URL
  final String url;
  
  /// 上次更新时间
  final DateTime? lastUpdated;
  
  /// 自动更新
  final bool autoUpdate;
  
  /// 更新间隔（天）
  final int updateInterval;
  
  /// 服务器列表
  final List<String> serverIds;
  
  /// 构造函数
  Subscription({
    required this.id,
    required this.name,
    required this.url,
    this.lastUpdated,
    this.autoUpdate = true,
    this.updateInterval = 1,
    this.serverIds = const [],
  });
  
  /// 从JSON构建对象
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated'] as String) 
          : null,
      autoUpdate: json['autoUpdate'] as bool? ?? true,
      updateInterval: json['updateInterval'] as int? ?? 1,
      serverIds: (json['serverIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'lastUpdated': lastUpdated?.toIso8601String(),
      'autoUpdate': autoUpdate,
      'updateInterval': updateInterval,
      'serverIds': serverIds,
    };
  }
  
  /// 创建副本
  Subscription copyWith({
    String? id,
    String? name,
    String? url,
    DateTime? lastUpdated,
    bool? autoUpdate,
    int? updateInterval,
    List<String>? serverIds,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      autoUpdate: autoUpdate ?? this.autoUpdate,
      updateInterval: updateInterval ?? this.updateInterval,
      serverIds: serverIds ?? this.serverIds,
    );
  }
} 