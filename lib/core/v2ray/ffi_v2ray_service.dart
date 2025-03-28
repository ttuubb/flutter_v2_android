import 'dart:async';
import 'dart:io';

import 'package:flutter_v2_android/core/config/v2ray_config_generator.dart';
import 'package:flutter_v2_android/core/ffi/v2ray_ffi.dart';
import 'package:flutter_v2_android/core/v2ray/v2ray_service.dart';
import 'package:flutter_v2_android/models/config/app_settings.dart';
import 'package:flutter_v2_android/models/server/server_config.dart';

/// 基于FFI的V2Ray服务实现
class FFIv2RayService implements V2RayService {
  static final FFIv2RayService _instance = FFIv2RayService._internal();
  
  /// 单例模式
  factory FFIv2RayService() => _instance;
  
  /// 构造函数
  FFIv2RayService._internal();
  
  /// 当前V2Ray状态
  V2RayStatus _status = V2RayStatus.stopped;
  
  /// 日志流控制器
  final StreamController<String> _logStreamController = StreamController<String>.broadcast();
  
  /// 流量统计流控制器
  final StreamController<TrafficStats> _trafficStreamController = StreamController<TrafficStats>.broadcast();
  
  /// 定时器，用于模拟流量统计
  Timer? _trafficTimer;
  
  /// 最后一次流量统计
  TrafficStats _lastTrafficStats = TrafficStats();
  
  /// 随机数生成器
  final _random = <int>[];
  
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
      // 初始化FFI绑定
      await V2RayFFI.init();
      
      // 记录日志
      _logStreamController.add('初始化FFI V2Ray服务成功');
      final version = await V2RayFFI.getVersion();
      _logStreamController.add('V2Ray版本: $version');
      
      _status = V2RayStatus.stopped;
    } catch (e) {
      _logStreamController.add('初始化FFI V2Ray服务失败: $e');
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
      _logStreamController.add('正在启动V2Ray服务...');
      
      // 生成配置
      final config = V2RayConfigGenerator.generateConfig(serverConfig, settings);
      _logStreamController.add('配置生成完成');
      
      // 启动V2Ray
      final result = await V2RayFFI.start(config);
      if (result != 0) {
        throw Exception('启动V2Ray失败，错误码: $result');
      }
      
      _logStreamController.add('V2Ray服务启动成功');
      _status = V2RayStatus.running;
      
      // 开始模拟流量统计
      _startTrafficStats();
      
      return true;
    } catch (e) {
      _logStreamController.add('启动V2Ray服务失败: $e');
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
      _logStreamController.add('正在停止V2Ray服务...');
      
      // 停止流量统计
      _stopTrafficStats();
      
      // 停止V2Ray
      await V2RayFFI.stop();
      
      _logStreamController.add('V2Ray服务已停止');
      _status = V2RayStatus.stopped;
      
      return true;
    } catch (e) {
      _logStreamController.add('停止V2Ray服务失败: $e');
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
      _logStreamController.add('测试服务器延迟: ${serverConfig.address}:${serverConfig.port}');
      final latency = await V2RayFFI.testLatency(serverConfig.address, serverConfig.port, timeoutMs);
      
      if (latency < 0) {
        _logStreamController.add('测试延迟失败');
        return null;
      }
      
      _logStreamController.add('延迟: ${latency}ms');
      return latency;
    } catch (e) {
      _logStreamController.add('测试延迟出错: $e');
      return null;
    }
  }
  
  /// 清理资源
  @override
  Future<void> dispose() async {
    await stop();
    _stopTrafficStats();
    await _logStreamController.close();
    await _trafficStreamController.close();
  }
  
  /// 启动流量统计
  void _startTrafficStats() {
    _stopTrafficStats();
    
    // 重置流量统计
    _lastTrafficStats = TrafficStats();
    
    // 创建定时器，每秒更新一次流量统计
    _trafficTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateTrafficStats();
    });
  }
  
  /// 停止流量统计
  void _stopTrafficStats() {
    _trafficTimer?.cancel();
    _trafficTimer = null;
  }
  
  /// 更新流量统计（模拟实现）
  void _updateTrafficStats() {
    if (_status != V2RayStatus.running) return;
    
    // 模拟随机流量数据
    // 实际实现中应该从V2Ray核心获取
    final uploadSpeed = _getRandomSpeed();
    final downloadSpeed = _getRandomSpeed();
    
    // 累计总流量
    final totalUpload = _lastTrafficStats.totalUpload + uploadSpeed;
    final totalDownload = _lastTrafficStats.totalDownload + downloadSpeed;
    
    // 创建新的流量统计对象
    final stats = TrafficStats(
      uploadSpeed: uploadSpeed,
      downloadSpeed: downloadSpeed,
      totalUpload: totalUpload,
      totalDownload: totalDownload,
    );
    
    // 更新最后一次流量统计
    _lastTrafficStats = stats;
    
    // 发送到流量统计流
    _trafficStreamController.add(stats);
  }
  
  /// 获取随机速度（用于模拟流量统计）
  int _getRandomSpeed() {
    _fillRandomIfEmpty();
    return _random.first * 1000 + _random.last * 10; // 模拟0-1MB/s的速度
  }
  
  /// 填充随机数数组
  void _fillRandomIfEmpty() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final digits = ms.toString().split('').map(int.parse).toList();
    _random.clear();
    _random.addAll(digits);
  }
} 