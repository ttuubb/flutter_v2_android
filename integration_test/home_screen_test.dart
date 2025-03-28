import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_v2_android/main.dart' as app;
import 'package:flutter_v2_android/views/home/home_screen.dart';
import 'package:flutter_v2_android/views/servers/server_list_screen.dart';
import 'package:flutter_v2_android/views/settings/settings_screen.dart';
import 'package:flutter_v2_android/views/logs/log_screen.dart';
import 'package:flutter_v2_android/views/subscriptions/subscription_list_screen.dart';
import 'package:flutter_v2_android/widgets/status_card.dart';
import 'package:provider/provider.dart';
import 'package:flutter_v2_android/services/connection/connection_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([ConnectionService])
import 'home_screen_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  late MockConnectionService mockConnectionService;
  
  setUp(() {
    mockConnectionService = MockConnectionService();
    
    // 设置连接服务的默认行为
    when(mockConnectionService.isConnected).thenReturn(false);
    when(mockConnectionService.isConnecting).thenReturn(false);
    when(mockConnectionService.currentServerName).thenReturn('测试服务器');
    when(mockConnectionService.statusStream).thenAnswer(
      (_) => Stream.value(ConnectionStatus.disconnected)
    );
    when(mockConnectionService.trafficStats).thenReturn(
      TrafficStats(uplink: 0, downlink: 0, upTotal: 0, downTotal: 0)
    );
    when(mockConnectionService.connect()).thenAnswer((_) async => true);
    when(mockConnectionService.disconnect()).thenAnswer((_) async => true);
  });
  
  group('主页面集成测试', () {
    testWidgets('主页面加载并显示正确的初始状态', (WidgetTester tester) async {
      // 启动应用，使用mock服务覆盖依赖
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectionService>.value(
              value: mockConnectionService,
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 验证页面标题
      expect(find.text('V2Ray'), findsOneWidget);
      
      // 验证连接状态卡片
      expect(find.byType(StatusCard), findsOneWidget);
      expect(find.text('未连接'), findsOneWidget);
      
      // 验证连接按钮存在
      expect(find.byIcon(Icons.power_settings_new), findsOneWidget);
      
      // 验证底部导航栏
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.list), findsOneWidget);
      expect(find.byIcon(Icons.subscriptions), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });
    
    testWidgets('点击连接按钮应调用连接服务', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectionService>.value(
              value: mockConnectionService,
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 点击连接按钮
      await tester.tap(find.byIcon(Icons.power_settings_new));
      await tester.pumpAndSettle();
      
      // 验证连接方法被调用
      verify(mockConnectionService.connect()).called(1);
    });
    
    testWidgets('已连接状态下应显示断开连接按钮', (WidgetTester tester) async {
      // 设置连接状态为已连接
      when(mockConnectionService.isConnected).thenReturn(true);
      when(mockConnectionService.statusStream).thenAnswer(
        (_) => Stream.value(ConnectionStatus.connected)
      );
      
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectionService>.value(
              value: mockConnectionService,
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 验证状态卡片显示已连接
      expect(find.text('已连接'), findsOneWidget);
      
      // 点击断开连接按钮
      await tester.tap(find.byIcon(Icons.power_settings_new));
      await tester.pumpAndSettle();
      
      // 验证断开连接方法被调用
      verify(mockConnectionService.disconnect()).called(1);
    });
    
    testWidgets('底部导航栏测试 - 服务器列表', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectionService>.value(
              value: mockConnectionService,
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
            routes: {
              '/servers': (context) => ServerListScreen(),
              '/settings': (context) => SettingsScreen(),
              '/logs': (context) => LogScreen(),
              '/subscriptions': (context) => SubscriptionListScreen(),
            },
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 点击服务器导航项
      await tester.tap(find.byIcon(Icons.list));
      await tester.pumpAndSettle();
      
      // 验证导航到服务器列表页面
      expect(find.byType(ServerListScreen), findsOneWidget);
    });
    
    testWidgets('底部导航栏测试 - 订阅列表', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectionService>.value(
              value: mockConnectionService,
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
            routes: {
              '/servers': (context) => ServerListScreen(),
              '/settings': (context) => SettingsScreen(),
              '/logs': (context) => LogScreen(),
              '/subscriptions': (context) => SubscriptionListScreen(),
            },
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 点击订阅导航项
      await tester.tap(find.byIcon(Icons.subscriptions));
      await tester.pumpAndSettle();
      
      // 验证导航到订阅列表页面
      expect(find.byType(SubscriptionListScreen), findsOneWidget);
    });
    
    testWidgets('底部导航栏测试 - 设置页面', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectionService>.value(
              value: mockConnectionService,
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
            routes: {
              '/servers': (context) => ServerListScreen(),
              '/settings': (context) => SettingsScreen(),
              '/logs': (context) => LogScreen(),
              '/subscriptions': (context) => SubscriptionListScreen(),
            },
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 点击设置导航项
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      
      // 验证导航到设置页面
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
    
    testWidgets('底部导航栏测试 - 日志页面', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectionService>.value(
              value: mockConnectionService,
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
            routes: {
              '/servers': (context) => ServerListScreen(),
              '/settings': (context) => SettingsScreen(),
              '/logs': (context) => LogScreen(),
              '/subscriptions': (context) => SubscriptionListScreen(),
            },
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 点击日志导航项
      await tester.tap(find.byIcon(Icons.info));
      await tester.pumpAndSettle();
      
      // 验证导航到日志页面
      expect(find.byType(LogScreen), findsOneWidget);
    });
    
    testWidgets('流量统计显示测试', (WidgetTester tester) async {
      // 设置模拟流量统计数据
      when(mockConnectionService.trafficStats).thenReturn(
        TrafficStats(uplink: 1024, downlink: 2048, upTotal: 10240, downTotal: 20480)
      );
      
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ConnectionService>.value(
              value: mockConnectionService,
            ),
          ],
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 验证流量统计显示
      expect(find.textContaining('上行'), findsOneWidget);
      expect(find.textContaining('下行'), findsOneWidget);
    });
  });
} 