import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../setting/presentation/providers/text_scale_provider.dart';
import '../providers/track_provider.dart';

/// 保存済みトラックを選択し、削除または地図表示できる画面。
class TrackLogListScreen extends ConsumerStatefulWidget {
  const TrackLogListScreen({super.key});

  @override
  ConsumerState<TrackLogListScreen> createState() => _TrackLogListScreenState();
}

class _TrackLogListScreenState extends ConsumerState<TrackLogListScreen> {
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
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

    final ids = _selectedIds.toList();
    setState(() => _isDeleting = true);
    try {
      final notifier = ref.read(trackListProvider.notifier);
      for (final id in ids) {
        await notifier.deleteTrack(id);
      }
      ref.read(trackMapDisplayProvider.notifier).removeIds(ids);
      if (mounted) setState(_selectedIds.clear);
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  void _showSelectedOnMap() {
    if (_selectedIds.isEmpty) return;
    ref.read(trackMapDisplayProvider.notifier).showOnly(_selectedIds);
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final tracksAsync = ref.watch(trackListProvider);
    final scale = ref.watch(textScaleProvider).scale;
    final selectedCount = _selectedIds.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('移動記録'),
        actions: [
          IconButton(
            tooltip: '選択を解除',
            onPressed: selectedCount == 0
                ? null
                : () => setState(_selectedIds.clear),
            icon: const Icon(Icons.deselect),
          ),
        ],
      ),
      body: tracksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('移動記録の読み込みに失敗しました: $error')),
        data: (tracks) {
          if (tracks.isEmpty) {
            return const Center(child: Text('保存済みの移動記録はありません'));
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              12 * scale,
              12 * scale,
              12 * scale,
              96 * scale,
            ),
            itemCount: tracks.length,
            separatorBuilder: (context, index) => SizedBox(height: 8 * scale),
            itemBuilder: (context, index) {
              final track = tracks[index];
              final isSelected = _selectedIds.contains(track.id);
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
                    setState(() {
                      if (selected == true) {
                        _selectedIds.add(track.id);
                      } else {
                        _selectedIds.remove(track.id);
                      }
                    });
                  },
                ),
              );
            },
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
