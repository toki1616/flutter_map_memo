import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'map/data/datasources/map_tile_cache_service.dart';

/// アプリ全体の起動処理と初期設定を行うエントリーポイントファイル
/// アプリ起動時にマップタイルのキャッシュデータベースを初期化し、Riverpodの有効化、共通のルーターやテーマの適用を一括して行う
void main() async {
  // Flutterのフレームワークとネイティブ側のバインディングを確実に行います
  WidgetsFlutterBinding.ensureInitialized();

  // マップタイルのキャッシュサービスを初期化します
  await MapTileCacheService.initialize();

  runApp(
    // Riverpodの状態管理をアプリ全体で有効にするためのスコープを設定します
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GoRouterとAppThemeを組み込んでMaterialAppを生成します
    return MaterialApp.router(
      title: 'フィールドマップアプリ',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system, // 端末の設定に合わせて自動でライト・ダークを切り替えます
      routerConfig: appRouter,      // 共通のルーティング設定を適用します
    );
  }
}