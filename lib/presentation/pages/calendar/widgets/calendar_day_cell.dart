// lib/presentation/pages/calendar/widgets/calendar_day_cell.dart
import 'package:flutter/material.dart';
import 'package:sukekenn/core/models/event.dart';

class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final List<Event> events;
  final bool isToday;
  final bool isSelected;
  final bool isOutside;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.events,
    this.isToday = false,
    this.isSelected = false,
    this.isOutside = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: isToday ? Colors.blue : Colors.grey.shade300,
          width: isToday ? 1.5 : 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
        color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.3) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4.0, top: 2.0),
            child: Text(
              day.day.toString(),
              style: TextStyle(
                color: isOutside ? Colors.grey.shade400 : (isToday ? Colors.blue : Colors.black),
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          if (events.isNotEmpty)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildEventTag(events.first),
                  if (events.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        '+${events.length - 1}件',
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventTag(Event event) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: event.backgroundColor,
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(
        event.title,
        style: TextStyle(
          color: event.textColor,
          fontSize: 10,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}