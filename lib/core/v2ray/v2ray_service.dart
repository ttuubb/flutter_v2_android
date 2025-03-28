import 'dart:async';
import 'dart:convert';

import 'package:flutter_v2_android/core/config/v2ray_config_generator.dart';
import 'package:flutter_v2_android/core/ffi/v2ray_ffi.dart';
import 'package:flutter_v2_android/models/config/app_settings.dart';
import 'package:flutter_v2_android/models/config/server_config.dart';
import 'package:flutter_v2_android/models/stats/traffic_stats.dart';
import 'package:flutter_v2_android/utils/logger.dart';

/// V2Ray状态
enum V2RayStatus {
  /// 停止状态
  stopped,
  /// 启动中
  starting,
  /// 运行状态
  running,
  /// 停止中
  stopping,
  /// 错误状态
  error,
}

/// V2Ray服务
class V2RayService {
  /// FFI接口
  final V2RayFFI _ffi = V2RayFFI();
  
  /// 配置生成器
  final V2RayConfigGenerator _configGenerator = V2RayConfigGenerator();
  
  /// 当前状态
  V2RayStatus _status = V2RayStatus.stopped;
  
  /// 最近错误信息
  String? _lastError;
  
  /// 日志控制器
  final StreamController<String> _logController = StreamController<String>.broadcast();
  
  /// 流量统计控制器
  final StreamController<TrafficStats> _trafficController = StreamController<TrafficStats>.broadcast();
  
  /// 状态控制器
  final StreamController<V2RayStatus> _statusController = StreamController<V2RayStatus>.broadcast();
  
  /// 获取当前状态
  V2RayStatus get status => _status;
  
  /// 获取最近错误信息
  String? get lastError => _lastError;
  
  /// 获取日志流
  Stream<String> get logStream => _logController.stream;
  
  /// 获取流量统计流
  Stream<TrafficStats> get trafficStream => _trafficController.stream;
  
  /// 获取状态流
  Stream<V2RayStatus> get statusStream => _statusController.stream;
  
  /// 构造函数
  V2RayService() {
    // 监听FFI的日志和流量统计
    _setupListeners();
  }
  
  /// 初始化
  Future<void> init() async {
    try {
      LoggerUtil.info('正在初始化V2Ray服务...');
      
      // 初始化FFI
      await _ffi.init();
      
      // 获取V2Ray版本
      final version = await _ffi.getVersion();
      LoggerUtil.info('V2Ray版本: $version');
      
      _updateStatus(V2RayStatus.stopped);
      LoggerUtil.info('V2Ray服务初始化完成');
    } catch (e) {
      _lastError = e.toString();
      _updateStatus(V2RayStatus.error);
      LoggerUtil.error('V2Ray服务初始化失败: $e');
      rethrow;
    }
  }
  
  /// 启动V2Ray
  Future<bool> start(String configJson) async {
    if (_status == V2RayStatus.running || _status == V2RayStatus.starting) {
      LoggerUtil.warn('V2Ray已在运行中');
      return true;
    }
    
    try {
      _updateStatus(V2RayStatus.starting);
      LoggerUtil.info('正在启动V2Ray...');
      
      // 调用FFI启动V2Ray
      final result = await _ffi.start(configJson);
      
      if (result) {
        _updateStatus(V2RayStatus.running);
        LoggerUtil.info('V2Ray启动成功');
        return true;
      } else {
        _lastError = '启动V2Ray失败';
        _updateStatus(V2RayStatus.error);
        LoggerUtil.error(_lastError!);
        return false;
      }
    } catch (e) {
      _lastError = e.toString();
      _updateStatus(V2RayStatus.error);
      LoggerUtil.error('启动V2Ray出错: $e');
      return false;
    }
  }
  
