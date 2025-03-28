import 'package:flutter/material.dart';

/// 应用程序设置模型
class AppSettings {
  /// 是否开启自动更新
  final bool autoUpdate;
  
  /// 是否开机自启动
  final bool autoStart;
  
  /// 是否自动连接到上次使用的服务器
  final bool autoConnect;
  
  /// 订阅自动更新时间间隔（小时）
  final int subscriptionUpdateInterval;
  
  /// 是否启用系统代理
  final bool enableSystemProxy;
  
  /// 是否启用UDP转发
  final bool enableUdp;
  
  /// 是否启用局域网共享
  final bool shareLan;
  
  /// 本地监听端口（HTTP代理）
  final int httpPort;
  
  /// 本地监听端口（SOCKS代理）
  final int socksPort;
  
  /// 当前使用的主题模式
  final ThemeMode themeMode;
  
  /// 当前使用的语言代码
  final String languageCode;
  
  /// 路由模式（0: 全局, 1: 绕过局域网, 2: 绕过大陆, 3: 绕过局域网和大陆, 4: 全局直连, 5: 自定义）
  final int routingMode;
  
  /// 域名解析策略（0: 使用系统DNS, 1: 使用代理DNS）
  final int domainStrategy;
  
  /// 自定义DNS服务器
  final String customDns;
  
  /// mux并发连接数
  final int muxConcurrency;
  
  /// 是否显示流量速度
  final bool showTrafficSpeed;
  
  /// 是否在通知栏中显示
  final bool showNotification;
  
  /// 构造函数
  AppSettings({
    this.autoUpdate = true,
    this.autoStart = false,
    this.autoConnect = false,
    this.subscriptionUpdateInterval = 24,
    this.enableSystemProxy = true,
    this.enableUdp = true,
    this.shareLan = false,
    this.httpPort = 10809,
    this.socksPort = 10808,
    this.themeMode = ThemeMode.system,
    this.languageCode = 'zh',
    this.routingMode = 1,
    this.domainStrategy = 0,
    this.customDns = '8.8.8.8',
    this.muxConcurrency = 8,
    this.showTrafficSpeed = true,
    this.showNotification = true,
  });
  
  /// 默认设置
  factory AppSettings.defaultSettings() {
    return AppSettings();
  }
  
  /// 从JSON构建对象
  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      autoUpdate: json['autoUpdate'] ?? true,
      autoStart: json['autoStart'] ?? false,
      autoConnect: json['autoConnect'] ?? false,
      subscriptionUpdateInterval: json['subscriptionUpdateInterval'] ?? 24,
      enableSystemProxy: json['enableSystemProxy'] ?? true,
      enableUdp: json['enableUdp'] ?? true,
      shareLan: json['shareLan'] ?? false,
      httpPort: json['httpPort'] ?? 10809,
      socksPort: json['socksPort'] ?? 10808,
      themeMode: _themeFromInt(json['themeMode'] ?? 0),
      languageCode: json['languageCode'] ?? 'zh',
      routingMode: json['routingMode'] ?? 1,
      domainStrategy: json['domainStrategy'] ?? 0,
      customDns: json['customDns'] ?? '8.8.8.8',
      muxConcurrency: json['muxConcurrency'] ?? 8,
      showTrafficSpeed: json['showTrafficSpeed'] ?? true,
      showNotification: json['showNotification'] ?? true,
    );
  }
  
  /// 根据整数值返回主题模式
  static ThemeMode _themeFromInt(int value) {
    switch (value) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
  
  /// 将主题模式转换为整数
  static int _themeToInt(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 1;
      case ThemeMode.dark:
        return 2;
      default:
        return 0;
    }
  }
  
  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'autoUpdate': autoUpdate,
      'autoStart': autoStart,
      'autoConnect': autoConnect,
      'subscriptionUpdateInterval': subscriptionUpdateInterval,
      'enableSystemProxy': enableSystemProxy,
      'enableUdp': enableUdp,
      'shareLan': shareLan,
      'httpPort': httpPort,
      'socksPort': socksPort,
      'themeMode': _themeToInt(themeMode),
      'languageCode': languageCode,
      'routingMode': routingMode,
      'domainStrategy': domainStrategy,
      'customDns': customDns,
      'muxConcurrency': muxConcurrency,
      'showTrafficSpeed': showTrafficSpeed,
      'showNotification': showNotification,
    };
  }
  
  /// 创建副本
  AppSettings copyWith({
    bool? autoUpdate,
    bool? autoStart,
    bool? autoConnect,
    int? subscriptionUpdateInterval,
    bool? enableSystemProxy,
    bool? enableUdp,
    bool? shareLan,
    int? httpPort,
    int? socksPort,
    ThemeMode? themeMode,
    String? languageCode,
    int? routingMode,
    int? domainStrategy,
    String? customDns,
    int? muxConcurrency,
    bool? showTrafficSpeed,
    bool? showNotification,
  }) {
    return AppSettings(
      autoUpdate: autoUpdate ?? this.autoUpdate,
      autoStart: autoStart ?? this.autoStart,
      autoConnect: autoConnect ?? this.autoConnect,
      subscriptionUpdateInterval: subscriptionUpdateInterval ?? this.subscriptionUpdateInterval,
      enableSystemProxy: enableSystemProxy ?? this.enableSystemProxy,
      enableUdp: enableUdp ?? this.enableUdp,
      shareLan: shareLan ?? this.shareLan,
      httpPort: httpPort ?? this.httpPort,
      socksPort: socksPort ?? this.socksPort,
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      routingMode: routingMode ?? this.routingMode,
      domainStrategy: domainStrategy ?? this.domainStrategy,
      customDns: customDns ?? this.customDns,
      muxConcurrency: muxConcurrency ?? this.muxConcurrency,
      showTrafficSpeed: showTrafficSpeed ?? this.showTrafficSpeed,
      showNotification: showNotification ?? this.showNotification,
    );
  }
} 