import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/theme/app_theme.dart';
import '../../../setting/presentation/providers/text_scale_provider.dart';
import '../../domain/entities/pin_data.dart';
import '../providers/pin_provider.dart';

/// FlutterMap の children に追加するピンマーカーレイヤー
/// タップでピン詳細・編集・削除シートを表示する
class PinMarkerLayer extends ConsumerWidget {
  const PinMarkerLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinsAsync = ref.watch(pinProvider);
    final scale = ref.watch(textScaleProvider).scale;

    return pinsAsync.when(
      loading: () => const MarkerLayer(markers: []),
      error: (_, __) => const MarkerLayer(markers: []),
      data: (pins) => MarkerLayer(
        markers: pins.map((pin) {
          final color =
          Color(int.parse(pin.colorHex.replaceFirst('#', '0xFF')));
          return Marker(
            point: LatLng(pin.latitude, pin.longitude),
            width: 40 * scale,
            height: 40 * scale,
            child: GestureDetector(
              onTap: () => _showDetail(context, ref, pin, scale),
              child: Icon(
                Icons.location_on,
                color: color,
                size: 36 * scale,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref, PinData pin, double scale) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return PinDetailSheet(pin: pin, scale: scale);
      },
    );
  }
}

class PinDetailSheet extends ConsumerStatefulWidget {
  final PinData pin;
  final double scale;

  const PinDetailSheet({
    super.key,
    required this.pin,
    required this.scale,
  });

  @override
  ConsumerState<PinDetailSheet> createState() => _PinDetailSheetState();
}

class _PinDetailSheetState extends ConsumerState<PinDetailSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _memoCtrl;
  bool _isEditing = false;

  // 💡 編集後にボトムシート内の文字を即時反映させるための内部状態
  late String _currentTitle;
  late String _currentMemo;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.pin.title);
    _memoCtrl = TextEditingController(text: widget.pin.memo);

    // 初期値をセット
    _currentTitle = widget.pin.title;
    _currentMemo = widget.pin.memo;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.7,
      expand: false,
      builder: (context, ctrl) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _isEditing
                        ? TextField(
                      controller: _titleCtrl,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18 * widget.scale,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'タイトル',
                        border: OutlineInputBorder(),
                      ),
                    )
                        : Text(
                      _currentTitle.isEmpty ? '無題のピン' : _currentTitle,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18 * widget.scale,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(_isEditing ? Icons.check : Icons.edit),
                    onPressed: () async {
                      if (_isEditing) {
                        final newTitle = _titleCtrl.text.trim();
                        final newMemo = _memoCtrl.text.trim();

                        if (newTitle.isEmpty) return;

                        final updatedPin = widget.pin.copyWith(
                          title: newTitle,
                          memo: newMemo,
                        );

                        // 💡 コントローラーに入力されたテキストをその場で内部状態に反映させて非編集モードに戻す（これで一瞬で画面が切り替わります）
                        setState(() {
                          _currentTitle = newTitle;
                          _currentMemo = newMemo;
                          _isEditing = false;
                        });

                        // 💡 裏側で永続化保存（Riverpodへの通知とファイル書き込み）を非同期実行
                        await ref.read(pinProvider.notifier).updatePin(updatedPin);
                      } else {
                        setState(() {
                          _isEditing = true;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: ctrl,
                padding: const EdgeInsets.all(16),
                child: _isEditing
                    ? TextField(
                  controller: _memoCtrl,
                  maxLines: null,
                  style: textTheme.bodyMedium,
                  decoration: const InputDecoration(
                    labelText: 'メモ',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                )
                    : Text(
                  _currentMemo.isEmpty
                      ? 'メモなし'
                      : _currentMemo,
                  style: _currentMemo.isEmpty
                      ? textTheme.bodyMedium
                      ?.copyWith(color: AppTheme.muted)
                      : textTheme.bodyMedium,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${widget.pin.latitude.toStringAsFixed(6)}, '
                    '${widget.pin.longitude.toStringAsFixed(6)}',
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppTheme.muted, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}