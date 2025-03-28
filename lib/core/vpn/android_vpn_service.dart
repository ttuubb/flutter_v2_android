import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_v2_android/core/constants/channel_constants.dart';
import 'package:flutter_v2_android/core/vpn/vpn_service.dart';
import 'package:flutter_v2_android/models/config/app_settings.dart';
import 'package:flutter_v2_android/utils/logger.dart';

/// Android VPN服务实现
/// 通过方法通道与Android原生VPN服务通信
class AndroidVpnService implements VpnService {
  /// 方法通道名称
  static const String _channelName = 'com.v2ray.flutter/vpn';
  
  /// 方法通道
  final MethodChannel _channel = const MethodChannel(_channelName);
  
  /// 事件通道
  final EventChannel _eventChannel = const EventChannel('$_channelName/events');
  
  /// VPN状态流控制器
  final StreamController<VpnStatus> _statusStreamController = 
      StreamController<VpnStatus>.broadcast();
  
  /// VPN当前状态
  VpnStatus _status = VpnStatus.disconnected;
  
  /// 获取VPN当前状态
  @override
  VpnStatus get status => _status;
  
  /// 获取VPN状态流
  @override
  Stream<VpnStatus> get statusStream => _statusStreamController.stream;
  
  /// 构造函数
  AndroidVpnService() {
    // 设置方法调用处理器
    _channel.setMethodCallHandler(_handleMethodCall);
  }
  
  /// 初始化VPN服务
  @override
  Future<void> init() async {
    try {
      LoggerUtil.info('正在初始化Android VPN服务...');
      
      // 监听VPN状态变化
      _listenToVpnStatus();
      
      // 检查当前VPN状态
      await _updateStatus();
      
      LoggerUtil.info('Android VPN服务初始化完成');
    } catch (e) {
      LoggerUtil.error('初始化Android VPN服务失败: $e');
      rethrow;
    }
  }
  
  /// 启动VPN服务
  @override
  Future<bool> start(AppSettings settings) async {
    if (_status == VpnStatus.connected || _status == VpnStatus.connecting) {
      LoggerUtil.warn('VPN服务已在运行中');
      return true;
    }
    
    try {
      LoggerUtil.info('正在启动Android VPN服务...');
      
      // 检查VPN权限
      final hasPermission = await checkPermission();
      if (!hasPermission) {
        // 请求VPN权限
        final granted = await requestPermission();
        if (!granted) {
          LoggerUtil.error('VPN权限被拒绝');
          _updateStatusValue(VpnStatus.error);
          return false;
        }
      }
      
      // 设置VPN参数
      final vpnParams = _buildVpnParams(settings);
      
      // 调用平台方法启动VPN
      final result = await _channel.invokeMethod<bool>('start', vpnParams) ?? false;
      
      if (result) {
        _updateStatusValue(VpnStatus.connecting);
        LoggerUtil.info('Android VPN服务启动成功');
        return true;
      } else {
        LoggerUtil.error('启动Android VPN服务失败');
        _updateStatusValue(VpnStatus.error);
        return false;
      }
    } on PlatformException catch (e) {
      if (e.code == _vpnPermissionDeniedError) {
        LoggerUtil.error('VPN权限被拒绝');
      } else {
        LoggerUtil.error('启动Android VPN服务出错: ${e.message}');
      }
      _updateStatusValue(VpnStatus.error);
      return false;
    } catch (e) {
      LoggerUtil.error('启动Android VPN服务出错: $e');
      _updateStatusValue(VpnStatus.error);
      return false;
    }
  }
  
  /// 停止VPN服务
  @override
  Future<bool> stop() async {
    if (_status == VpnStatus.disconnected || _status == VpnStatus.disconnecting) {
      LoggerUtil.warn('VPN服务已处于停止状态');
      return true;
    }
    
    try {
      LoggerUtil.info('正在停止Android VPN服务...');
      
      // 调用平台方法停止VPN
      final result = await _channel.invokeMethod<bool>('stop') ?? false;
      
      if (result) {
        _updateStatusValue(VpnStatus.disconnecting);
        LoggerUtil.info('已发送停止Android VPN服务的请求');
        return true;
      } else {
        LoggerUtil.error('停止Android VPN服务失败');
        return false;
      }
    } catch (e) {
      LoggerUtil.error('停止Android VPN服务出错: $e');
      return false;
    }
  }
  
  /// 检查VPN服务状态
  @override
  Future<VpnStatus> checkStatus() async {
    try {
      final statusIndex = await _channel.invokeMethod<int>('checkStatus');
      if (statusIndex != null) {
        _setStatus(VpnStatus.values[statusIndex]);
      }
      return _status;
    } catch (e) {
      print('检查VPN状态失败: $e');
      return _status;
    }
  }
  
