import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_v2_android/config/app_config.dart';
import 'package:flutter_v2_android/core/v2ray/v2ray_service.dart';
import 'package:flutter_v2_android/di/app_module.dart';
import 'package:flutter_v2_android/models/config/app_settings.dart';
import 'package:flutter_v2_android/models/config/server_config.dart';
import 'package:flutter_v2_android/models/config/subscription.dart';
import 'package:flutter_v2_android/models/stats/traffic_stats.dart';
import 'package:flutter_v2_android/services/connection/connection_service.dart';
import 'package:flutter_v2_android/services/server/server_service.dart';
import 'package:flutter_v2_android/services/settings/settings_service.dart';
import 'package:flutter_v2_android/services/storage/storage_service.dart';
import 'package:flutter_v2_android/services/subscription/subscription_service.dart';
import 'package:flutter_v2_android/views/themes/app_theme.dart';
import 'package:flutter_v2_android/views/home/home_screen.dart';
import 'package:get_it/get_it.dart';

void main() async {
  // 确保Flutter引擎初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 初始化依赖注入模块
  await AppModule.init();
  
  // 初始化服务
  final storageService = StorageService();
  await storageService.init();
  
  final settingsService = SettingsService(storageService);
  await settingsService.init();
  
  final serverService = ServerService(storageService);
  await serverService.init();
  
  final subscriptionService = SubscriptionService(storageService, serverService);
  await subscriptionService.init();
  
  final connectionService = ConnectionService(
    serverService: serverService,
    settingsService: settingsService,
  );
  await connectionService.init();
  
  runApp(
    MultiProvider(
      providers: [
        // 提供设置状态
        ChangeNotifierProvider(
          create: (_) => AppSettingsProvider(settingsService),
        ),
        // 提供服务器状态
        ChangeNotifierProvider(
          create: (_) => ServerProvider(serverService),
        ),
        // 提供连接状态
        ChangeNotifierProvider(
          create: (_) => ConnectionStateProvider(connectionService),
        ),
        // 提供流量统计状态
        ChangeNotifierProvider(
          create: (_) => TrafficStatsProvider(connectionService),
        ),
        // 提供日志状态
        ChangeNotifierProvider(
          create: (_) => LogProvider(connectionService),
        ),
        // 提供订阅状态
        ChangeNotifierProvider(
          create: (_) => SubscriptionProvider(subscriptionService),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

/// 应用设置状态管理
class AppSettingsProvider extends ChangeNotifier {
  final SettingsService _settingsService;
  
  AppSettingsProvider(this._settingsService) {
    // 监听设置变化
    _settingsService.addListener(_onSettingsChanged);
  }
  
  /// 获取当前设置
  AppSettings get settings => _settingsService.currentSettings;
  
  /// 处理设置变化
  void _onSettingsChanged() {
    notifyListeners();
  }
  
  /// 更新设置
  Future<void> updateSetting({
    bool? autoStart,
    bool? autoConnect,
    bool? showNotification,
    bool? showTrafficSpeed,
    bool? enableSystemProxy,
    bool? enableUdp,
    bool? shareLan,
    int? httpPort,
    int? socksPort,
    int? routingMode,
    int? domainStrategy,
    String? customDns,
    int? muxConcurrency,
    ThemeMode? themeMode,
    bool? autoUpdate,
    int? subscriptionUpdateInterval,
  }) async {
    final newSettings = AppSettings(
      autoStart: autoStart ?? settings.autoStart,
      autoConnect: autoConnect ?? settings.autoConnect,
      showNotification: showNotification ?? settings.showNotification,
      showTrafficSpeed: showTrafficSpeed ?? settings.showTrafficSpeed,
      enableSystemProxy: enableSystemProxy ?? settings.enableSystemProxy,
      enableUdp: enableUdp ?? settings.enableUdp,
      shareLan: shareLan ?? settings.shareLan,
      httpPort: httpPort ?? settings.httpPort,
      socksPort: socksPort ?? settings.socksPort,
      routingMode: routingMode ?? settings.routingMode,
      domainStrategy: domainStrategy ?? settings.domainStrategy,
      customDns: customDns ?? settings.customDns,
      muxConcurrency: muxConcurrency ?? settings.muxConcurrency,
      themeMode: themeMode ?? settings.themeMode,
      autoUpdate: autoUpdate ?? settings.autoUpdate,
      subscriptionUpdateInterval: subscriptionUpdateInterval ?? 
          settings.subscriptionUpdateInterval,
    );
    
    await _settingsService.saveSettings(newSettings);
  }
  
  /// 重置为默认设置
  Future<void> resetToDefaults() async {
    await _settingsService.resetToDefaults();
  }
  
  @override
  void dispose() {
    _settingsService.removeListener(_onSettingsChanged);
    super.dispose();
  }
}

/// 服务器状态管理
class ServerProvider extends ChangeNotifier {
  final ServerService _serverService;
  
  ServerProvider(this._serverService) {
    _serverService.addListener(_onServersChanged);
  }
  
  /// 获取服务器列表
  List<ServerConfig> get servers => _serverService.servers;
  
  /// 获取当前选中的服务器
  ServerConfig? get selectedServer => _serverService.selectedServer;
  
  /// 获取当前选中的服务器索引
  int get selectedServerIndex => _serverService.selectedServerIndex;
  
  /// 添加服务器
  Future<void> addServer(ServerConfig server) async {
    await _serverService.addServer(server);
    notifyListeners();
  }
  
  /// 更新服务器
  Future<void> updateServer(ServerConfig server) async {
    await _serverService.updateServer(server);
    notifyListeners();
  }
  
  /// 删除服务器
  Future<void> deleteServer(String serverId) async {
    await _serverService.deleteServer(serverId);
    notifyListeners();
  }
  
  /// 选择服务器
  Future<void> selectServer(String serverId) async {
    await _serverService.selectServer(serverId);
    notifyListeners();
  }
  
  /// 从分享链接添加服务器
  Future<ServerConfig?> addServerFromShareLink(String shareLink) async {
    final server = await _serverService.addServerFromShareLink(shareLink);
    notifyListeners();
    return server;
  }
  
  /// 导入多个分享链接
  Future<List<ServerConfig>> importMultipleShareLinks(List<String> shareLinks) async {
    final servers = await _serverService.importMultipleShareLinks(shareLinks);
    notifyListeners();
    return servers;
  }
  
  /// 从JSON导入服务器
  Future<List<ServerConfig>> importServersFromJson(String jsonString) async {
    final servers = await _serverService.importServersFromJson(jsonString);
    notifyListeners();
    return servers;
  }
  
  /// 移动服务器位置
  Future<void> moveServer(int oldIndex, int newIndex) async {
    await _serverService.moveServer(oldIndex, newIndex);
    notifyListeners();
  }
  
  /// 更新服务器延迟测试结果
  Future<void> updateServerLatency(String serverId, int latency) async {
    await _serverService.updateServerLatency(serverId, latency);
    notifyListeners();
  }
  
  void _onServersChanged() {
    notifyListeners();
  }
  
  @override
  void dispose() {
    _serverService.removeListener(_onServersChanged);
    super.dispose();
  }
}

/// 连接状态管理
class ConnectionStateProvider extends ChangeNotifier {
  final ConnectionService _connectionService;
  
  ConnectionStateProvider(this._connectionService) {
    _connectionService.addConnectionStateListener(_onConnectionStateChanged);
  }
  
  /// 获取当前连接状态
  bool get isConnected => _connectionService.isConnected;
  
  /// 获取当前连接错误
  String? get connectionError => _connectionService.connectionError;
  
  /// 获取当前连接服务器
  ServerConfig? get currentServer => _connectionService.currentServer;
  
  void _onConnectionStateChanged() {
    notifyListeners();
  }
  
  /// 连接到服务器
  Future<bool> connect(ServerConfig server) async {
    return await _connectionService.connect(server);
  }
  
  /// 断开连接
  Future<void> disconnect() async {
    await _connectionService.disconnect();
  }
  
  @override
  void dispose() {
    _connectionService.removeConnectionStateListener(_onConnectionStateChanged);
    super.dispose();
  }
}

/// 流量统计管理
class TrafficStatsProvider extends ChangeNotifier {
  final ConnectionService _connectionService;
  
  TrafficStatsProvider(this._connectionService) {
    _connectionService.addStatsListener(_onStatsChanged);
  }
  
  /// 获取当前流量统计
  TrafficStats get stats => _connectionService.trafficStats;
  
  void _onStatsChanged(TrafficStats stats) {
    notifyListeners();
  }
  
  @override
  void dispose() {
    _connectionService.removeStatsListener(_onStatsChanged);
    super.dispose();
  }
}

/// 日志管理
class LogProvider extends ChangeNotifier {
  final ConnectionService _connectionService;
  
  LogProvider(this._connectionService) {
    _connectionService.addLogListener(_onLogAdded);
  }
  
  /// 获取日志列表
  List<String> get logs => _connectionService.logs;
  
  void _onLogAdded() {
    notifyListeners();
  }
  
  /// 清空日志
  void clearLogs() {
    _connectionService.clearLogs();
  }
  
  @override
  void dispose() {
    _connectionService.removeLogListener(_onLogAdded);
    super.dispose();
  }
}

/// 订阅状态管理
class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService;
  
  SubscriptionProvider(this._subscriptionService) {
    _subscriptionService.addListener(_onSubscriptionsChanged);
  }
  
  /// 获取订阅列表
  List<Subscription> get subscriptions => _subscriptionService.subscriptions;
  
  /// 获取订阅更新状态
  bool isUpdating(String subscriptionId) => _subscriptionService.isUpdating(subscriptionId);
  
  /// 获取上次更新状态信息
  String? getLastUpdateStatus(String subscriptionId) => 
      _subscriptionService.getLastUpdateStatus(subscriptionId);
  
  /// 处理订阅变化
  void _onSubscriptionsChanged() {
    notifyListeners();
  }
  
  /// 添加订阅
  Future<Subscription> addSubscription(String name, String url) async {
    return await _subscriptionService.addSubscription(name, url);
  }
  
  /// 更新订阅信息
  Future<void> updateSubscriptionInfo(Subscription subscription) async {
    await _subscriptionService.updateSubscriptionInfo(subscription);
  }
  
  /// 删除订阅
  Future<void> deleteSubscription(String id) async {
    await _subscriptionService.deleteSubscription(id);
  }
  
  /// 更新订阅内容
  Future<bool> updateSubscription(String id) async {
    return await _subscriptionService.updateSubscription(id);
  }
  
  /// 更新所有订阅
  Future<void> updateAllSubscriptions() async {
    await _subscriptionService.updateAllSubscriptions();
  }
  
  @override
  void dispose() {
    _subscriptionService.removeListener(_onSubscriptionsChanged);
    super.dispose();
  }
}

/// 应用程序入口
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取当前设置
    final settingsProvider = Provider.of<AppSettingsProvider>(context);
    final settings = settingsProvider.settings;
    
    return MaterialApp(
      title: AppConfig.appName,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: settings.themeMode,
      // 国际化设置
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppConfig.supportedLocales,
      locale: Locale(settings.languageCode),
      home: const HomeScreen(),
    );
  }
}

/// 主页（临时示例）
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 获取连接状态
    final connectionProvider = Provider.of<ConnectionStateProvider>(context);
    final connectionStatus = connectionProvider.isConnected;
    
    // 获取服务器列表
    final serverProvider = Provider.of<ServerProvider>(context);
    final selectedServer = serverProvider.selectedServer;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'V2rayNG Flutter 项目基础架构已完成',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            Text(
              '当前状态: ${_getStatusText(connectionStatus)}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Text(
              '当前服务器: ${selectedServer?.name ?? '未选择服务器'}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
  
  /// 获取状态文本
  String _getStatusText(bool status) {
    return status ? '已连接' : '已断开连接';
  }
}
