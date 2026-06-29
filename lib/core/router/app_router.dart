import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../map/presentation/screens/map_screen.dart';
import '../../setting/presentation/screens/setting_screen.dart';

// GoRouterを使用したアプリの画面遷移を定義するファイル
// 設定ボタンや画面の下部ナビゲーションバーをすべて削除し、起動時に直接マップ画面だけを表示するようにルーティングを一本化
// ShellRouteを導入して永続的な下部フッターナビゲーション（NavigationBar）を構築し、各画面へのタブ切り替えを効率的に一元管理
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const MapScreen(),
        ),
        GoRoute(
          path: '/setting',
          builder: (context, state) => const SettingScreen(),
        ),
      ],
    ),
  ],
);

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
    // 現在のURI文字列を取得してインデックス判定を行います
    final location = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: location == '/setting' ? 1 : 0,
        onDestinationSelected: (i) {
          if (i == 0) context.go('/');
          if (i == 1) context.go('/setting');
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'マップ',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}