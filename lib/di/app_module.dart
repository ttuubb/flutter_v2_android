import 'package:flutter_v2_android/core/v2ray/ffi_v2ray_service.dart';
import 'package:flutter_v2_android/core/v2ray/v2ray_service.dart';
import 'package:flutter_v2_android/core/vpn/android_vpn_service.dart';
import 'package:flutter_v2_android/core/vpn/vpn_service.dart';
import 'package:flutter_v2_android/services/connection/connection_service.dart';
import 'package:flutter_v2_android/services/server/server_service.dart';
import 'package:flutter_v2_android/services/settings/settings_service.dart';
import 'package:flutter_v2_android/services/storage/storage_service.dart';
import 'package:get_it/get_it.dart';

/// 全局依赖注入容器
final GetIt getIt = GetIt.instance;

/// 应用依赖注入模块
class AppModule {
  /// 初始化依赖注入
  static Future<void> init() async {
    // 注册服务实现
    _registerCoreServices();
    _registerBusinessServices();
    
    // 初始化服务
    await _initServices();
  }
  
  /// 注册核心服务
  static void _registerCoreServices() {
    // V2Ray服务
    getIt.registerSingleton<V2RayService>(FFIv2RayService());
    
    // VPN服务
    getIt.registerSingleton<VpnService>(AndroidVpnService());
    
    // 存储服务
    getIt.registerSingleton<StorageService>(StorageService());
  }
  
  /// 注册业务逻辑服务
  static void _registerBusinessServices() {
    // 服务器管理服务
    getIt.registerSingleton<ServerService>(ServerService());
    
    // 连接管理服务
    getIt.registerSingleton<ConnectionService>(ConnectionService());
    
    // 设置服务
    getIt.registerSingleton<SettingsService>(SettingsService());
  }
  
  /// 初始化服务
  static Future<void> _initServices() async {
    // 初始化V2Ray服务
    await getIt<V2RayService>().init();
    
    // 初始化VPN服务
    await getIt<VpnService>().init();
    
    // 初始化存储服务
    await getIt<StorageService>().init();
    
    // 初始化服务器服务
    await getIt<ServerService>().init();
    
    // 初始化设置服务
    await getIt<SettingsService>().init();
    
    // 初始化连接服务
    await getIt<ConnectionService>().init();
  }
} 