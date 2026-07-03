import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../folder/presentation/providers/folder_provider.dart';
import '../../domain/entities/text_scale_config.dart';
import '../providers/text_scale_provider.dart';

/// 設定画面
/// - 表示サイズ変更（ドロップダウン）
/// - マップフォルダ選択 / 変更 / クリア
class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScaleType = ref.watch(textScaleProvider);
    final folderAsync = ref.watch(folderProvider);
    final textTheme = Theme.of(context).textTheme;
    final scale = ref.watch(textScaleProvider).scale;

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── 表示サイズ ──────────────────────────────────────────────────
          Card(
            child: ListTile(
              title: Text(
                '表示サイズ',
                style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '文字やボタンの一括拡大倍率',
                style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6)),
              ),
              trailing: DropdownButton<TextScaleType>(
                value: currentScaleType,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface),
                underline: const SizedBox(),
                items: TextScaleType.values.map((type) {
                  return DropdownMenuItem<TextScaleType>(
                    value: type,
                    child: Text(type.label, style: textTheme.bodyMedium),
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

          const SizedBox(height: 12),

          // ── マップフォルダ ──────────────────────────────────────────────
          Card(
            child: Padding(
              padding: EdgeInsets.all(16 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'マップフォルダ',
                    style: textTheme.bodyLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '選択フォルダ内の map/ からタイルを読み込み、\n'
                    'save_data/map_data/pin.json にピンを保存します。\n'
                    '選択したパスは settings.json に自動で保存されます。',
                    style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.6)),
                  ),
                  const SizedBox(height: 12),

                  // ── 現在のフォルダ表示 ──
                  folderAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(
                      'エラー: $e',
                      style: textTheme.bodyMedium
                          ?.copyWith(color: AppTheme.danger),
                    ),
                    data: (folder) => folder == null
                        ? Text(
                            '未選択',
                            style: textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.muted),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.folder,
                                      color: AppTheme.primary, size: 18),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      folder.name,
                                      style: textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                folder.path,
                                style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 11 * scale,
                                    color: AppTheme.muted),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'マップ: ${folder.localMapNames.isEmpty ? "なし" : folder.localMapNames.join(", ")}',
                                style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 11 * scale,
                                    color: AppTheme.muted),
                              ),
                            ],
                          ),
                  ),

                  const SizedBox(height: 16),

                  // ── フォルダ選択 / 変更 / クリア ボタン ──
                  folderAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => _PickButton(
                      label: 'フォルダを再選択',
                      onTap: () =>
                          ref.read(folderProvider.notifier).pickFolder(),
                    ),
                    data: (folder) => folder == null
                        // 未選択 → 選択ボタンのみ
                        ? _PickButton(
                            label: 'フォルダを選択',
                            onTap: () =>
                                ref.read(folderProvider.notifier).pickFolder(),
                          )
                        // 選択済み → 変更 + クリア
                        : Row(
                            children: [
                              Expanded(
                                child: _PickButton(
                                  label: 'フォルダを変更',
                                  onTap: () => ref
                                      .read(folderProvider.notifier)
                                      .pickFolder(),
                                ),
                              ),
                              const SizedBox(width: 8),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _confirmClear(context, ref),
                                icon: const Icon(Icons.delete_outline,
                                    color: AppTheme.danger, size: 18),
                                label: const Text('クリア',
                                    style:
                                        TextStyle(color: AppTheme.danger)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                      color: AppTheme.danger),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── フォルダ構造ガイド ───────────────────────────────────────────
          Card(
            child: Padding(
              padding: EdgeInsets.all(14 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'フォルダ構造',
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'root/\n'
                    '  map/\n'
                    '    {マップ名}/{z}/{x}/{y}.png\n'
                    '  save_data/\n'
                    '    map_data/\n'
                    '      pin.json',
                    style: TextStyle(
                      fontSize: 11 * scale,
                      fontFamily: 'monospace',
                      color: AppTheme.muted,
                      height: 1.6,
                    ),
                  ),
                  const Divider(height: 20),
                  Text(
                    'アプリ内保存先',
                    style: textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Documents/\n'
                    '  save_data/\n'
                    '    setting/\n'
                    '      settings.json  ← フォルダパスと設定を保存',
                    style: TextStyle(
                      fontSize: 11 * scale,
                      fontFamily: 'monospace',
                      color: AppTheme.muted,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('フォルダ設定をクリア'),
        content: const Text(
            '選択したフォルダの設定を削除しますか？\n'
            'settings.json からパスが削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除',
                style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(folderProvider.notifier).clear();
    }
  }
}

class _PickButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PickButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.folder_open_outlined),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }
}