  /// 停止V2Ray
  Future<bool> stop() async {
    if (_status == V2RayStatus.stopped || _status == V2RayStatus.stopping) {
      LoggerUtil.warn('V2Ray已处于停止状态');
      return true;
    }
    
    try {
      _updateStatus(V2RayStatus.stopping);
      LoggerUtil.info('正在停止V2Ray...');
      
      // 调用FFI停止V2Ray
      final result = await _ffi.stop();
      
      if (result) {
        _updateStatus(V2RayStatus.stopped);
        LoggerUtil.info('V2Ray已停止');
        return true;
      } else {
        _lastError = '停止V2Ray失败';
        _updateStatus(V2RayStatus.error);
        LoggerUtil.error(_lastError!);
        return false;
      }
    } catch (e) {
      _lastError = e.toString();
      _updateStatus(V2RayStatus.error);
      LoggerUtil.error('停止V2Ray出错: $e');
      return false;
    }
  }
  
  /// 重启V2Ray
  Future<bool> restart(String configJson) async {
    LoggerUtil.info('正在重启V2Ray...');
    
    // 先停止
    if (_status != V2RayStatus.stopped) {
      await stop();
    }
    
    // 再启动
    return await start(configJson);
  }
  
  /// 测试服务器延迟
  Future<int?> testLatency(ServerConfig serverConfig) async {
    try {
      LoggerUtil.info('测试服务器延迟: ${serverConfig.address}:${serverConfig.port}');
      
      // 构建测试参数
      final server = '${serverConfig.address}:${serverConfig.port}';
      
      // 调用FFI测试延迟
      final latency = await _ffi.testLatency(server);
      
      if (latency >= 0) {
        LoggerUtil.info('服务器延迟: ${latency}ms');
        return latency;
      } else {
        LoggerUtil.warn('测试延迟失败');
        return null;
      }
    } catch (e) {
      LoggerUtil.error('测试延迟出错: $e');
      return null;
    }
  }
  
  /// 获取流量统计
  Future<TrafficStats?> getStats() async {
    try {
      return await _ffi.getStats();
    } catch (e) {
      LoggerUtil.error('获取流量统计出错: $e');
      return null;
    }
  }
  
  /// 设置监听器
  void _setupListeners() {
    // 监听FFI的流量统计
    _ffi.statsStream.listen((stats) {
      _trafficController.add(stats);
    });
    
    // 监听FFI的日志
    _ffi.logStream.listen((log) {
      _logController.add(log);
    });
  }
  
  /// 更新状态
  void _updateStatus(V2RayStatus newStatus) {
    if (_status != newStatus) {
      _status = newStatus;
      _statusController.add(_status);
    }
  }
  
  /// 清理资源
  Future<void> dispose() async {
    try {
      LoggerUtil.info('正在清理V2Ray服务资源...');
      
      // 确保V2Ray已停止
      if (_status == V2RayStatus.running || _status == V2RayStatus.starting) {
        await stop();
      }
      
      // 清理FFI资源
      await _ffi.dispose();
      
      // 关闭控制器
      await _logController.close();
      await _trafficController.close();
      await _statusController.close();
      
      LoggerUtil.info('V2Ray服务资源已清理');
    } catch (e) {
      LoggerUtil.error('清理V2Ray服务资源出错: $e');
    }
  }
}

/// 流量统计模型
class TrafficStats {
  /// 上传速度（字节/秒）
  final int uploadSpeed;
  
  /// 下载速度（字节/秒）
  final int downloadSpeed;
  
  /// 总上传流量（字节）
  final int totalUpload;
  
  /// 总下载流量（字节）
  final int totalDownload;
  
  /// 构造函数
  TrafficStats({
    this.uploadSpeed = 0,
    this.downloadSpeed = 0,
    this.totalUpload = 0,
    this.totalDownload = 0,
  });
  
  /// 创建副本
  TrafficStats copyWith({
    int? uploadSpeed,
    int? downloadSpeed,
    int? totalUpload,
    int? totalDownload,
  }) {
    return TrafficStats(
      uploadSpeed: uploadSpeed ?? this.uploadSpeed,
      downloadSpeed: downloadSpeed ?? this.downloadSpeed,
      totalUpload: totalUpload ?? this.totalUpload,
      totalDownload: totalDownload ?? this.totalDownload,
    );
  }
} 