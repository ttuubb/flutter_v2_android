import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_v2_android/core/config/v2ray_config_generator.dart';
import 'package:flutter_v2_android/core/v2ray/v2ray_service.dart';
import 'package:flutter_v2_android/core/vpn/vpn_service.dart';
import 'package:flutter_v2_android/models/config/app_settings.dart';
import 'package:flutter_v2_android/models/config/server_config.dart';
import 'package:flutter_v2_android/models/stats/traffic_stats.dart';
import 'package:flutter_v2_android/services/server/server_service.dart';
import 'package:flutter_v2_android/services/settings/settings_service.dart';
import 'package:flutter_v2_android/utils/logger.dart';

/// 连接状态
enum ConnectionStatus {
  /// 已断开连接
  disconnected,
  /// 正在连接
  connecting,
  /// 已连接
  connected,
  /// 正在断开连接
  disconnecting,
  /// 发生错误
  error
}

/// 连接服务
/// 负责管理V2Ray服务和VPN服务的连接状态
class ConnectionService {
  /// V2Ray服务
  final V2RayService _v2rayService;
  
  /// VPN服务
  final VpnService _vpnService;
  
  /// 服务器管理服务
  final ServerService _serverService;
  
  /// 设置服务
  final SettingsService _settingsService;
  
  /// 连接状态
  ConnectionStatus _status = ConnectionStatus.disconnected;
  
  /// 当前使用的服务器配置
  ServerConfig? _currentServer;
  
  /// 最后一次错误信息
  String _lastError = '';
  
  /// 流量统计信息
  TrafficStats _trafficStats = TrafficStats(
    uploadSpeed: 0,
    downloadSpeed: 0,
    totalUpload: 0,
    totalDownload: 0,
  );
  
  /// 连接状态控制器
  final _statusController = StreamController<ConnectionStatus>.broadcast();
  
  /// 流量统计控制器
  final _trafficStatsController = StreamController<TrafficStats>.broadcast();
  
  /// 日志控制器
  final _logController = StreamController<String>.broadcast();
  
  /// 订阅取消器列表
  final List<StreamSubscription> _subscriptions = [];
  
  /// 构造函数
  ConnectionService({
    required this.serverService,
    required this.settingsService,
    V2RayService? v2RayService,
    VpnService? vpnService,
  }) : 
    _serverService = serverService,
    _settingsService = settingsService,
    _v2rayService = v2RayService ?? V2RayService(),
    _vpnService = vpnService ?? VpnService() {
    _init();
  }
  
  /// 获取连接状态
  ConnectionStatus get status => _status;
  
  /// 获取连接状态流
  Stream<ConnectionStatus> get statusStream => _statusController.stream;
  
  /// 获取流量统计信息
  TrafficStats get trafficStats => _trafficStats;
  
  /// 获取流量统计流
  Stream<TrafficStats> get trafficStatsStream => _trafficStatsController.stream;
  
  /// 获取日志流
  Stream<String> get logStream => _logController.stream;
  
  /// 获取最后一次错误信息
  String get lastError => _lastError;
  
  /// 获取当前使用的服务器配置
  ServerConfig? get currentServer => _currentServer;
  
  /// 初始化连接服务
  Future<void> _init() async {
    try {
      LoggerUtil.info('正在初始化连接服务...');
      
      // 初始化V2Ray服务
      await _v2rayService.init();
      
      // 初始化VPN服务
      await _vpnService.init();
      
      // 监听V2Ray服务状态变化
      _subscriptions.add(
        _v2rayService.statusStream.listen(_handleV2RayStatusChange)
      );
      
      // 监听VPN服务状态变化
      _subscriptions.add(
        _vpnService.statusStream.listen(_handleVpnStatusChange)
      );
      
      // 监听V2Ray服务日志
      _subscriptions.add(
        _v2rayService.logStream.listen((log) {
          _logController.add(log);
        })
      );
      
      // 监听V2Ray服务流量统计
      _subscriptions.add(
        _v2rayService.trafficStatsStream.listen((stats) {
          _trafficStats = stats;
          _trafficStatsController.add(stats);
        })
      );
      
      // 检查是否需要自动连接
      final settings = await _settingsService.getSettings();
      if (settings.autoConnect) {
        connect();
      }
      
      LoggerUtil.info('连接服务初始化完成');
    } catch (e) {
      _lastError = e.toString();
      LoggerUtil.error('初始化连接服务失败: $e');
      _updateStatus(ConnectionStatus.error);
    }
  }
  
  /// 连接到服务器
  Future<bool> connect({int? serverId}) async {
    if (_status == ConnectionStatus.connected || _status == ConnectionStatus.connecting) {
      LoggerUtil.warn('已处于连接状态，无需重复连接');
      return true;
    }
    
    try {
      _updateStatus(ConnectionStatus.connecting);
      
      // 获取服务器配置
      final ServerConfig? server = serverId != null 
          ? await _serverService.getServer(serverId)
          : await _serverService.getSelectedServer();
      
      if (server == null) {
        _lastError = '未找到可用的服务器配置';
        LoggerUtil.error(_lastError);
        _updateStatus(ConnectionStatus.error);
        return false;
      }
      
      _currentServer = server;
      LoggerUtil.info('准备连接到服务器: ${server.name}');
      
      // 获取应用设置
      final settings = await _settingsService.getSettings();
      
      // 启动V2Ray服务
      final v2rayStarted = await _v2rayService.start(server);
      if (!v2rayStarted) {
        _lastError = 'V2Ray服务启动失败';
        LoggerUtil.error(_lastError);
        _updateStatus(ConnectionStatus.error);
        return false;
      }
      
      // 启动VPN服务
      final vpnStarted = await _vpnService.start(settings);
      if (!vpnStarted) {
        // 如果VPN启动失败，停止V2Ray服务
        await _v2rayService.stop();
        _lastError = 'VPN服务启动失败';
        LoggerUtil.error(_lastError);
        _updateStatus(ConnectionStatus.error);
        return false;
      }
      
      LoggerUtil.info('成功连接到服务器: ${server.name}');
      return true;
    } catch (e) {
      _lastError = e.toString();
      LoggerUtil.error('连接失败: $e');
      _updateStatus(ConnectionStatus.error);
      
      // 确保服务都已停止
      await _v2rayService.stop();
      await _vpnService.stop();
      
      return false;
    }
  }
  
