import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../setting/presentation/providers/text_scale_provider.dart';
import '../providers/pin_provider.dart';

/// ピン追加時に画面下部から表示されるボトムシート
/// タイトル（必須）・メモ（任意）・カラー選択を入力してピンを作成する
class AddPinBottomSheet extends ConsumerStatefulWidget {
  final LatLng position;
  const AddPinBottomSheet({super.key, required this.position});

  @override
  ConsumerState<AddPinBottomSheet> createState() => _AddPinBottomSheetState();
}

class _AddPinBottomSheetState extends ConsumerState<AddPinBottomSheet> {
  final _titleCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();
  String _selectedColor = '#E63946';
  bool _isSaving = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _memoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _isSaving = true);

    try {
      // ピン追加非同期処理の実行
      await ref.read(pinProvider.notifier).addPin(
        position: widget.position,
        title: _titleCtrl.text.trim(),
        memo: _memoCtrl.text.trim(),
        colorHex: _selectedColor,
      );

      // 💡【追加】保存が正常終了したらコンテキストの有効性を確認して画面を閉じる
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      // 💡【追加】エラーが発生した場合はここでぐるぐるを解除し、メッセージを出す
      if (context.mounted) {
        setState(() => _isSaving = false); // ボタンを有効化し、ぐるぐるを止める
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ピンの保存に失敗しました。詳細: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scale = ref.watch(textScaleProvider).scale;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ピンを追加',
            style: textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold, fontSize: 18 * scale),
          ),
          const SizedBox(height: 16),

          // タイトル入力
          TextField(
            controller: _titleCtrl,
            style: textTheme.bodyMedium,
            decoration: const InputDecoration(
              labelText: 'タイトル（必須）',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),

          // メモ入力
          TextField(
            controller: _memoCtrl,
            maxLines: 3,
            style: textTheme.bodyMedium,
            decoration: const InputDecoration(
              labelText: 'メモ（任意）',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),

          // カラー選択ラベル
          Text(
            'カラー',
            style: textTheme.bodyMedium
                ?.copyWith(color: AppTheme.muted, fontSize: 13 * scale),
          ),
          const SizedBox(height: 8),

          // カラーパレット
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AppConstants.pinColors.map((String colorHex) {
              // `?.` を削除して `.` に修正（String? から String へ適合）
              final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
              final selected = _selectedColor == colorHex;
              return GestureDetector(
                onTap: () => setState(() => _selectedColor = colorHex),
                child: Container(
                  width: 32 * scale,
                  height: 32 * scale,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? Colors.black87 : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // 座標表示
          Text(
            '${widget.position.latitude.toStringAsFixed(6)}, '
                '${widget.position.longitude.toStringAsFixed(6)}',
            style: textTheme.bodyMedium
                ?.copyWith(color: AppTheme.muted, fontSize: 11 * scale),
          ),
          const SizedBox(height: 16),

          // ボタン
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('キャンセル', style: textTheme.bodyMedium),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : Text('追加',
                    style: textTheme.labelLarge
                        ?.copyWith(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}