  /// 检查是否拥有VPN权限
  @override
  Future<bool> checkPermission() async {
    try {
      LoggerUtil.info('正在检查VPN权限...');
      return await _channel.invokeMethod<bool>('checkPermission') ?? false;
    } catch (e) {
      LoggerUtil.error('检查VPN权限出错: $e');
      return false;
    }
  }
  
  /// 请求VPN权限
  @override
  Future<bool> requestPermission() async {
    try {
      LoggerUtil.info('正在请求VPN权限...');
      return await _channel.invokeMethod<bool>('requestPermission') ?? false;
    } catch (e) {
      LoggerUtil.error('请求VPN权限出错: $e');
      return false;
    }
  }
  
  /// 设置VPN DNS
  @override
  Future<bool> setDns(List<String> dns) async {
    try {
      LoggerUtil.info('正在设置VPN DNS: $dns');
      return await _channel.invokeMethod<bool>('setDns', {'dns': dns}) ?? false;
    } catch (e) {
      LoggerUtil.error('设置VPN DNS出错: $e');
      return false;
    }
  }
  
  /// 设置VPN路由
  @override
  Future<bool> setRoutes(List<String> routes) async {
    try {
      LoggerUtil.info('正在设置VPN路由: $routes');
      return await _channel.invokeMethod<bool>('setRoutes', {'routes': routes}) ?? false;
    } catch (e) {
      LoggerUtil.error('设置VPN路由出错: $e');
      return false;
    }
  }
  
  /// 更新VPN状态
  Future<void> _updateStatus() async {
    try {
      final statusString = await _channel.invokeMethod<String>('getStatus');
      final vpnStatus = _parseStatus(statusString);
      _updateStatusValue(vpnStatus);
    } catch (e) {
      LoggerUtil.error('获取VPN状态出错: $e');
    }
  }
  
  /// 监听VPN状态变化
  void _listenToVpnStatus() {
    _eventChannel.receiveBroadcastStream().listen((statusString) {
      final vpnStatus = _parseStatus(statusString.toString());
      _updateStatusValue(vpnStatus);
    }, onError: (error) {
      LoggerUtil.error('VPN状态监听错误: $error');
    });
  }
  
  /// 更新状态值
  void _updateStatusValue(VpnStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusStreamController.add(_status);
      LoggerUtil.info('VPN状态更新: $_status');
    }
  }
  
  /// 解析状态字符串
  VpnStatus _parseStatus(String? statusString) {
    switch (statusString) {
      case 'CONNECTED':
        return VpnStatus.connected;
      case 'CONNECTING':
        return VpnStatus.connecting;
      case 'DISCONNECTING':
        return VpnStatus.disconnecting;
      case 'DISCONNECTED':
        return VpnStatus.disconnected;
      case 'ERROR':
        return VpnStatus.error;
      default:
        return VpnStatus.disconnected;
    }
  }
  
  /// 构建VPN参数
  Map<String, dynamic> _buildVpnParams(AppSettings settings) {
    // 解析DNS设置
    final dnsServers = settings.customDns.split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    
    // 构建路由模式
    final routes = _buildRoutesFromMode(settings.routingMode);
    
    return {
      'socksPort': settings.socksPort,
      'httpPort': settings.httpPort,
      'enableUdp': settings.enableUdp,
      'bypassLan': settings.routingMode == 1 || settings.routingMode == 3,
      'bypassChinese': settings.routingMode == 2 || settings.routingMode == 3,
      'dns': dnsServers.isEmpty ? ['8.8.8.8', '8.8.4.4'] : dnsServers,
      'routes': routes,
      'perAppProxy': false, // 暂不支持分应用代理
      'allowedApps': <String>[], // 暂不支持分应用代理
    };
  }
  
  /// 根据路由模式构建路由规则
  List<String> _buildRoutesFromMode(int routingMode) {
    switch (routingMode) {
      case 1: // 绕过局域网
        return ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16'];
      case 2: // 绕过中国大陆
        return ['geoip:cn'];
      case 3: // 绕过局域网和中国大陆
        return ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16', 'geoip:cn'];
      case 0: // 全局
      default:
        return [];
    }
  }
  
  /// 处理来自原生代码的方法调用
  Future<dynamic> _handleMethodCall(MethodCall call) async {
    print('收到VPN服务方法调用: ${call.method}');
    
    switch (call.method) {
      case 'updateStatus':
        final statusIndex = call.arguments as int;
        _setStatus(VpnStatus.values[statusIndex]);
        break;
      case 'error':
        final message = call.arguments as String;
        print('VPN服务错误: $message');
        break;
    }
    
    return null;
  }
  
  /// 设置VPN状态
  void _setStatus(VpnStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusStreamController.add(_status);
    }
  }
  
  /// 释放资源
  @override
  Future<void> dispose() async {
    await stop();
    await _statusStreamController.close();
  }
} 