  /// 断开连接
  Future<bool> disconnect() async {
    if (_status == ConnectionStatus.disconnected || _status == ConnectionStatus.disconnecting) {
      LoggerUtil.warn('已处于断开状态，无需重复断开');
      return true;
    }
    
    try {
      _updateStatus(ConnectionStatus.disconnecting);
      LoggerUtil.info('正在断开连接...');
      
      // 先停止VPN服务
      final vpnStopped = await _vpnService.stop();
      if (!vpnStopped) {
        LoggerUtil.warn('VPN服务停止失败');
      }
      
      // 再停止V2Ray服务
      final v2rayStopped = await _v2rayService.stop();
      if (!v2rayStopped) {
        LoggerUtil.warn('V2Ray服务停止失败');
      }
      
      if (!vpnStopped || !v2rayStopped) {
        _lastError = '断开连接过程中出现错误';
        LoggerUtil.error(_lastError);
        _updateStatus(ConnectionStatus.error);
        return false;
      }
      
      _currentServer = null;
      LoggerUtil.info('成功断开连接');
      return true;
    } catch (e) {
      _lastError = e.toString();
      LoggerUtil.error('断开连接失败: $e');
      _updateStatus(ConnectionStatus.error);
      return false;
    }
  }
  
  /// 测试当前服务器延迟
  Future<int> testCurrentLatency() async {
    if (_currentServer == null) {
      LoggerUtil.warn('当前没有连接到任何服务器');
      return -1;
    }
    
    try {
      LoggerUtil.info('测试当前服务器延迟...');
      final latency = await _v2rayService.testLatency(_currentServer!);
      LoggerUtil.info('当前服务器延迟: ${latency}ms');
      return latency;
    } catch (e) {
      LoggerUtil.error('测试延迟失败: $e');
      return -1;
    }
  }
  
  /// 重新连接
  Future<bool> reconnect() async {
    LoggerUtil.info('正在重新连接...');
    
    final wasConnected = _status == ConnectionStatus.connected;
    final currentServerId = _currentServer?.id;
    
    // 先断开连接
    await disconnect();
    
    // 如果之前是连接状态，重新连接
    if (wasConnected) {
      return connect(serverId: currentServerId);
    }
    
    return false;
  }
  
  /// 处理V2Ray服务状态变化
  void _handleV2RayStatusChange(V2RayStatus status) {
    LoggerUtil.info('V2Ray服务状态变化: $status');
    
    switch (status) {
      case V2RayStatus.running:
        if (_vpnService.status == VpnStatus.connected) {
          _updateStatus(ConnectionStatus.connected);
        }
        break;
      case V2RayStatus.stopped:
        if (_status != ConnectionStatus.disconnecting) {
          _updateStatus(ConnectionStatus.disconnected);
        }
        break;
      case V2RayStatus.error:
        _lastError = '在V2Ray服务中发生错误: ${_v2rayService.lastError}';
        _updateStatus(ConnectionStatus.error);
        break;
      default:
        // 其他状态不处理
        break;
    }
  }
  
  /// 处理VPN服务状态变化
  void _handleVpnStatusChange(VpnStatus status) {
    LoggerUtil.info('VPN服务状态变化: $status');
    
    switch (status) {
      case VpnStatus.connected:
        if (_v2rayService.status == V2RayStatus.running) {
          _updateStatus(ConnectionStatus.connected);
        }
        break;
      case VpnStatus.disconnected:
        if (_status != ConnectionStatus.disconnecting) {
          _updateStatus(ConnectionStatus.disconnected);
        }
        // 确保V2Ray服务也已停止
        _v2rayService.stop();
        break;
      case VpnStatus.error:
        _lastError = 'VPN服务发生错误';
        _updateStatus(ConnectionStatus.error);
        // 确保V2Ray服务也已停止
        _v2rayService.stop();
        break;
      default:
        // 其他状态不处理
        break;
    }
  }
  
  /// 更新连接状态
  void _updateStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
      LoggerUtil.info('连接状态更新: $_status');
    }
  }
  
  /// 清理资源
  Future<void> dispose() async {
    try {
      // 断开连接
      await disconnect();
      
      // 取消所有订阅
      for (final subscription in _subscriptions) {
        await subscription.cancel();
      }
      _subscriptions.clear();
      
      // 关闭控制器
      await _statusController.close();
      await _trafficStatsController.close();
      await _logController.close();
      
      LoggerUtil.info('连接服务资源已清理');
    } catch (e) {
      LoggerUtil.error('清理连接服务资源时出错: $e');
    }
  }
} 
} 