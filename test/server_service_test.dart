import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_v2_android/models/server/server_config.dart';
import 'package:flutter_v2_android/services/servers/server_service.dart';
import 'package:flutter_v2_android/services/storage/storage_service.dart';
import 'package:flutter_v2_android/utils/logger.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// 生成Mock类
@GenerateMocks([StorageService])
import 'server_service_test.mocks.dart';

void main() {
  // 初始化测试前的设置
  late MockStorageService mockStorageService;
  late ServerService serverService;
  
  // 测试数据
  final testServers = [
    ServerConfig(
      id: 1,
      name: '测试服务器1',
      address: 'test1.example.com',
      port: 443,
      protocol: 'vmess',
      uuid: 'test-uuid-1',
      alterId: 0,
      security: 'auto',
      tls: true,
      network: 'ws',
      wsPath: '/path1',
      remarks: '测试用1',
      subscriptionId: null,
      isSelected: true,
    ),
    ServerConfig(
      id: 2,
      name: '测试服务器2',
      address: 'test2.example.com',
      port: 443,
      protocol: 'vmess',
      uuid: 'test-uuid-2',
      alterId: 0,
      security: 'auto',
      tls: true,
      network: 'ws',
      wsPath: '/path2',
      remarks: '测试用2',
      subscriptionId: null,
      isSelected: false,
    ),
  ];
  
  setUp(() {
    // 初始化日志
    LoggerUtil.debugEnabled = true;
    
    // 初始化Mock服务
    mockStorageService = MockStorageService();
    
    // 创建服务器服务
    serverService = ServerService(storageService: mockStorageService);
    
    // 配置Mock行为
    when(mockStorageService.getServerList()).thenAnswer((_) async => List<Map<String, dynamic>>.from(
      testServers.map((server) => server.toJson())
    ));
    
    when(mockStorageService.saveServerList(any)).thenAnswer((_) async => true);
  });
  
  group('服务器服务测试', () {
    test('获取所有服务器', () async {
      // 调用获取所有服务器方法
      final servers = await serverService.getServers();
      
      // 验证结果
      expect(servers.length, 2);
      expect(servers[0].id, 1);
      expect(servers[0].name, '测试服务器1');
      expect(servers[1].id, 2);
      expect(servers[1].name, '测试服务器2');
    });
    
    test('获取服务器', () async {
      // 调用获取服务器方法
      final server = await serverService.getServer(1);
      
      // 验证结果
      expect(server, isNotNull);
      expect(server!.id, 1);
      expect(server.name, '测试服务器1');
    });
    
    test('获取不存在的服务器应该返回null', () async {
      // 调用获取服务器方法
      final server = await serverService.getServer(999);
      
      // 验证结果
      expect(server, isNull);
    });
    
    test('获取当前选中的服务器', () async {
      // 调用获取当前选中的服务器方法
      final server = await serverService.getSelectedServer();
      
      // 验证结果
      expect(server, isNotNull);
      expect(server!.id, 1);
      expect(server.isSelected, isTrue);
    });
    
    test('添加服务器', () async {
      // 创建新服务器
      final newServer = ServerConfig(
        id: 0, // 自动分配ID
        name: '新服务器',
        address: 'new.example.com',
        port: 443,
        protocol: 'vmess',
        uuid: 'new-uuid',
        alterId: 0,
        security: 'auto',
        tls: true,
        network: 'tcp',
        wsPath: '',
        remarks: '新添加的',
        subscriptionId: null,
        isSelected: false,
      );
      
      // 模拟保存操作
      when(mockStorageService.saveServerList(any)).thenAnswer((_) async => true);
      
      // 调用添加服务器方法
      final result = await serverService.addServer(newServer);
      
      // 验证结果
      expect(result, isTrue);
      verify(mockStorageService.saveServerList(any)).called(1);
    });
    
    test('更新服务器', () async {
      // 创建更新后的服务器
      final updatedServer = ServerConfig(
        id: 1,
        name: '更新后的服务器',
        address: 'updated.example.com',
        port: 443,
        protocol: 'vmess',
        uuid: 'test-uuid-1',
        alterId: 0,
        security: 'auto',
        tls: true,
        network: 'ws',
        wsPath: '/path1',
        remarks: '已更新',
        subscriptionId: null,
        isSelected: true,
      );
      
      // 模拟保存操作
      when(mockStorageService.saveServerList(any)).thenAnswer((_) async => true);
      
      // 调用更新服务器方法
      final result = await serverService.updateServer(updatedServer);
      
      // 验证结果
      expect(result, isTrue);
      verify(mockStorageService.saveServerList(any)).called(1);
    });
    
    test('删除服务器', () async {
      // 模拟保存操作
      when(mockStorageService.saveServerList(any)).thenAnswer((_) async => true);
      
      // 调用删除服务器方法
      final result = await serverService.deleteServer(1);
      
      // 验证结果
      expect(result, isTrue);
      verify(mockStorageService.saveServerList(any)).called(1);
    });
    
    test('选择服务器', () async {
      // 模拟保存操作
      when(mockStorageService.saveServerList(any)).thenAnswer((_) async => true);
      
      // 调用选择服务器方法
      final result = await serverService.selectServer(2);
      
      // 验证结果
      expect(result, isTrue);
      verify(mockStorageService.saveServerList(any)).called(1);
    });
  });
} 