// lib/presentation/widgets/calendar/event_tile.dart

import 'package:flutter/material.dart';
import 'package:sukekenn/models/schedule_model.dart';

class EventTile extends StatelessWidget {
  final Schedule schedule;
  final bool isSelected;
  final Function(Schedule) onTap;

  const EventTile({
    super.key,
    required this.schedule,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // タップイベントは親のGestureDetectorで処理されるため、
    // ここでも個別にGestureDetectorを設けておく
    return GestureDetector(
      onTap: () => onTap(schedule),
      child: Container(
        margin: const EdgeInsets.only(right: 2.0),
        padding: const EdgeInsets.all(4.0),
        decoration: BoxDecoration(
          color: schedule.color,
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
    );
  }
}