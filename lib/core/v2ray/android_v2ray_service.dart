import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_v2_android/core/v2ray/v2ray_service.dart';
import 'package:flutter_v2_android/models/config/app_settings.dart';
import 'package:flutter_v2_android/models/server/server_config.dart';
import 'package:flutter_v2_android/utils/constants/channel_constants.dart';

/// Android平台上的V2Ray服务实现
class AndroidV2RayService implements V2RayService {
  static final AndroidV2RayService _instance = AndroidV2RayService._internal();

  /// 单例模式
  factory AndroidV2RayService() => _instance;

  /// 构造函数
  AndroidV2RayService._internal();

  /// 平台通道
  final MethodChannel _channel = const MethodChannel(ChannelConstants.v2rayServiceChannel);

  /// 日志事件通道
  final EventChannel _logEventChannel = const EventChannel(ChannelConstants.v2rayLogChannel);

  /// 流量统计事件通道
  final EventChannel _trafficEventChannel = const EventChannel(ChannelConstants.v2rayTrafficChannel);
  
  /// 当前V2Ray状态
  V2RayStatus _status = V2RayStatus.stopped;
  
  /// 日志流控制器
  final StreamController<String> _logStreamController = StreamController<String>.broadcast();
  
  /// 流量统计流控制器
  final StreamController<TrafficStats> _trafficStreamController = StreamController<TrafficStats>.broadcast();
  
  /// 获取当前状态
  @override
  V2RayStatus get status => _status;
  
  /// 获取日志流
  @override
  Stream<String> get logStream => _logStreamController.stream;
  
  /// 获取流量统计流
  @override
  Stream<TrafficStats> get trafficStream => _trafficStreamController.stream;
  
