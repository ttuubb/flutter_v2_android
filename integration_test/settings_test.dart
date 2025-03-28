import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_v2_android/views/settings/settings_screen.dart';
import 'package:flutter_v2_android/models/settings/app_settings.dart';
import 'package:flutter_v2_android/services/settings/settings_service.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([SettingsService])
import 'settings_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  late MockSettingsService mockSettingsService;
  
  // 测试设置
  final testSettings = AppSettings(
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
  
  setUp(() {
    mockSettingsService = MockSettingsService();
    
    // 设置模拟行为
    when(mockSettingsService.settings).thenReturn(testSettings);
    when(mockSettingsService.getSettings()).thenAnswer((_) async => testSettings);
    when(mockSettingsService.saveSettings(any)).thenAnswer((_) async => true);
    when(mockSettingsService.settingsStream).thenAnswer(
      (_) => Stream.value(testSettings)
    );
  });
  
  group('设置页面集成测试', () {
    testWidgets('设置页面加载并显示各设置项', (WidgetTester tester) async {
      // 启动应用，使用mock服务覆盖依赖
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService,
            ),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 验证页面标题
      expect(find.text('设置'), findsOneWidget);
      
      // 验证各设置分类
      expect(find.text('基本设置'), findsOneWidget);
      expect(find.text('代理设置'), findsOneWidget);
      expect(find.text('日志设置'), findsOneWidget);
      
      // 验证各设置项
      expect(find.text('应用主题'), findsOneWidget);
      expect(find.text('语言'), findsOneWidget);
      expect(find.text('DNS服务器'), findsOneWidget);
      expect(find.text('绕过中国大陆地址'), findsOneWidget);
      expect(find.text('绕过局域网地址'), findsOneWidget);
      expect(find.text('启用流量探测'), findsOneWidget);
      expect(find.text('MTU值'), findsOneWidget);
      expect(find.text('Socks端口'), findsOneWidget);
      expect(find.text('HTTP端口'), findsOneWidget);
      expect(find.text('日志级别'), findsOneWidget);
      expect(find.text('保存日志到文件'), findsOneWidget);
    });
    
    testWidgets('主题设置应能正确切换', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService,
            ),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到主题设置项
      final themeSettingFinder = find.text('应用主题');
      expect(themeSettingFinder, findsOneWidget);
      
      // 点击主题设置项
      await tester.tap(themeSettingFinder);
      await tester.pumpAndSettle();
      
      // 验证弹出的选择对话框
      expect(find.text('选择主题'), findsOneWidget);
      expect(find.text('深色'), findsOneWidget);
      expect(find.text('浅色'), findsOneWidget);
      expect(find.text('跟随系统'), findsOneWidget);
      
      // 选择浅色主题
      await tester.tap(find.text('浅色'));
      await tester.pumpAndSettle();
      
      // 验证设置被保存
      verify(mockSettingsService.saveSettings(any)).called(1);
    });
    
    testWidgets('语言设置应能正确切换', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService,
            ),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到语言设置项
      final languageSettingFinder = find.text('语言');
      expect(languageSettingFinder, findsOneWidget);
      
      // 点击语言设置项
      await tester.tap(languageSettingFinder);
      await tester.pumpAndSettle();
      
      // 验证弹出的选择对话框
      expect(find.text('选择语言'), findsOneWidget);
      expect(find.text('简体中文'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      
      // 选择英文
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      
      // 验证设置被保存
      verify(mockSettingsService.saveSettings(any)).called(1);
    });
    
    testWidgets('DNS服务器设置应能打开编辑对话框', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService,
            ),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到DNS服务器设置项
      final dnsSettingFinder = find.text('DNS服务器');
      expect(dnsSettingFinder, findsOneWidget);
      
      // 点击DNS服务器设置项
      await tester.tap(dnsSettingFinder);
      await tester.pumpAndSettle();
      
      // 验证弹出的编辑对话框
      expect(find.text('设置DNS服务器'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('8.8.8.8, 1.1.1.1'), findsOneWidget);
      
      // 修改DNS服务器
      await tester.enterText(find.byType(TextField), '8.8.8.8, 114.114.114.114');
      
      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      
      // 验证设置被保存
      verify(mockSettingsService.saveSettings(any)).called(1);
    });
    
    testWidgets('绕过中国大陆地址开关应能正确切换', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService,
            ),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到绕过中国大陆地址开关
      final bypassMainlandFinder = find.ancestor(
        of: find.text('绕过中国大陆地址'),
        matching: find.byType(Row),
      );
      expect(bypassMainlandFinder, findsOneWidget);
      
      // 找到开关
      final switchFinder = find.descendant(
        of: bypassMainlandFinder,
        matching: find.byType(Switch),
      );
      
      // 点击开关
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      
      // 验证设置被保存
      verify(mockSettingsService.saveSettings(any)).called(1);
    });
    
    testWidgets('绕过局域网地址开关应能正确切换', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService,
            ),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到绕过局域网地址开关
      final bypassPrivateFinder = find.ancestor(
        of: find.text('绕过局域网地址'),
        matching: find.byType(Row),
      );
      expect(bypassPrivateFinder, findsOneWidget);
      
      // 找到开关
      final switchFinder = find.descendant(
        of: bypassPrivateFinder,
        matching: find.byType(Switch),
      );
      
      // 点击开关
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      
      // 验证设置被保存
      verify(mockSettingsService.saveSettings(any)).called(1);
    });
    
    testWidgets('端口设置应能打开编辑对话框', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService,
            ),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到Socks端口设置项
      final socksPortFinder = find.text('Socks端口');
      expect(socksPortFinder, findsOneWidget);
      
      // 点击Socks端口设置项
      await tester.tap(socksPortFinder);
      await tester.pumpAndSettle();
      
      // 验证弹出的编辑对话框
      expect(find.text('设置Socks端口'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      
      // 修改端口
      await tester.enterText(find.byType(TextField), '1088');
      
      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      
      // 验证设置被保存
      verify(mockSettingsService.saveSettings(any)).called(1);
    });
    
    testWidgets('日志级别设置应能正确切换', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService,
            ),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到日志级别设置项
      final logLevelFinder = find.text('日志级别');
      expect(logLevelFinder, findsOneWidget);
      
      // 点击日志级别设置项
      await tester.tap(logLevelFinder);
      await tester.pumpAndSettle();
      
      // 验证弹出的选择对话框
      expect(find.text('选择日志级别'), findsOneWidget);
      expect(find.text('调试'), findsOneWidget);
      expect(find.text('信息'), findsOneWidget);
      expect(find.text('警告'), findsOneWidget);
      expect(find.text('错误'), findsOneWidget);
      
      // 选择调试级别
      await tester.tap(find.text('调试'));
      await tester.pumpAndSettle();
      
      // 验证设置被保存
      verify(mockSettingsService.saveSettings(any)).called(1);
    });
    
    testWidgets('保存日志到文件开关应能正确切换', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService,
            ),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到保存日志到文件开关
      final saveLogFinder = find.ancestor(
        of: find.text('保存日志到文件'),
        matching: find.byType(Row),
      );
      expect(saveLogFinder, findsOneWidget);
      
      // 找到开关
      final switchFinder = find.descendant(
        of: saveLogFinder,
        matching: find.byType(Switch),
      );
      
      // 点击开关
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();
      
      // 验证设置被保存
      verify(mockSettingsService.saveSettings(any)).called(1);
    });
    
    testWidgets('MTU值设置应能打开编辑对话框', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsService>.value(
              value: mockSettingsService,
            ),
          ],
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      
      // 等待所有异步操作完成
      await tester.pumpAndSettle();
      
      // 找到MTU值设置项
      final mtuFinder = find.text('MTU值');
      expect(mtuFinder, findsOneWidget);
      
      // 点击MTU值设置项
      await tester.tap(mtuFinder);
      await tester.pumpAndSettle();
      
      // 验证弹出的编辑对话框
      expect(find.text('设置MTU值'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      
      // 修改MTU值
      await tester.enterText(find.byType(TextField), '1450');
      
      // 点击保存按钮
      await tester.tap(find.text('保存'));
      await tester.pumpAndSettle();
      
      // 验证设置被保存
      verify(mockSettingsService.saveSettings(any)).called(1);
    });
  });
} 