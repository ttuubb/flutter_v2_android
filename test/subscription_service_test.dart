import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_v2_android/models/sub/subscription.dart';
import 'package:flutter_v2_android/services/servers/server_service.dart';
import 'package:flutter_v2_android/services/storage/storage_service.dart';
import 'package:flutter_v2_android/services/sub/subscription_service.dart';
import 'package:flutter_v2_android/utils/logger.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;

// 生成Mock类
@GenerateMocks([StorageService, ServerService, http.Client])
import 'subscription_service_test.mocks.dart';

void main() {
  // 初始化测试前的设置
  late MockStorageService mockStorageService;
  late MockServerService mockServerService;
  late MockClient mockHttpClient;
  late SubscriptionService subscriptionService;
  
  // 测试数据
  final testSubscriptions = [
    Subscription(
      id: 1,
      name: '测试订阅1',
      url: 'https://test1.example.com/sub',
      lastUpdated: DateTime(2023, 1, 1),
      autoUpdate: true,
      updateInterval: 24,
    ),
    Subscription(
      id: 2,
      name: '测试订阅2',
      url: 'https://test2.example.com/sub',
      lastUpdated: DateTime(2023, 1, 2),
      autoUpdate: false,
      updateInterval: 72,
    ),
  ];
  
  // 模拟订阅内容
  const mockSubscriptionContent = '''
    vmess://eyJhZGQiOiJ0ZXN0MS5leGFtcGxlLmNvbSIsImFpZCI6IjAiLCJpZCI6InRlc3QtdXVpZC0xIiwibmV0Ijoid3MiLCJwYXRoIjoiL3BhdGgxIiwicG9ydCI6IjQ0MyIsInBzIjoi5rWL6K+V5pyN5Yqh5Zmo77yaMSIsInRscyI6InRscyIsInR5cGUiOiJub25lIiwidiI6IjIifQ==
    vmess://eyJhZGQiOiJ0ZXN0Mi5leGFtcGxlLmNvbSIsImFpZCI6IjAiLCJpZCI6InRlc3QtdXVpZC0yIiwibmV0Ijoid3MiLCJwYXRoIjoiL3BhdGgyIiwicG9ydCI6IjQ0MyIsInBzIjoi5rWL6K+V5pyN5Yqh5Zmo77yaMiIsInRscyI6InRscyIsInR5cGUiOiJub25lIiwidiI6IjIifQ==
  ''';
  
  setUp(() {
    // 初始化日志
    LoggerUtil.debugEnabled = true;
    
    // 初始化Mock服务
    mockStorageService = MockStorageService();
    mockServerService = MockServerService();
    mockHttpClient = MockClient();
    
    // 创建订阅服务
    subscriptionService = SubscriptionService(
      storageService: mockStorageService,
      serverService: mockServerService,
      httpClient: mockHttpClient,
    );
    
    // 配置Mock行为
    when(mockStorageService.getSubscriptionList()).thenAnswer((_) async => List<Map<String, dynamic>>.from(
      testSubscriptions.map((sub) => sub.toJson())
    ));
    
    when(mockStorageService.saveSubscriptionList(any)).thenAnswer((_) async => true);
    
    when(mockHttpClient.get(any)).thenAnswer((_) async => http.Response(
      mockSubscriptionContent,
      200,
      headers: {'content-type': 'text/plain'},
    ));
  });
  
  group('订阅服务测试', () {
    test('获取所有订阅', () async {
      // 调用获取所有订阅方法
      final subscriptions = await subscriptionService.getSubscriptions();
      
      // 验证结果
      expect(subscriptions.length, 2);
      expect(subscriptions[0].id, 1);
      expect(subscriptions[0].name, '测试订阅1');
      expect(subscriptions[1].id, 2);
      expect(subscriptions[1].name, '测试订阅2');
    });
    
    test('获取订阅', () async {
      // 调用获取订阅方法
      final subscription = await subscriptionService.getSubscription(1);
      
      // 验证结果
      expect(subscription, isNotNull);
      expect(subscription!.id, 1);
      expect(subscription.name, '测试订阅1');
    });
    
    test('获取不存在的订阅应该返回null', () async {
      // 调用获取订阅方法
      final subscription = await subscriptionService.getSubscription(999);
      
      // 验证结果
      expect(subscription, isNull);
    });
    
    test('添加订阅', () async {
      // 创建新订阅
      final newSubscription = Subscription(
        id: 0, // 自动分配ID
        name: '新订阅',
        url: 'https://new.example.com/sub',
        lastUpdated: DateTime.now(),
        autoUpdate: true,
        updateInterval: 24,
      );
      
      // 模拟保存操作
      when(mockStorageService.saveSubscriptionList(any)).thenAnswer((_) async => true);
      
      // 调用添加订阅方法
      final result = await subscriptionService.addSubscription(newSubscription);
      
      // 验证结果
      expect(result, isTrue);
      verify(mockStorageService.saveSubscriptionList(any)).called(1);
    });
    
    test('更新订阅', () async {
      // 创建更新后的订阅
      final updatedSubscription = Subscription(
        id: 1,
        name: '更新后的订阅',
        url: 'https://updated.example.com/sub',
        lastUpdated: DateTime.now(),
        autoUpdate: false,
        updateInterval: 48,
      );
      
      // 模拟保存操作
      when(mockStorageService.saveSubscriptionList(any)).thenAnswer((_) async => true);
      
      // 调用更新订阅方法
      final result = await subscriptionService.updateSubscription(updatedSubscription);
      
      // 验证结果
      expect(result, isTrue);
      verify(mockStorageService.saveSubscriptionList(any)).called(1);
    });
    
    test('删除订阅', () async {
      // 模拟保存操作
      when(mockStorageService.saveSubscriptionList(any)).thenAnswer((_) async => true);
      when(mockServerService.getServers()).thenAnswer((_) async => []);
      
      // 调用删除订阅方法
      final result = await subscriptionService.deleteSubscription(1);
      
      // 验证结果
      expect(result, isTrue);
      verify(mockStorageService.saveSubscriptionList(any)).called(1);
    });
    
    test('更新订阅内容', () async {
      // 模拟服务器服务
      when(mockServerService.getServers()).thenAnswer((_) async => []);
      when(mockServerService.addServer(any)).thenAnswer((_) async => true);
      
      // 调用更新订阅内容方法
      final result = await subscriptionService.updateSubscriptionContent(1);
      
      // 验证结果
      expect(result, isTrue);
      verify(mockHttpClient.get(any)).called(1);
      verify(mockServerService.addServer(any)).called(greaterThan(0));
    });
  });
} 