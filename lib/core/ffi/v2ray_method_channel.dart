import 'package:flutter/services.dart';

/// V2Ray方法通道
/// 
/// 提供与Android原生代码通信的方法通道
class V2RayMethodChannel {
  /// 方法通道名称
  static const MethodChannel _channel = MethodChannel('com.v2ray.ang.flutter_v2_android/v2ray');
  
  /// 单例实例
  static final V2RayMethodChannel _instance = V2RayMethodChannel._internal();
  
  /// 工厂构造函数
  factory V2RayMethodChannel() => _instance;
  
  /// 私有构造函数
  V2RayMethodChannel._internal();
  
  /// 启动V2Ray服务
  /// 
  /// [config] V2Ray配置JSON字符串
  /// 返回启动结果代码，0表示成功
  Future<int> start(String config) async {
    try {
      final result = await _channel.invokeMethod<int>('start', {'config': config});
      return result ?? -1;
    } on PlatformException catch (e) {
      print('启动V2Ray服务失败: ${e.message}');
      return -1;
    }
  }
  
  /// 停止V2Ray服务
  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stop');
    } on PlatformException catch (e) {
      print('停止V2Ray服务失败: ${e.message}');
    }
  }
  
  /// 获取V2Ray版本
  /// 
  /// 返回V2Ray版本字符串
  Future<String> getVersion() async {
    try {
      final version = await _channel.invokeMethod<String>('getVersion');
      return version ?? 'unknown';
    } on PlatformException catch (e) {
      print('获取V2Ray版本失败: ${e.message}');
      return 'unknown';
    }
  }
  
  /// 测试服务器延迟
  /// 
  /// [host] 服务器地址
  /// [port] 服务器端口
  /// [timeoutMs] 超时时间（毫秒）
  /// 返回延迟时间（毫秒），小于0表示测试失败
  Future<int> testLatency(String host, int port, {int timeoutMs = 5000}) async {
    try {
      final latency = await _channel.invokeMethod<int>(
        'testLatency', 
        {
          'host': host,
          'port': port,
          'timeout': timeoutMs
        }
      );
      return latency ?? -1;
    } on PlatformException catch (e) {
      print('测试延迟失败: ${e.message}');
      return -1;
    }
  }
} 