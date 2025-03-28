import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_v2_android/models/stats/traffic_stats.dart';
import 'package:flutter_v2_android/utils/logger.dart';
import 'package:path_provider/path_provider.dart';

/// V2Ray FFI方法类型定义
typedef _StartFuncNative = Int32 Function(Pointer<Utf8>);
typedef _StartFunc = int Function(Pointer<Utf8>);

typedef _StopFuncNative = Void Function();
typedef _StopFunc = void Function();

typedef _TestFuncNative = Int64 Function(Pointer<Utf8>);
typedef _TestFunc = int Function(Pointer<Utf8>);

typedef _VersionFuncNative = Pointer<Utf8> Function();
typedef _VersionFunc = Pointer<Utf8> Function();

typedef _StatsUpFuncNative = Int64 Function();
typedef _StatsUpFunc = int Function();

typedef _StatsDownFuncNative = Int64 Function();
typedef _StatsDownFunc = int Function();

/// V2Ray FFI绑定类
class V2RayFFI {
  /// 单例实例
  static final V2RayFFI _instance = V2RayFFI._internal();
  
  /// 工厂构造函数
  factory V2RayFFI() => _instance;
  
  /// 内部构造函数
  V2RayFFI._internal();
  
  /// 动态库
  late DynamicLibrary _v2rayLib;
  
  /// V2Ray核心启动函数
  late _StartFunc _start;
  
  /// V2Ray核心停止函数
  late _StopFunc _stop;
  
  /// V2Ray核心测试函数
  late _TestFunc _test;
  
  /// V2Ray核心版本函数
  late _VersionFunc _version;
  
  /// V2Ray上行流量统计函数
  late _StatsUpFunc _statsUp;
  
  /// V2Ray下行流量统计函数
  late _StatsDownFunc _statsDown;
  
  /// 是否已初始化
  bool _initialized = false;
  
  /// 是否运行中
  bool _isRunning = false;
  
  /// 日志控制器
  final _logController = StreamController<String>.broadcast();
  
  /// 流量统计控制器
  final _statsController = StreamController<TrafficStats>.broadcast();
  
  /// 流量定时器
  Timer? _statsTimer;
  
  /// 上行流量计数
  int _upBytes = 0;
  
  /// 下行流量计数
  int _downBytes = 0;
  
  /// 获取日志流
  Stream<String> get logStream => _logController.stream;
  
  /// 获取流量统计流
  Stream<TrafficStats> get statsStream => _statsController.stream;
  
  /// 获取运行状态
  bool get isRunning => _isRunning;
  
  /// 初始化
  Future<void> init() async {
    if (_initialized) {
      return;
    }
    
    try {
      LoggerUtil.info('初始化V2Ray FFI...');
      
      // 加载动态库
      await _loadLibrary();
      
      // 绑定函数
      _bindFunctions();
      
      _initialized = true;
      LoggerUtil.info('V2Ray FFI初始化完成');
    } catch (e) {
      LoggerUtil.error('V2Ray FFI初始化失败: $e');
      rethrow;
    }
  }
  
  /// 加载动态库
  Future<void> _loadLibrary() async {
    try {
      // 确定平台
      if (Platform.isAndroid) {
        _v2rayLib = DynamicLibrary.open('libv2ray.so');
      } else if (Platform.isIOS) {
        _v2rayLib = DynamicLibrary.process();
      } else {
        throw Exception('不支持的平台: ${Platform.operatingSystem}');
      }
    } catch (e) {
      LoggerUtil.error('加载V2Ray动态库失败: $e');
      rethrow;
    }
  }
  
  /// 绑定函数
  void _bindFunctions() {
    try {
      // 绑定C函数
      _start = _v2rayLib.lookupFunction<_StartFuncNative, _StartFunc>('start');
      _stop = _v2rayLib.lookupFunction<_StopFuncNative, _StopFunc>('stop');
      _test = _v2rayLib.lookupFunction<_TestFuncNative, _TestFunc>('test');
      _version = _v2rayLib.lookupFunction<_VersionFuncNative, _VersionFunc>('version');
      _statsUp = _v2rayLib.lookupFunction<_StatsUpFuncNative, _StatsUpFunc>('statsUp');
      _statsDown = _v2rayLib.lookupFunction<_StatsDownFuncNative, _StatsDownFunc>('statsDown');
    } catch (e) {
      LoggerUtil.error('绑定V2Ray函数失败: $e');
      rethrow;
    }
  }
  
