import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_v2_android/models/servers/proxy_protocol.dart';
import 'package:flutter_v2_android/models/servers/security_type.dart';
import 'package:flutter_v2_android/models/servers/server_config.dart';
import 'package:flutter_v2_android/models/settings/app_settings.dart';
import 'package:flutter_v2_android/services/config/config_generator.dart';
import 'package:flutter_v2_android/utils/logger.dart';

void main() {
  late ConfigGenerator configGenerator;
  late ServerConfig testServer;
  late AppSettings testSettings;

  setUp(() {
    LoggerUtil.debugEnabled = true;
    configGenerator = ConfigGenerator();
    
    // 创建测试服务器配置
    testServer = ServerConfig(
      id: 1,
      name: '测试服务器',
      address: 'test.example.com',
      port: 443,
      protocol: ProxyProtocol.vmess,
      userId: 'test-uuid-1234',
      alterId: 0,
      security: SecurityType.auto,
      network: 'ws',
      path: '/path',
      host: 'test.example.com',
      tls: true,
      subscribedId: 0,
    );
    
    // 创建测试应用设置
    testSettings = AppSettings(
      selectedServerId: 1,
      appTheme: 'dark',
      language: 'zh_CN',
      enableLogFile: true,
      logLevel: 'info',
      dnsServers: ['8.8.8.8', '1.1.1.1'],
      bypassMainland: true,
      enableSniffing: true,
      bypassPrivateNetwork: true,
      mtu: 1500,
      socksPort: 1080,
      httpPort: 1081,
    );
  });

  group('配置生成器测试', () {
    test('生成基础配置', () {
      final config = configGenerator.generateConfig(testServer, testSettings);
      final Map<String, dynamic> configMap = json.decode(config);
      
      // 检查基本结构是否存在
      expect(configMap.containsKey('log'), isTrue);
      expect(configMap.containsKey('inbounds'), isTrue);
      expect(configMap.containsKey('outbounds'), isTrue);
      expect(configMap.containsKey('dns'), isTrue);
      expect(configMap.containsKey('routing'), isTrue);
      
      // 检查日志配置
      expect(configMap['log']['loglevel'], 'info');
      
      // 检查入站配置
      final inbounds = configMap['inbounds'] as List;
      expect(inbounds.length, 2); // SOCKS和HTTP入站
      
      // 检查出站配置
      final outbounds = configMap['outbounds'] as List;
      expect(outbounds.length, greaterThan(1)); // 至少有主出站和直连出站
    });
    
    test('VMess协议配置', () {
      testServer.protocol = ProxyProtocol.vmess;
      final config = configGenerator.generateConfig(testServer, testSettings);
      final Map<String, dynamic> configMap = json.decode(config);
      
      final outbounds = configMap['outbounds'] as List;
      final mainOutbound = outbounds[0] as Map<String, dynamic>;
      
      expect(mainOutbound['protocol'], 'vmess');
      
      final settings = mainOutbound['settings'] as Map<String, dynamic>;
      final vnext = settings['vnext'] as List;
      expect(vnext.length, 1);
      
      final server = vnext[0] as Map<String, dynamic>;
      expect(server['address'], 'test.example.com');
      expect(server['port'], 443);
      
      final users = server['users'] as List;
      expect(users.length, 1);
      expect(users[0]['id'], 'test-uuid-1234');
      expect(users[0]['alterId'], 0);
      expect(users[0]['security'], 'auto');
    });
    
    test('Shadowsocks协议配置', () {
      testServer.protocol = ProxyProtocol.shadowsocks;
      testServer.method = 'aes-256-gcm';
      testServer.password = 'test-password';
      
      final config = configGenerator.generateConfig(testServer, testSettings);
      final Map<String, dynamic> configMap = json.decode(config);
      
      final outbounds = configMap['outbounds'] as List;
      final mainOutbound = outbounds[0] as Map<String, dynamic>;
      
      expect(mainOutbound['protocol'], 'shadowsocks');
      
      final settings = mainOutbound['settings'] as Map<String, dynamic>;
      final servers = settings['servers'] as List;
      expect(servers.length, 1);
      
      final server = servers[0] as Map<String, dynamic>;
      expect(server['address'], 'test.example.com');
      expect(server['port'], 443);
      expect(server['method'], 'aes-256-gcm');
      expect(server['password'], 'test-password');
    });
    
    test('Trojan协议配置', () {
      testServer.protocol = ProxyProtocol.trojan;
      testServer.password = 'trojan-password';
      
      final config = configGenerator.generateConfig(testServer, testSettings);
      final Map<String, dynamic> configMap = json.decode(config);
      
      final outbounds = configMap['outbounds'] as List;
      final mainOutbound = outbounds[0] as Map<String, dynamic>;
      
      expect(mainOutbound['protocol'], 'trojan');
      
      final settings = mainOutbound['settings'] as Map<String, dynamic>;
      final servers = settings['servers'] as List;
      expect(servers.length, 1);
      
      final server = servers[0] as Map<String, dynamic>;
      expect(server['address'], 'test.example.com');
      expect(server['port'], 443);
      expect(server['password'], 'trojan-password');
    });
    
    test('传输层配置', () {
      testServer.network = 'ws';
      testServer.path = '/ws-path';
      testServer.host = 'ws.example.com';
      testServer.tls = true;
      
      final config = configGenerator.generateConfig(testServer, testSettings);
      final Map<String, dynamic> configMap = json.decode(config);
      
      final outbounds = configMap['outbounds'] as List;
      final mainOutbound = outbounds[0] as Map<String, dynamic>;
      
      final streamSettings = mainOutbound['streamSettings'] as Map<String, dynamic>;
      expect(streamSettings['network'], 'ws');
      expect(streamSettings['security'], 'tls');
      
      final wsSettings = streamSettings['wsSettings'] as Map<String, dynamic>;
      expect(wsSettings['path'], '/ws-path');
      
      final headers = wsSettings['headers'] as Map<String, dynamic>;
      expect(headers['Host'], 'ws.example.com');
      
      final tlsSettings = streamSettings['tlsSettings'] as Map<String, dynamic>;
      expect(tlsSettings['serverName'], 'ws.example.com');
    });
    
    test('DNS配置', () {
      testSettings.dnsServers = ['8.8.8.8', '1.1.1.1', '114.114.114.114'];
      
      final config = configGenerator.generateConfig(testServer, testSettings);
      final Map<String, dynamic> configMap = json.decode(config);
      
      final dns = configMap['dns'] as Map<String, dynamic>;
      expect(dns.containsKey('servers'), isTrue);
      
      final servers = dns['servers'] as List;
      expect(servers.contains('8.8.8.8'), isTrue);
      expect(servers.contains('1.1.1.1'), isTrue);
      expect(servers.contains('114.114.114.114'), isTrue);
    });
    
    test('路由配置', () {
      testSettings.bypassMainland = true;
      testSettings.bypassPrivateNetwork = true;
      
      final config = configGenerator.generateConfig(testServer, testSettings);
      final Map<String, dynamic> configMap = json.decode(config);
      
      final routing = configMap['routing'] as Map<String, dynamic>;
      expect(routing.containsKey('rules'), isTrue);
      
      final rules = routing['rules'] as List;
      expect(rules.length, greaterThan(0));
      
      // 检查是否有私有网络绕过规则
      bool hasPrivateNetworkRule = false;
      for (var rule in rules) {
        if ((rule as Map<String, dynamic>)['outboundTag'] == 'direct') {
          if (rule.containsKey('ip') && (rule['ip'] as List).contains('geoip:private')) {
            hasPrivateNetworkRule = true;
            break;
          }
        }
      }
      expect(hasPrivateNetworkRule, isTrue);
      
      // 检查是否有中国大陆绕过规则
      bool hasMainlandRule = false;
      for (var rule in rules) {
        if ((rule as Map<String, dynamic>)['outboundTag'] == 'direct') {
          if (rule.containsKey('ip') && (rule['ip'] as List).contains('geoip:cn')) {
            hasMainlandRule = true;
            break;
          }
        }
      }
      expect(hasMainlandRule, isTrue);
    });
  });
} 