  /// 初始化V2Ray核心
  @override
  Future<void> init() async {
    try {
      // 监听日志事件
      _logEventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is String) {
            _logStreamController.add(event);
          }
        },
        onError: (dynamic error) {
          print('日志流错误: $error');
        },
      );
      
      // 监听流量统计事件
      _trafficEventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          if (event is Map) {
            final trafficStats = TrafficStats(
              uploadSpeed: event['uploadSpeed'] ?? 0,
              downloadSpeed: event['downloadSpeed'] ?? 0,
              totalUpload: event['totalUpload'] ?? 0,
              totalDownload: event['totalDownload'] ?? 0,
            );
            _trafficStreamController.add(trafficStats);
          }
        },
        onError: (dynamic error) {
          print('流量统计流错误: $error');
        },
      );
      
      // 初始化核心
      await _channel.invokeMethod('init');
      _status = V2RayStatus.stopped;
    } catch (e) {
      print('初始化V2Ray核心出错: $e');
      _status = V2RayStatus.error;
      rethrow;
    }
  }
  
  /// 启动V2Ray服务
  @override
  Future<bool> start(ServerConfig serverConfig, AppSettings settings) async {
    if (_status == V2RayStatus.starting || _status == V2RayStatus.running) {
      return true;
    }
    
    try {
      _status = V2RayStatus.starting;
      
      // 生成配置
      final config = await _generateConfig(serverConfig, settings);
      
      // 启动服务
      final result = await _channel.invokeMethod('start', {
        'config': config,
        'enableLocalDns': settings.domainStrategy == 1,
        'forwardIpv6': settings.enableUdp,
        'enableFakeDns': settings.routingMode == 2 || settings.routingMode == 3,
      });
      
      if (result == true) {
        _status = V2RayStatus.running;
        return true;
      } else {
        _status = V2RayStatus.error;
        return false;
      }
    } catch (e) {
      print('启动V2Ray服务出错: $e');
      _status = V2RayStatus.error;
      return false;
    }
  }
  
  /// 停止V2Ray服务
  @override
  Future<bool> stop() async {
    if (_status == V2RayStatus.stopped || _status == V2RayStatus.stopping) {
      return true;
    }
    
    try {
      _status = V2RayStatus.stopping;
      final result = await _channel.invokeMethod('stop');
      if (result == true) {
        _status = V2RayStatus.stopped;
        return true;
      } else {
        _status = V2RayStatus.error;
        return false;
      }
    } catch (e) {
      print('停止V2Ray服务出错: $e');
      _status = V2RayStatus.error;
      return false;
    }
  }
  
  /// 重启V2Ray服务
  @override
  Future<bool> restart(ServerConfig serverConfig, AppSettings settings) async {
    await stop();
    return await start(serverConfig, settings);
  }
  
  /// 测试延迟
  @override
  Future<int?> testLatency(ServerConfig serverConfig, {int timeoutMs = 5000}) async {
    try {
      final result = await _channel.invokeMethod('measureLatency', {
        'address': serverConfig.address,
        'port': serverConfig.port,
        'timeout': timeoutMs,
      });
      
      return result is int ? result : null;
    } catch (e) {
      print('测试延迟出错: $e');
      return null;
    }
  }
  
  /// 清理资源
  @override
  Future<void> dispose() async {
    await stop();
    await _logStreamController.close();
    await _trafficStreamController.close();
  }
  
  /// 生成配置
  Future<String> _generateConfig(ServerConfig serverConfig, AppSettings settings) async {
    // 这只是一个基本示例，实际生成的配置会更复杂
    final Map<String, dynamic> configMap = {
      'inbounds': [
        {
          'tag': 'socks',
          'port': settings.socksPort,
          'listen': settings.shareLan ? '0.0.0.0' : '127.0.0.1',
          'protocol': 'socks',
          'settings': {
            'auth': 'noauth',
            'udp': settings.enableUdp,
            'ip': settings.shareLan ? '0.0.0.0' : '127.0.0.1',
          },
        },
        {
          'tag': 'http',
          'port': settings.httpPort,
          'listen': settings.shareLan ? '0.0.0.0' : '127.0.0.1',
          'protocol': 'http',
          'settings': {
            'timeout': 300,
          },
        }
      ],
      'outbounds': [
        _generateOutbound(serverConfig),
        {
          'tag': 'direct',
          'protocol': 'freedom',
          'settings': {}
        },
        {
          'tag': 'block',
          'protocol': 'blackhole',
          'settings': {}
        }
      ],
      'routing': _generateRouting(settings),
      'dns': _generateDns(settings),
    };
    
    return jsonEncode(configMap);
  }
  
  /// 生成出站配置
  Map<String, dynamic> _generateOutbound(ServerConfig serverConfig) {
    switch (serverConfig.protocol.toLowerCase()) {
      case 'vmess':
        return {
          'tag': 'proxy',
          'protocol': 'vmess',
          'settings': {
            'vnext': [
              {
                'address': serverConfig.address,
                'port': serverConfig.port,
                'users': [
                  {
                    'id': serverConfig.password,
                    'alterId': 0,
                    'security': serverConfig.encryption,
                  }
                ]
              }
            ]
          },
          'streamSettings': {
            'network': serverConfig.network,
            'security': serverConfig.security,
          },
          'mux': {
            'enabled': serverConfig.enableMux,
            'concurrency': serverConfig.muxConcurrency,
          }
        };
      
      // 其他协议的实现类似
      default:
        throw Exception('不支持的协议类型: ${serverConfig.protocol}');
    }
  }
  
  /// 生成路由配置
  Map<String, dynamic> _generateRouting(AppSettings settings) {
    // 基本路由规则
    final Map<String, dynamic> routing = {
      'domainStrategy': 'IPIfNonMatch',
      'rules': []
    };
    
    final List<Map<String, dynamic>> rules = [];
    
    // 根据路由模式设置不同的规则
    switch (settings.routingMode) {
      case 0: // 全局
        // 不添加规则，全部走代理
        break;
      
      case 1: // 绕过局域网
        rules.add({
          'type': 'field',
          'ip': ['geoip:private'],
          'outboundTag': 'direct'
        });
        break;
      
      case 2: // 绕过大陆
        rules.add({
          'type': 'field',
          'domain': ['geosite:cn'],
          'outboundTag': 'direct'
        });
        rules.add({
          'type': 'field',
          'ip': ['geoip:cn'],
          'outboundTag': 'direct'
        });
        break;
      
      case 3: // 绕过局域网和大陆
        rules.add({
          'type': 'field',
          'ip': ['geoip:private'],
          'outboundTag': 'direct'
        });
        rules.add({
          'type': 'field',
          'domain': ['geosite:cn'],
          'outboundTag': 'direct'
        });
        rules.add({
          'type': 'field',
          'ip': ['geoip:cn'],
          'outboundTag': 'direct'
        });
        break;
      
      case 4: // 全局直连
        rules.add({
          'type': 'field',
          'outboundTag': 'direct',
          'network': 'tcp,udp'
        });
        break;
      
      case 5: // 自定义
        // 这里应该加载自定义路由规则
        break;
    }
    
    routing['rules'] = rules;
    return routing;
  }
  
  /// 生成DNS配置
  Map<String, dynamic> _generateDns(AppSettings settings) {
    return {
      'servers': [
        settings.customDns,
        '8.8.8.8',
        '1.1.1.1',
      ]
    };
  }
} 