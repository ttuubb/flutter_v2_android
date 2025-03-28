import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_v2_android/views/subscriptions/subscription_list_screen.dart';
import 'package:flutter_v2_android/views/subscriptions/subscription_edit_screen.dart';
import 'package:flutter_v2_android/models/sub/subscription.dart';
import 'package:flutter_v2_android/services/sub/subscription_service.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([SubscriptionService])
import 'subscription_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  late MockSubscriptionService mockSubscriptionService;
  
  // 测试订阅列表
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
  
  setUp(() {
    mockSubscriptionService = MockSubscriptionService();
    
    // 设置模拟行为
    when(mockSubscriptionService.getSubscriptions()).thenAnswer((_) async => List.from(testSubscriptions));
    when(mockSubscriptionService.getSubscription(1)).thenAnswer((_) async => testSubscriptions[0]);
    when(mockSubscriptionService.getSubscription(2)).thenAnswer((_) async => testSubscriptions[1]);
    when(mockSubscriptionService.addSubscription(any)).thenAnswer((_) async => true);
    when(mockSubscriptionService.updateSubscription(any)).thenAnswer((_) async => true);
    when(mockSubscriptionService.deleteSubscription(any)).thenAnswer((_) async => true);
    when(mockSubscriptionService.updateSubscriptionContent(any)).thenAnswer((_) async => true);
  });
  
  group('订阅管理页面集成测试', () {
    testWidgets('订阅列表页面加载并显示订阅', (WidgetTester tester) async {
      // 启动应用，使用mock服务覆盖依赖
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionService>.value(
              value: mockSubscriptionService,
            ),
          ],
          child: MaterialApp(
            home: SubscriptionListScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 验证页面标题
      expect(find.text('订阅管理'), findsOneWidget);
      
      // 验证订阅列表项
      expect(find.text('测试订阅1'), findsOneWidget);
      expect(find.text('测试订阅2'), findsOneWidget);
      
      // 验证添加按钮存在
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
    
    testWidgets('点击添加按钮应导航到编辑页面', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionService>.value(
              value: mockSubscriptionService,
            ),
          ],
          child: MaterialApp(
            home: SubscriptionListScreen(),
            routes: {
              '/subscription/edit': (context) => SubscriptionEditScreen(),
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
      expect(find.byType(SubscriptionEditScreen), findsOneWidget);
      expect(find.text('添加订阅'), findsOneWidget);
    });
    
    testWidgets('点击订阅项应显示操作菜单', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionService>.value(
              value: mockSubscriptionService,
            ),
          ],
          child: MaterialApp(
            home: SubscriptionListScreen(),
            routes: {
              '/subscription/edit': (context) => SubscriptionEditScreen(),
            },
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到第一个订阅项的更多按钮
      final moreIconFinder = find.byIcon(Icons.more_vert).first;
      
      // 点击更多按钮
      await tester.tap(moreIconFinder);
      await tester.pumpAndSettle();
      
      // 验证弹出的菜单项
      expect(find.text('编辑'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
      expect(find.text('更新'), findsOneWidget);
    });
    
    testWidgets('选择编辑菜单项应导航到编辑页面', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionService>.value(
              value: mockSubscriptionService,
            ),
          ],
          child: MaterialApp(
            home: SubscriptionListScreen(),
            routes: {
              '/subscription/edit': (context) => SubscriptionEditScreen(),
            },
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到第一个订阅项的更多按钮
      final moreIconFinder = find.byIcon(Icons.more_vert).first;
      
      // 点击更多按钮
      await tester.tap(moreIconFinder);
      await tester.pumpAndSettle();
      
      // 点击编辑菜单项
      await tester.tap(find.text('编辑'));
      await tester.pumpAndSettle();
      
      // 验证导航到编辑页面
      expect(find.byType(SubscriptionEditScreen), findsOneWidget);
      expect(find.text('编辑订阅'), findsOneWidget);
    });
    
    testWidgets('选择删除菜单项应显示确认对话框', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionService>.value(
              value: mockSubscriptionService,
            ),
          ],
          child: MaterialApp(
            home: SubscriptionListScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到第一个订阅项的更多按钮
      final moreIconFinder = find.byIcon(Icons.more_vert).first;
      
      // 点击更多按钮
      await tester.tap(moreIconFinder);
      await tester.pumpAndSettle();
      
      // 点击删除菜单项
      await tester.tap(find.text('删除'));
      await tester.pumpAndSettle();
      
      // 验证确认对话框
      expect(find.text('确认删除'), findsOneWidget);
      expect(find.text('你确定要删除这个订阅吗？此操作将同时删除该订阅下的所有服务器。'), findsOneWidget);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('删除'), findsOneWidget);
    });
    
    testWidgets('确认删除对话框应调用删除方法', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionService>.value(
              value: mockSubscriptionService,
            ),
          ],
          child: MaterialApp(
            home: SubscriptionListScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到第一个订阅项的更多按钮
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
      verify(mockSubscriptionService.deleteSubscription(any)).called(1);
    });
    
    testWidgets('选择更新菜单项应调用更新方法', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionService>.value(
              value: mockSubscriptionService,
            ),
          ],
          child: MaterialApp(
            home: SubscriptionListScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到第一个订阅项的更多按钮
      final moreIconFinder = find.byIcon(Icons.more_vert).first;
      
      // 点击更多按钮
      await tester.tap(moreIconFinder);
      await tester.pumpAndSettle();
      
      // 点击更新菜单项
      await tester.tap(find.text('更新'));
      await tester.pumpAndSettle();
      
      // 验证更新方法被调用
      verify(mockSubscriptionService.updateSubscriptionContent(any)).called(1);
    });
    
    testWidgets('订阅编辑页面应正确显示表单', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionService>.value(
              value: mockSubscriptionService,
            ),
          ],
          child: MaterialApp(
            home: SubscriptionEditScreen(subscription: null),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 验证表单字段
      expect(find.text('名称'), findsOneWidget);
      expect(find.text('订阅链接'), findsOneWidget);
      expect(find.text('自动更新'), findsOneWidget);
      expect(find.text('更新间隔'), findsOneWidget);
      
      // 验证保存按钮
      expect(find.text('保存'), findsOneWidget);
    });
    
    testWidgets('订阅编辑页面提交应调用添加方法', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionService>.value(
              value: mockSubscriptionService,
            ),
          ],
          child: MaterialApp(
            home: SubscriptionEditScreen(subscription: null),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 填写表单
      await tester.enterText(find.byType(TextFormField).at(0), '新订阅');
      await tester.enterText(find.byType(TextFormField).at(1), 'https://new.example.com/sub');
      
      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      
      // 验证添加方法被调用
      verify(mockSubscriptionService.addSubscription(any)).called(1);
    });
    
    testWidgets('编辑现有订阅应调用更新方法', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionService>.value(
              value: mockSubscriptionService,
            ),
          ],
          child: MaterialApp(
            home: SubscriptionEditScreen(subscription: testSubscriptions[0]),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 修改表单
      await tester.enterText(find.byType(TextFormField).at(0), '修改后的订阅');
      
      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      
      // 验证更新方法被调用
      verify(mockSubscriptionService.updateSubscription(any)).called(1);
    });
    
    testWidgets('应显示订阅的最后更新时间', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionService>.value(
              value: mockSubscriptionService,
            ),
          ],
          child: MaterialApp(
            home: SubscriptionListScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 验证最后更新时间
      expect(find.textContaining('最近更新:'), findsWidgets);
    });
    
    testWidgets('应显示自动更新状态', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SubscriptionService>.value(
              value: mockSubscriptionService,
            ),
          ],
          child: MaterialApp(
            home: SubscriptionListScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 验证自动更新状态
      expect(find.text('自动'), findsOneWidget);
      expect(find.text('手动'), findsOneWidget);
    });
  });
} 