  /// 启动V2Ray
  Future<bool> start(String configJson) async {
    if (!_initialized) {
      await init();
    }
    
    if (_isRunning) {
      LoggerUtil.warn('V2Ray已经在运行');
      return true;
    }
    
    try {
      // 将配置保存到临时文件
      final configFile = await _saveConfigToFile(configJson);
      
      LoggerUtil.info('正在启动V2Ray，配置文件: $configFile');
      
      // 调用启动函数
      final configPtr = configFile.toNativeUtf8();
      final result = _start(configPtr);
      malloc.free(configPtr);
      
      if (result != 0) {
        LoggerUtil.error('启动V2Ray失败: $result');
        return false;
      }
      
      _isRunning = true;
      LoggerUtil.info('V2Ray启动成功');
      
      // 启动流量统计
      _startStatsTimer();
      
      return true;
    } catch (e) {
      LoggerUtil.error('启动V2Ray出错: $e');
      return false;
    }
  }
  
  /// 停止V2Ray
  Future<bool> stop() async {
    if (!_isRunning) {
      LoggerUtil.warn('V2Ray未在运行');
      return true;
    }
    
    try {
      LoggerUtil.info('正在停止V2Ray');
      
      // 停止流量统计
      _stopStatsTimer();
      
      // 调用停止函数
      _stop();
      
      _isRunning = false;
      LoggerUtil.info('V2Ray已停止');
      
      return true;
    } catch (e) {
      LoggerUtil.error('停止V2Ray出错: $e');
      return false;
    }
  }
  
  /// 测试服务器延迟
  Future<int> testLatency(String server) async {
    if (!_initialized) {
      await init();
    }
    
    try {
      LoggerUtil.info('测试服务器延迟: $server');
      
      // 调用测试函数
      final serverPtr = server.toNativeUtf8();
      final result = _test(serverPtr);
      malloc.free(serverPtr);
      
      if (result < 0) {
        LoggerUtil.warn('测试延迟失败: $result');
        return -1;
      }
      
      LoggerUtil.info('延迟测试结果: ${result}ms');
      return result;
    } catch (e) {
      LoggerUtil.error('测试延迟出错: $e');
      return -1;
    }
  }
  
  /// 获取V2Ray版本
  Future<String> getVersion() async {
    if (!_initialized) {
      await init();
    }
    
    try {
      // 调用版本函数
      final versionPtr = _version();
      final versionStr = versionPtr.toDartString();
      
      LoggerUtil.info('V2Ray版本: $versionStr');
      return versionStr;
    } catch (e) {
      LoggerUtil.error('获取V2Ray版本出错: $e');
      return 'Unknown';
    }
  }
  
  /// 获取流量统计
  Future<TrafficStats> getStats() async {
    if (!_initialized || !_isRunning) {
      return TrafficStats();
    }
    
    try {
      // 调用统计函数
      final up = _statsUp();
      final down = _statsDown();
      
      // 计算速率
      final upSpeed = up - _upBytes;
      final downSpeed = down - _downBytes;
      
      // 更新总流量
      _upBytes = up;
      _downBytes = down;
      
      final stats = TrafficStats(
        uplink: up,
        downlink: down,
        uplinkSpeed: upSpeed >= 0 ? upSpeed : 0,
        downlinkSpeed: downSpeed >= 0 ? downSpeed : 0,
      );
      
      // 发送流量统计
      _statsController.add(stats);
      
      return stats;
    } catch (e) {
      LoggerUtil.error('获取流量统计出错: $e');
      return TrafficStats();
    }
  }
  
  /// 启动流量统计定时器
  void _startStatsTimer() {
    _stopStatsTimer();
    
    // 每秒更新一次流量统计
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      getStats();
    });
  }
  
  /// 停止流量统计定时器
  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
    _upBytes = 0;
    _downBytes = 0;
  }
  
  /// 将配置保存到临时文件
  Future<String> _saveConfigToFile(String configJson) async {
    try {
      // 获取临时目录
      final tempDir = await getTemporaryDirectory();
      final configFile = File('${tempDir.path}/v2ray_config.json');
      
      // 写入配置
      await configFile.writeAsString(configJson);
      
      return configFile.path;
    } catch (e) {
      LoggerUtil.error('保存配置文件失败: $e');
      rethrow;
    }
  }
  
  /// 释放资源
  Future<void> dispose() async {
    _stopStatsTimer();
    
    if (_isRunning) {
      await stop();
    }
    
    await _logController.close();
    await _statsController.close();
  }
} 