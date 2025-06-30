// lib/presentation/pages/calendar/widgets/color_picker_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:sukekenn/core/models/event.dart'; // Event.getAdaptiveTextColorのために必要

class ColorPickerBottomSheet extends StatefulWidget {
  final Color initialColor;
  final List<Color>? customColors; // カスタムカラーパレットや履歴

  const ColorPickerBottomSheet({
    super.key,
    required this.initialColor,
    this.customColors,
  });

  @override
  State<ColorPickerBottomSheet> createState() => _ColorPickerBottomSheetState();
}

class _ColorPickerBottomSheetState extends State<ColorPickerBottomSheet> {
  late Color _selectedColor;
  // 仮のプリセットカラー
  final List<Color> _presetColors = [
    Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
    Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
    Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
    Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,
    // デフォルトカラーもプリセットに追加 (Event.EventTypeExtensionから取得することも可能)
    const Color(0xFFCFB53B), // フレンド
    const Color(0xFF004080), // 誰でも
    const Color(0xFFAA2455), // 異性
    Colors.purple.shade300,  // マイグループ
    Colors.grey.shade400,    // 固定予定
  ];

  List<Color> _colorHistory = []; // 選択履歴

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    // TODO: ここでFirestoreなどから履歴をロードし、_colorHistoryにセット
    _colorHistory = widget.customColors ?? [];
    // 初期カラーがプリセットや履歴になければ履歴に追加
    if (!_presetColors.contains(_selectedColor) && !_colorHistory.contains(_selectedColor)) {
      _colorHistory.insert(0, _selectedColor);
      if (_colorHistory.length > 10) _colorHistory.removeLast(); // 履歴の上限
    }
  }

  void _onColorSelected(Color color) {
    setState(() {
      _selectedColor = color;
      if (!_colorHistory.contains(color)) {
        _colorHistory.insert(0, color);
        if (_colorHistory.length > 10) _colorHistory.removeLast();
      }
    });
    // TODO: 履歴をFirestoreに保存
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            '色を選択',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        // 選択履歴
        if (_colorHistory.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(alignment: Alignment.centerLeft, child: Text('最近使った色')),
          ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _colorHistory.length,
              itemBuilder: (context, index) {
                final color = _colorHistory[index];
                return GestureDetector(
                  onTap: () => _onColorSelected(color),
                  child: Container(
                    width: 40,
                    height: 40,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _selectedColor == color ? Theme.of(context).primaryColor : Colors.grey.shade300,
                        width: _selectedColor == color ? 3 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(),
        ],
        // プリセットカラーパレット
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Align(alignment: Alignment.centerLeft, child: Text('カラーパレット')),
        ),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              childAspectRatio: 1.0,
              mainAxisSpacing: 10.0,
              crossAxisSpacing: 10.0,
            ),
            padding: const EdgeInsets.all(16.0),
            itemCount: _presetColors.length,
            itemBuilder: (context, index) {
              final color = _presetColors[index];
              return GestureDetector(
                onTap: () => _onColorSelected(color),
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _selectedColor == color ? Theme.of(context).primaryColor : Colors.grey.shade300,
                      width: _selectedColor == color ? 3 : 1,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, _selectedColor); // 選択した色を返す
            },
            child: const Text('この色に決定'),
          ),
        ),
      ],
    );
  }
}