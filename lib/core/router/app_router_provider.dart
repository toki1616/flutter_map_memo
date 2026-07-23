import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../folder/presentation/providers/folder_provider.dart';
import '../../map/presentation/providers/map_camera_provider.dart';
import '../../map/presentation/providers/map_selection_provider.dart';
import '../../map/presentation/providers/map_url_source_provider.dart';
import '../../map/presentation/screens/map_screen.dart';
import '../../setting/presentation/providers/setting_storage_provider.dart';
import '../../setting/presentation/screens/setting_screen.dart';
import '../../track/presentation/screens/track_log_list_screen.dart';
import '../presentation/screens/splash_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final container = ProviderScope.containerOf(context);

      print('=== [GoRouter Redirect Check] 開始 ===');
      final settingStorage = container.read(settingStorageProvider);
      final mapUrlSource = container.read(mapUrlSourceProvider);
      final mapCamera = container.read(mapCameraProvider);
      final currentUrlMap = container.read(mapSelectionProvider);

      print(
        '  - settingStorage 状態: ${settingStorage.runtimeType} (hasValue: ${settingStorage.hasValue})',
      );
      print(
        '  - mapUrlSource 状態: ${mapUrlSource.runtimeType} (hasValue: ${mapUrlSource.hasValue})',
      );
      print('  - mapCamera 状態: ${mapCamera.runtimeType}');
      print('  - mapSelection (currentUrlMap) 状態: $currentUrlMap');

      if (settingStorage.valueOrNull == null ||
          mapUrlSource.valueOrNull == null ||
          currentUrlMap == null) {
        print('  => 必須データまたはマップ選択の初期化が未完了のため [/splash] に留まります');
        print('=== [GoRouter Redirect Check] 終了 ===');
        return '/splash';
      }

      if (state.uri.toString() == '/splash') {
        print('  => マップ選択まで全データロード完了！ [/] (メイン画面) へ遷移します');
        print('=== [GoRouter Redirect Check] 終了 ===');
        return '/';
      }

      print('  => 通常遷移のためリダイレクトなし');
      print('=== [GoRouter Redirect Check] 終了 ===');
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
          GoRoute(path: '/', builder: (context, state) => const MapScreen()),
          GoRoute(
            path: '/setting',
            builder: (context, state) => const SettingScreen(),
          ),
          GoRoute(
            path: '/track-logs',
            builder: (context, state) => const TrackLogListScreen(),
          ),
        ],
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(settingStorageProvider, (prev, next) {
      print('[RouterListen] settingStorageProvider が更新されました');
      notifyListeners();
    });
    ref.listen(mapCameraProvider, (prev, next) {
      print('[RouterListen] mapCameraProvider が更新されました');
      notifyListeners();
    });
    ref.listen(mapUrlSourceProvider, (prev, next) {
      print('[RouterListen] mapUrlSourceProvider が更新されました');
      notifyListeners();
    });
    // マップ選択の状態が変わった（null から初期マップがセットされた）瞬間も検知してルーターを再評価する
    ref.listen(mapSelectionProvider, (prev, next) {
      print('[RouterListen] mapSelectionProvider (選択マップ) が更新されました: $next');
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
        selectedIndex: switch (location) {
          '/setting' => 1,
          '/track-logs' => 2,
          _ => 0,
        },
        onDestinationSelected: (i) {
          if (i == 0) context.go('/');
          if (i == 1) context.go('/setting');
          if (i == 2) context.go('/track-logs');
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
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route),
            label: '記録',
          ),
        ],
      ),
    );
  }
}
