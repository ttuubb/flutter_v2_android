import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_v2_android/core/v2ray/v2ray_service.dart';
import 'package:flutter_v2_android/core/vpn/vpn_service.dart';
import 'package:flutter_v2_android/models/config/app_settings.dart';
import 'package:flutter_v2_android/models/server/server_config.dart';
import 'package:flutter_v2_android/services/connection/connection_service.dart';
import 'package:flutter_v2_android/services/servers/server_service.dart';
import 'package:flutter_v2_android/services/settings/settings_service.dart';
import 'package:flutter_v2_android/utils/logger.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// 生成Mock类
@GenerateMocks([V2RayService, VpnService, ServerService, SettingsService])
import 'connection_service_test.mocks.dart';

void main() {
  // 初始化测试前的设置
  late MockV2RayService mockV2RayService;
  late MockVpnService mockVpnService;
  late MockServerService mockServerService;
  late MockSettingsService mockSettingsService;
  late ConnectionService connectionService;
  
  // 测试数据
  late ServerConfig testServer;
  late AppSettings testSettings;
  
  setUp(() {
    // 初始化日志
    LoggerUtil.debugEnabled = true;
    
    // 初始化Mock服务
    mockV2RayService = MockV2RayService();
    mockVpnService = MockVpnService();
    mockServerService = MockServerService();
    mockSettingsService = MockSettingsService();
    
    // 创建连接服务
    connectionService = ConnectionService(
      v2rayService: mockV2RayService,
      vpnService: mockVpnService,
      serverService: mockServerService,
      settingsService: mockSettingsService,
    );
    
    // 设置测试数据
    testServer = ServerConfig(
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
    
    testSettings = AppSettings(
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
    
    // 配置Mock行为
    when(mockV2RayService.init()).thenAnswer((_) async {});
    when(mockVpnService.init()).thenAnswer((_) async {});
    when(mockV2RayService.status).thenReturn(V2RayStatus.stopped);
    when(mockVpnService.status).thenReturn(VpnStatus.disconnected);
    when(mockServerService.getSelectedServer()).thenAnswer((_) async => testServer);
    when(mockSettingsService.getSettings()).thenAnswer((_) async => testSettings);
  });
  
  group('连接服务测试', () {
    test('初始状态应该是断开连接', () {
      expect(connectionService.status, ConnectionStatus.disconnected);
      expect(connectionService.currentServer, isNull);
    });
    
    test('连接应该启动V2Ray和VPN服务', () async {
      // 配置Mock服务的行为
      when(mockV2RayService.start(any)).thenAnswer((_) async => true);
      when(mockVpnService.start(any)).thenAnswer((_) async => true);
      
      // 调用连接方法
      final result = await connectionService.connect();
      
      // 验证结果
      expect(result, isTrue);
      verify(mockV2RayService.start(testServer)).called(1);
      verify(mockVpnService.start(testSettings)).called(1);
    });
    
    test('V2Ray启动失败应该返回失败', () async {
      // 配置Mock服务的行为
      when(mockV2RayService.start(any)).thenAnswer((_) async => false);
      
      // 调用连接方法
      final result = await connectionService.connect();
      
      // 验证结果
      expect(result, isFalse);
      verify(mockV2RayService.start(testServer)).called(1);
      verifyNever(mockVpnService.start(any));
    });
    
    test('VPN启动失败应该停止V2Ray并返回失败', () async {
      // 配置Mock服务的行为
      when(mockV2RayService.start(any)).thenAnswer((_) async => true);
      when(mockVpnService.start(any)).thenAnswer((_) async => false);
      when(mockV2RayService.stop()).thenAnswer((_) async => true);
      
      // 调用连接方法
      final result = await connectionService.connect();
      
      // 验证结果
      expect(result, isFalse);
      verify(mockV2RayService.start(testServer)).called(1);
      verify(mockVpnService.start(testSettings)).called(1);
      verify(mockV2RayService.stop()).called(1);
    });
    
    test('断开连接应该停止VPN和V2Ray服务', () async {
      // 先连接
      when(mockV2RayService.start(any)).thenAnswer((_) async => true);
      when(mockVpnService.start(any)).thenAnswer((_) async => true);
      await connectionService.connect();
      
      // 配置Mock服务的行为
      when(mockVpnService.stop()).thenAnswer((_) async => true);
      when(mockV2RayService.stop()).thenAnswer((_) async => true);
      
      // 调用断开连接方法
      final result = await connectionService.disconnect();
      
      // 验证结果
      expect(result, isTrue);
      verify(mockVpnService.stop()).called(1);
      verify(mockV2RayService.stop()).called(1);
    });
    
    test('测试当前服务器延迟', () async {
      // 先连接
      when(mockV2RayService.start(any)).thenAnswer((_) async => true);
      when(mockVpnService.start(any)).thenAnswer((_) async => true);
      await connectionService.connect();
      
      // 配置Mock服务的行为
      when(mockV2RayService.testLatency(any)).thenAnswer((_) async => 100);
      
      // 调用测试延迟方法
      final latency = await connectionService.testCurrentLatency();
      
      // 验证结果
      expect(latency, 100);
      verify(mockV2RayService.testLatency(testServer)).called(1);
    });
  });
} 