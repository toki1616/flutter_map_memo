import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../map/presentation/screens/map_screen.dart';
import '../../setting/presentation/providers/setting_storage_provider.dart';
import '../../setting/presentation/screens/setting_screen.dart';
import '../presentation/screens/splash_screen.dart';

// GoRouterのインスタンスをRiverpodのProviderとして定義・一元管理するファイル
// _RouterRefreshNotifierクラスにRefを渡すことで、ルーターの初期化中であっても安全にストレージのロード完了を監視可能に
// 起動時はSplashScreen（/splash）で待機し、設定データの非同期読み込みが完了した瞬間にメイン画面（/）へ安全に自動リダイレクトする設計
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',

    // ➔ RiverpodのRefを渡して、状態変化を安全に購読する
    refreshListenable: _RouterRefreshNotifier(ref),

    redirect: (context, state) {
      final container = ProviderScope.containerOf(context);
      final settingStorage = container.read(settingStorageProvider);

      // まだデータの読み込みが終わっていない（AsyncLoadingなど）場合
      if (settingStorage.valueOrNull == null) {
        return '/splash';
      }

      // データのロードが完了しており、かつ現在スプラッシュ画面にいる場合
      if (state.uri.toString() == '/splash') {
        return '/';
      }

      // 通常の画面遷移時はそのまま進む
      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
});

// Riverpodの非同期プロバイダーの完了イベントをGoRouterが購読できるChangeNotifier形式に変換する内部クラス
class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    // ➔ appRouter変数を直接触るのではなく、Refを使って安全にストレージの状態を監視
    // 設定ファイルの読み込みが完了（LoadingからDataに遷移）した瞬間に、ルーターへ通知（notifyListeners）を送る
    ref.listen(settingStorageProvider, (_, __) {
      notifyListeners();
    });
  }
}

class _AppShell extends StatelessWidget {
  final Widget child;
  const _AppShell({required this.child});

  @override
  Widget build(BuildContext context) {
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