import 'package:flutter/material.dart';

/// 应用配置
class AppConfig {
  /// 应用名称
  static const String appName = 'Flutter V2ray Android';
  
  /// 应用版本
  static const String appVersion = '1.0.0';
  
  /// 应用构建版本
  static const String appBuildNumber = '1';
  
  /// 支持的语言
  static const List<Locale> supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];
  
  /// 存储键 - 设置
  static const String storageKeySettings = 'settings';
  
  /// 存储键 - 服务器列表
  static const String storageKeyServers = 'servers';
  
  /// 存储键 - 当前选择的服务器ID
  static const String storageKeySelectedServer = 'selected_server';
  
  /// 存储键 - 订阅列表
  static const String storageKeySubscriptions = 'subscriptions';
  
  /// 存储键 - 流量统计
  static const String storageKeyTrafficStats = 'traffic_stats';
  
  /// V2Ray核心版本
  static const String v2rayCoreVersion = '4.45.2';
} 