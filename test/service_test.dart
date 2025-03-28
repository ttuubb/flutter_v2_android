import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_v2_android/core/config/v2ray_config_generator.dart';
import 'package:flutter_v2_android/models/server/server_config.dart';
import 'package:flutter_v2_android/models/config/app_settings.dart';
import 'package:flutter_v2_android/utils/logger.dart';

void main() {
  setUp(() {
    // 初始化日志
    LoggerUtil.debugEnabled = true;
  });

  group('配置生成器测试', () {
    test('生成V2Ray配置', () {
      // 创建测试服务器配置
      final server = ServerConfig(
        id: 1,
        name: '测试服务器',
        address: 'test.example.com',
        port: 443,
        protocol: 'vmess',
        uuid: 'test-uuid',
        alterId: 0,
        security: 'auto',
        tls: true,
        network: 'ws',
        wsPath: '/path',
        remarks: '测试用',
        subscriptionId: null,
        isSelected: true,
      );

      // 创建测试应用设置
      final settings = AppSettings(
        socksPort: 1080,
        httpPort: 1081,
        enableUdp: true,
        routingMode: 0,
        autoConnect: false,
        bypassLan: true,
        bypassChinese: false,
        customDns: '8.8.8.8,8.8.4.4',
        enableSniffing: true,
        theme: 'light',
        language: 'zh',
      );

      // 生成配置
      final configGenerator = V2RayConfigGenerator();
      final config = configGenerator.generateConfig(server, settings);

      // 验证配置
      expect(config, isNotNull);
      expect(config, isNotEmpty);
      expect(config, contains('"protocol": "vmess"'));
      expect(config, contains('"address": "test.example.com"'));
      expect(config, contains('"port": 443'));
      expect(config, contains('"id": "test-uuid"'));
      expect(config, contains('"alterId": 0'));
      expect(config, contains('"security": "auto"'));
      expect(config, contains('"network": "ws"'));
      expect(config, contains('"path": "/path"'));
      expect(config, contains('"tls": "tls"'));
      expect(config, contains('"port": 1080')); // socks端口
    });
  });
} 