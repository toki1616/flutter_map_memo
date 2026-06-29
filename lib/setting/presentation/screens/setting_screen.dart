import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/text_scale_config.dart';
import '../providers/text_scale_provider.dart';

// 設定ボタンから遷移した後に表示される設定画面のUIファイル
// 地図選択と同様のドロップダウンメニュー（DropdownButton）を採用し、選択肢の文字サイズもアプリ全体の倍率に合わせて動的に拡大・縮小する構造を適用
class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScaleType = ref.watch(textScaleProvider);
    // 現在の拡大倍率が適用されているテキストテーマを取得
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: ListTile(
              title: Text(
                '表示サイズ',
                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '文字やボタンの一括拡大倍率',
                style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
              ),
              // 倍率に応じてドロップダウン自体のサイズや文字サイズを動的に変更
              trailing: DropdownButton<TextScaleType>(
                value: currentScaleType,
                dropdownColor: Theme.of(context).colorScheme.surface,
                // ボタンを閉じた状態のテキストスタイルを現在の倍率に合わせる
                style: textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
                underline: const SizedBox(),
                items: TextScaleType.values.map((type) {
                  return DropdownMenuItem<TextScaleType>(
                    value: type,
                    child: Text(
                      type.label,
                      // ドロップダウンを開いたリスト内の文字サイズも倍率に追従させる
                      style: textTheme.bodyMedium,
                    ),
                  );
                }).toList(),
                onChanged: (TextScaleType? newValue) {
                  if (newValue != null) {
                    ref.read(textScaleProvider.notifier).updateScale(newValue);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}