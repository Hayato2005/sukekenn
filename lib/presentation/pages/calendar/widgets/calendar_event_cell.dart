// lib/presentation/pages/calendar/widgets/calendar_event_cell.dart
import 'package:flutter/material.dart';
import 'package:sukekenn/core/models/event.dart'; // パスを修正

class CalendarEventCell extends StatelessWidget {
  final Event event;
  final double fontSizeMultiplier;
  final bool selectionMode;
  final bool isSelected;

  const CalendarEventCell({
    super.key,
    required this.event,
    this.fontSizeMultiplier = 1.0,
    this.selectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 1.0),
      decoration: BoxDecoration(
        color: event.backgroundColor.withOpacity(isSelected ? 0.7 : 1.0), // 選択中は少し薄く
        borderRadius: BorderRadius.circular(4.0),
        border: isSelected ? Border.all(color: Theme.of(context).primaryColor, width: 2) : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      child: Row(
        children: [
          if (selectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Checkbox(
                value: isSelected,
                onChanged: (bool? value) {
                  // 親ウィジェットで onTap をハンドルするので、ここでは何もしないか、setStateを呼び出す
                  // 親の GestureDetector がタップを処理する
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // チェックボックスのタップ範囲を小さく
              ),
            ),
          Expanded(
            child: Text(
              event.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: event.textColor,
                fontSize: 10 * fontSizeMultiplier, // フォントサイズ適用
                fontWeight: event.isFixed ? FontWeight.bold : FontWeight.normal, // 固定予定は太字
              ),
            ),
          ),
          // TODO: ユーザー名表示が必要なら追加 (スペースを考慮)
          // Text(
          //   ' (${event.ownerId})', // 仮
          //   style: TextStyle(
          //     color: event.textColor.withOpacity(0.8),
          //     fontSize: 8 * fontSizeMultiplier,
          //   ),
          // ),
        ],
      ),
    );
  }
}