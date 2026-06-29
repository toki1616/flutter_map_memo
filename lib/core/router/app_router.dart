import 'package:go_router/go_router.dart';
import '../../map/presentation/screens/map_screen.dart';

// GoRouterを使用したアプリの画面遷移を定義するファイル
// 設定ボタンや画面の下部ナビゲーションバーをすべて削除し、起動時に直接マップ画面だけを表示するようにルーティングを一本化
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const MapScreen(),
    ),
  ],
);