import 'package:flutter/material.dart';

// アプリ起動時に必要な初期設定やファイル（settings.json）の読み込みが完了するまで表示するアプリ共通のスプラッシュ画面UIファイル
// どの特定の機能（Feature）にも属さないアプリ全体の起動状態を管理するため、core（共通基盤）レイヤーに配置
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'アプリを準備中...',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}