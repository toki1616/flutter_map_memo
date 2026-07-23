import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../folder/presentation/providers/folder_provider.dart';
import '../../domain/entities/orientation_config.dart';
import '../../domain/entities/text_scale_config.dart';
import '../../domain/entities/track_setting_config.dart';
import '../providers/setting_storage_provider.dart';
import '../providers/text_scale_provider.dart';

class SettingScreen extends ConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentScaleType = ref.watch(textScaleProvider);
    final settingAsync = ref.watch(settingStorageProvider);
    final folderAsync = ref.watch(folderProvider);
    final textTheme = Theme.of(context).textTheme;
    final scale = ref.watch(textScaleProvider).scale;
    final settings = settingAsync.valueOrNull;

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
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '文字やボタンの一括拡大倍率',
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              trailing: DropdownButton<TextScaleType>(
                value: currentScaleType,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                underline: const SizedBox(),
                items: TextScaleType.values
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t.label, style: textTheme.bodyMedium),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null)
                    ref.read(textScaleProvider.notifier).updateScale(v);
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── 画面の向き ──────────────────────────────────────────────────
          Card(
            child: Padding(
              padding: EdgeInsets.all(16 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '画面の向き',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '縦画面・横画面・自動回転を切り替えます',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: OrientationType.values.map((type) {
                      final isSelected = settings?.orientationType == type;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: type != OrientationType.landscape
                                ? 6 * scale
                                : 0,
                          ),
                          child: _OrientationButton(
                            type: type,
                            isSelected: isSelected,
                            scale: scale,
                            onTap: () => ref
                                .read(settingStorageProvider.notifier)
                                .saveOrientation(type),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── トラック記録設定 ────────────────────────────────────────────
          Card(
            child: Padding(
              padding: EdgeInsets.all(16 * scale),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '移動記録の設定',
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 保存間隔
                  _SettingRow(
                    label: '保存間隔',
                    subtitle: 'GPSポイントを記録する時間の間隔',
                    child: DropdownButton<TrackIntervalType>(
                      value:
                          settings?.trackIntervalType ??
                          TrackIntervalType.sec10,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      underline: const SizedBox(),
                      items: TrackIntervalType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label, style: textTheme.bodyMedium),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null)
                          ref
                              .read(settingStorageProvider.notifier)
                              .saveTrackInterval(v);
                      },
                    ),
                  ),

                  const Divider(height: 20),

                  // 表示期間
                  _SettingRow(
                    label: 'マップ表示期間',
                    subtitle: 'この期間以内のログをマップに表示する',
                    child: DropdownButton<TrackDisplayDaysType>(
                      value:
                          settings?.trackDisplayDaysType ??
                          TrackDisplayDaysType.week1,
                      dropdownColor: Theme.of(context).colorScheme.surface,
                      style: textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      underline: const SizedBox(),
                      items: TrackDisplayDaysType.values
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label, style: textTheme.bodyMedium),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null)
                          ref
                              .read(settingStorageProvider.notifier)
                              .saveTrackDisplayDays(v);
                      },
                    ),
                  ),
                  /*
                   * 機能: 自動削除までの保存期間をユーザーが選択する UI。
                   * 状態: 保存期間による自動削除を停止中のため、設定 UI は非表示。
                   * 再導入時は SettingStorageNotifier.saveTrackRetentionDays と
                   * TrackListNotifier.deleteOldLogs も有効化する。
                  _SettingRow(
                    label: '保存期間',
                    subtitle: 'この期間より古いログは自動削除される',
                    child: DropdownButton<TrackRetentionDaysType>(
                      value: settings?.trackRetentionDaysType ??
                          TrackRetentionDaysType.month1,
                      items: TrackRetentionDaysType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type.label),
                              ))
                          .toList(),
                      onChanged: (type) {
                        if (type != null) {
                          ref
                              .read(settingStorageProvider.notifier)
                              .saveTrackRetentionDays(type);
                        }
                      },
                    ),
                  ),
                  */
                ],
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
                    style: textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '外部フォルダを選択していない場合はアプリ内に保存します。\n'
                    '選択フォルダ内の map/ からタイルを読み込み、\n'
                    'save_data/map_data/pin.json にピンを保存します。\n'
                    'save_data/map_data/track_log/ に移動記録を保存します。',
                    style: textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  folderAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text(
                      'エラー: $e',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppTheme.danger,
                      ),
                    ),
                    data: (folder) => folder == null
                        ? const SizedBox.shrink()
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    folder.isAppStorage
                                        ? Icons.phone_android
                                        : Icons.folder,
                                    color: AppTheme.primary,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      folder.isAppStorage
                                          ? 'アプリ内ストレージ（外部フォルダ未選択）'
                                          : folder.name,
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
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
                                  color: AppTheme.muted,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 16),
                  folderAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => _PickButton(
                      label: 'フォルダを再選択',
                      onTap: () =>
                          ref.read(folderProvider.notifier).pickFolder(),
                    ),
                    data: (folder) => folder == null || folder.isAppStorage
                        ? _PickButton(
                            label: 'フォルダを選択',
                            onTap: () =>
                                ref.read(folderProvider.notifier).pickFolder(),
                          )
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
                                onPressed: () => _confirmClear(context, ref),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.danger,
                                  size: 18,
                                ),
                                label: const Text(
                                  'クリア',
                                  style: TextStyle(color: AppTheme.danger),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: AppTheme.danger,
                                  ),
                                ),
                              ),
                            ],
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
        content: const Text('選択したフォルダの設定を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除', style: TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    if (ok == true) await ref.read(folderProvider.notifier).clear();
  }
}

// ── 内部ウィジェット ────────────────────────────────────────────────────────

class _SettingRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final Widget child;
  const _SettingRow({
    required this.label,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

class _OrientationButton extends StatelessWidget {
  final OrientationType type;
  final bool isSelected;
  final double scale;
  final VoidCallback onTap;
  const _OrientationButton({
    required this.type,
    required this.isSelected,
    required this.scale,
    required this.onTap,
  });

  IconData get _icon {
    switch (type) {
      case OrientationType.auto:
        return Icons.screen_rotation_outlined;
      case OrientationType.portrait:
        return Icons.stay_current_portrait_outlined;
      case OrientationType.landscape:
        return Icons.stay_current_landscape_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.symmetric(
          vertical: 10 * scale,
          horizontal: 4 * scale,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.shade300,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: 22 * scale,
              color: isSelected ? Colors.white : AppTheme.muted,
            ),
            SizedBox(height: 4 * scale),
            Text(
              type.label,
              style: textTheme.bodyMedium?.copyWith(
                fontSize: 12 * scale,
                color: isSelected ? Colors.white : AppTheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
