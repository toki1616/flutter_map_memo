import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'map/data/datasources/map_tile_cache_service.dart';
import 'setting/presentation/providers/text_scale_provider.dart';

/// アプリ全体の起動処理と初期設定を行うエントリーポイントファイル
/// アプリ起動時にマップタイルのキャッシュデータベースを初期化し、Riverpodの有効化、共通のルーターやテーマの適用を一括して行う
/// サイズ設定プロバイダーから現在の列挙型データを取得し、その倍率数値をテーマデータに適用してMaterialAppへ動的に反映
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

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 列挙型の状態を監視し、内包されている倍率（scale）を取り出します
    final textScaleType = ref.watch(textScaleProvider);

    return MaterialApp.router(
      title: 'フィールドマップアプリ',
      theme: AppTheme.getLight(textScaleType.scale),
      darkTheme: AppTheme.getDark(textScaleType.scale),
      themeMode: ThemeMode.system,  // 端末の設定に合わせて自動でライト・ダークを切り替えます
      routerConfig: appRouter,      // 共通のルーティング設定を適用します
    );
  }
}