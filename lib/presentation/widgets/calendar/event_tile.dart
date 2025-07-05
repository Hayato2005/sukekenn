// lib/presentation/widgets/calendar/event_tile.dart

import 'package:flutter/material.dart';
import 'package:sukekenn/models/schedule_model.dart';

class EventTile extends StatelessWidget {
  final Schedule schedule;
  final bool isSelected;
  final bool isDragging;
  final Function(Schedule) onTap;
  final Function(LongPressStartDetails) onLongPressStart;
  final Function(LongPressMoveUpdateDetails) onLongPressMoveUpdate;
  final Function(LongPressEndDetails) onLongPressEnd;

  const EventTile({
    super.key,
    required this.schedule,
    required this.isSelected,
    required this.isDragging,
    required this.onTap,
    required this.onLongPressStart,
    required this.onLongPressMoveUpdate,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    // 仮スケジュールは別のウィジェットで扱うため、ここでは考慮しない
    if (schedule.id.startsWith('temporary')) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => onTap(schedule),
      onLongPressStart: onLongPressStart,
      onLongPressMoveUpdate: onLongPressMoveUpdate,
      onLongPressEnd: onLongPressEnd,
      child: Opacity(
        opacity: isDragging ? 0.0 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(right: 2.0),
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: schedule.color.withOpacity(isSelected ? 0.6 : 1.0),
            borderRadius: BorderRadius.circular(4),
            border: isSelected ? Border.all(color: Colors.blue.shade700, width: 2) : null,
          ),
          child: Text(
            schedule.title,
            style: TextStyle(
              fontSize: 12,
              color: schedule.color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ),
    );
  }
}