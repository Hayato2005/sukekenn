// lib/presentation/pages/calendar/widgets/day_timeline_popup.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/core/models/event.dart';
import 'package:sukekenn/presentation/pages/calendar/widgets/event_detail_dialog.dart'; // 詳細ダイアログをインポート

class DayTimelinePopup extends StatefulWidget {
  final DateTime date;
  final List<Event> events;

  const DayTimelinePopup({
    super.key,
    required this.date,
    required this.events,
  });

  @override
  State<DayTimelinePopup> createState() => _DayTimelinePopupState();
}

class _DayTimelinePopupState extends State<DayTimelinePopup> {
  final double initialHourHeight = 60.0;
  final double hourLabelWidth = 50.0;
  ValueNotifier<double> scaleNotifier = ValueNotifier(1.0);

  @override
  void dispose() {
    scaleNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(DateFormat('M月d日(E)', 'ja').format(widget.date)),
      contentPadding: EdgeInsets.zero,
      insetPadding: const EdgeInsets.all(16.0),
      content: Container(
        width: MediaQuery.of(context).size.width,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: ValueListenableBuilder<double>(
          valueListenable: scaleNotifier,
          builder: (context, scale, _) {
            final double currentHourHeight = initialHourHeight * scale;
            return GestureDetector(
              onScaleUpdate: (details) {
                scaleNotifier.value = (scale * details.scale).clamp(0.5, 3.0);
              },
              child: SingleChildScrollView(
                child: SizedBox(
                  height: 24 * currentHourHeight,
                  child: Stack(
                    children: [
                      ..._buildHourLines(currentHourHeight),
                      ..._buildEventBlocks(currentHourHeight),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  List<Widget> _buildHourLines(double hourHeight) {
    return List.generate(24, (hour) {
      return Positioned(
        top: hour * hourHeight,
        left: 0,
        right: 0,
        child: Row(
          children: [
            SizedBox(
              width: hourLabelWidth,
              child: Center(
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  style: TextStyle(fontSize: 12 / scaleNotifier.value),
                ),
              ),
            ),
            Expanded(
              child: Container(height: 1, color: Colors.grey.shade300),
            ),
          ],
        ),
      );
    });
  }

  List<Widget> _buildEventBlocks(double hourHeight) {
    return widget.events.map((event) {
      final top = event.startTime.hour * hourHeight + (event.startTime.minute / 60.0 * hourHeight);
      final height = event.endTime.difference(event.startTime).inMinutes / 60.0 * hourHeight;

      return Positioned(
        top: top,
        left: hourLabelWidth,
        right: 8,
        height: height < 20 ? 20 : height, // 最小高さを保証
        child: GestureDetector(
          onTap: () {
            // 予定ブロックをタップしたら詳細ダイアログを表示
            showDialog(
              context: context,
              builder: (_) => EventDetailDialog(event: event),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(4.0),
            decoration: BoxDecoration(
              color: event.backgroundColor.withOpacity(0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              event.title,
              style: TextStyle(
                color: event.textColor,
                fontSize: 12 / scaleNotifier.value,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );
    }).toList();
  }
}