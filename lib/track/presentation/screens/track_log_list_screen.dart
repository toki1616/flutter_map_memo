import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../setting/presentation/providers/setting_storage_provider.dart';
import '../../../setting/presentation/providers/text_scale_provider.dart';
import '../providers/track_provider.dart';

/// 保存済みトラックを選択し、削除または地図表示できる画面。
class TrackLogListScreen extends ConsumerStatefulWidget {
  const TrackLogListScreen({super.key});

  @override
  ConsumerState<TrackLogListScreen> createState() => _TrackLogListScreenState();
}

class _TrackLogListScreenState extends ConsumerState<TrackLogListScreen> {
  bool _isDeleting = false;

  Future<void> _deleteSelected() async {
    final selectedIds = ref.read(trackListSelectionProvider);
    final count = selectedIds.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移動記録を削除'),
        content: Text('$count 件の移動記録を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ids = selectedIds.toList();
    setState(() => _isDeleting = true);
    try {
      final notifier = ref.read(trackListProvider.notifier);
      for (final id in ids) {
        await notifier.deleteTrack(id);
      }
      ref.read(trackListSelectionProvider.notifier).removeIds(ids);
      ref.read(trackMapFilterProvider.notifier).removeDeletedIds(ids);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showSelectedOnMap() {
    final selectedIds = ref.read(trackListSelectionProvider);
    if (selectedIds.isEmpty) return;
    ref.read(trackMapFilterProvider.notifier).showSelected(selectedIds);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(trackListProvider);
    final scale = ref.watch(textScaleProvider).scale;
    final selectedIds = ref.watch(trackListSelectionProvider);
    final selectedCount = selectedIds.length;
    final trackMapFilter = ref.watch(trackMapFilterProvider);
    final displayPeriodLabel =
        ref
            .watch(settingStorageProvider)
            .valueOrNull
            ?.trackDisplayDaysType
            .label ??
        '1週間';

    return Scaffold(
      appBar: AppBar(
        title: const Text('移動記録'),
        actions: [
          IconButton(
            tooltip: '選択を解除',
            onPressed: selectedCount == 0
                ? null
                : ref.read(trackListSelectionProvider.notifier).clear,
            icon: const Icon(Icons.deselect),
          ),
        ],
      ),
      body: tracksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('移動記録の読み込みに失敗しました: $error')),
        data: (tracks) {
          return Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  12 * scale,
                  12 * scale,
                  12 * scale,
                  0,
                ),
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12 * scale),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.filter_alt_outlined),
                            SizedBox(width: 8),
                            Text('地図のトラック表示'),
                          ],
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          trackMapFilter.mode == TrackMapFilterMode.selectedOnly
                              ? '選択した ${trackMapFilter.selectedIds.length}件を表示中'
                              : '設定の表示期間: $displayPeriodLabel',
                        ),
                        if (trackMapFilter.mode ==
                            TrackMapFilterMode.selectedOnly)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                ref
                                    .read(trackMapFilterProvider.notifier)
                                    .showSettingsPeriod();
                                ref
                                    .read(trackListSelectionProvider.notifier)
                                    .clear();
                              },
                              child: const Text('選択を解除して期間設定に戻す'),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: tracks.isEmpty
                    ? const Center(child: Text('保存済みの移動記録はありません'))
                    : ListView.separated(
                        padding: EdgeInsets.fromLTRB(
                          12 * scale,
                          12 * scale,
                          12 * scale,
                          96 * scale,
                        ),
                        itemCount: tracks.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 8 * scale),
                        itemBuilder: (context, index) {
                          final track = tracks[index];
                          final isSelected = selectedIds.contains(track.id);
                          return Card(
                            child: CheckboxListTile(
                              value: isSelected,
                              controlAffinity: ListTileControlAffinity.leading,
                              title: Text(_formatDate(track.startedAt)),
                              subtitle: Text(
                                '${track.points.length} 点  ・  ${track.totalDistanceKm.toStringAsFixed(2)} km'
                                '${track.endedAt == null ? '  ・  記録中' : ''}',
                              ),
                              onChanged: (selected) {
                                ref
                                    .read(trackListSelectionProvider.notifier)
                                    .setSelected(track.id, selected == true);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: selectedCount == 0
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.all(12 * scale),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isDeleting ? null : _deleteSelected,
                        icon: const Icon(Icons.delete_outline),
                        label: Text('$selectedCount 件を削除'),
                      ),
                    ),
                    SizedBox(width: 12 * scale),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isDeleting ? null : _showSelectedOnMap,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('地図に表示'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _formatDate(DateTime value) {
    return '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')} '
        '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
  }
}
