import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_v2_android/views/servers/server_list_screen.dart';
import 'package:flutter_v2_android/views/servers/server_edit_screen.dart';
import 'package:flutter_v2_android/models/servers/server_config.dart';
import 'package:flutter_v2_android/models/servers/proxy_protocol.dart';
import 'package:flutter_v2_android/models/servers/security_type.dart';
import 'package:flutter_v2_android/services/servers/server_service.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([ServerService])
import 'server_list_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  late MockServerService mockServerService;
  
  // 测试服务器列表
  final testServers = [
    ServerConfig(
      id: 1,
      name: '测试服务器1',
      address: 'test1.example.com',
      port: 443,
      protocol: ProxyProtocol.vmess,
      userId: 'test-uuid-1',
      alterId: 0,
      security: SecurityType.auto,
      network: 'ws',
      path: '/path1',
      tls: true,
      subscribedId: 0,
    ),
    ServerConfig(
      id: 2,
      name: '测试服务器2',
      address: 'test2.example.com',
      port: 443,
      protocol: ProxyProtocol.shadowsocks,
      method: 'aes-256-gcm',
      password: 'test-password',
      network: 'tcp',
      subscribedId: 0,
    ),
  ];
  
  setUp(() {
    mockServerService = MockServerService();
    
    // 设置模拟行为
    when(mockServerService.getServers()).thenAnswer((_) async => List.from(testServers));
    when(mockServerService.getServer(1)).thenAnswer((_) async => testServers[0]);
    when(mockServerService.getServer(2)).thenAnswer((_) async => testServers[1]);
    when(mockServerService.addServer(any)).thenAnswer((_) async => true);
    when(mockServerService.updateServer(any)).thenAnswer((_) async => true);
    when(mockServerService.deleteServer(any)).thenAnswer((_) async => true);
    when(mockServerService.selectServer(any)).thenAnswer((_) async => true);
    when(mockServerService.getSelectedServerId()).thenAnswer((_) async => 1);
  });
  
  group('服务器列表页面集成测试', () {
    testWidgets('服务器列表页面加载并显示服务器', (WidgetTester tester) async {
      // 启动应用，使用mock服务覆盖依赖
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerService>.value(
              value: mockServerService,
            ),
          ],
          child: MaterialApp(
            home: ServerListScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 验证页面标题
      expect(find.text('服务器'), findsOneWidget);
      
      // 验证服务器列表项
      expect(find.text('测试服务器1'), findsOneWidget);
      expect(find.text('测试服务器2'), findsOneWidget);
      
      // 验证添加按钮存在
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
    
    testWidgets('点击添加按钮应导航到编辑页面', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerService>.value(
              value: mockServerService,
            ),
          ],
          child: MaterialApp(
            home: ServerListScreen(),
            routes: {
              '/server/edit': (context) => ServerEditScreen(),
            },
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 点击添加按钮
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();
      
      // 验证导航到编辑页面
      expect(find.byType(ServerEditScreen), findsOneWidget);
      expect(find.text('添加服务器'), findsOneWidget);
    });
    
    testWidgets('点击服务器项应显示操作菜单', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerService>.value(
              value: mockServerService,
            ),
          ],
          child: MaterialApp(
            home: ServerListScreen(),
            routes: {
              '/server/edit': (context) => ServerEditScreen(),
            },
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到第一个服务器项的更多按钮
      final moreIconFinder = find.byIcon(Icons.more_vert).first;
      
      // 点击更多按钮
      await tester.tap(moreIconFinder);
      await tester.pumpAndSettle();
      
      // 验证弹出的菜单项
      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      expect(find.text('测试延迟'), findsOneWidget);
    });
    
    testWidgets('选择编辑菜单项应导航到编辑页面', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerService>.value(
              value: mockServerService,
            ),
          ],
          child: MaterialApp(
            home: ServerListScreen(),
            routes: {
              '/server/edit': (context) => ServerEditScreen(),
            },
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到第一个服务器项的更多按钮
      final moreIconFinder = find.byIcon(Icons.more_vert).first;
      
      // 点击更多按钮
      await tester.tap(moreIconFinder);
      await tester.pumpAndSettle();
      
      // 点击编辑菜单项
      await tester.tap(find.text('编辑'));
      await tester.pumpAndSettle();
      
      // 验证导航到编辑页面
      expect(find.byType(ServerEditScreen), findsOneWidget);
      expect(find.text('编辑服务器'), findsOneWidget);
    });
    
    testWidgets('选择删除菜单项应显示确认对话框', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerService>.value(
              value: mockServerService,
            ),
          ],
          child: MaterialApp(
            home: ServerListScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到第一个服务器项的更多按钮
      final moreIconFinder = find.byIcon(Icons.more_vert).first;
      
      // 点击更多按钮
      await tester.tap(moreIconFinder);
      await tester.pumpAndSettle();
      
      // 点击删除菜单项
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      
      // 验证确认对话框
      expect(find.text('确认删除'), findsOneWidget);
      expect(find.text('你确定要删除这个服务器配置吗？此操作不可撤销。'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    });
    
    testWidgets('确认删除对话框应调用删除方法', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerService>.value(
              value: mockServerService,
            ),
          ],
          child: MaterialApp(
            home: ServerListScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到第一个服务器项的更多按钮
      final moreIconFinder = find.byIcon(Icons.more_vert).first;
      
      // 点击更多按钮
      await tester.tap(moreIconFinder);
      await tester.pumpAndSettle();
      
      // 点击删除菜单项
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      
      // 点击确认删除按钮
      await tester.tap(find.text('删除').last);
      await tester.pumpAndSettle();
      
      // 验证删除方法被调用
      verify(mockServerService.deleteServer(any)).called(1);
    });
    
    testWidgets('点击服务器项应选择该服务器', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerService>.value(
              value: mockServerService,
            ),
          ],
          child: MaterialApp(
            home: ServerListScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到第二个服务器项（不是当前选中的）
      final serverItemFinder = find.text('测试服务器2');
      
      // 点击服务器项
      await tester.tap(serverItemFinder);
      await tester.pumpAndSettle();
      
      // 验证选择方法被调用
      verify(mockServerService.selectServer(2)).called(1);
    });
    
    testWidgets('服务器协议类型应正确显示', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ServerService>.value(
              value: mockServerService,
            ),
          ],
          child: MaterialApp(
            home: ServerListScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 验证协议类型标签
      expect(find.text('VMess'), findsOneWidget);
      expect(find.text('Shadowsocks'), findsOneWidget);
    });
  });
} 