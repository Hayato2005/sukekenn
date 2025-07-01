// lib/presentation/pages/calendar/widgets/week_view_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/application/providers/event_provider.dart';
import 'package:sukekenn/core/models/event.dart';

// 週表示の状態を管理するProvider
final weekViewHourHeightProvider = StateProvider<double>((ref) => 60.0);
final weekViewPageControllerProvider =
    Provider.autoDispose((ref) => PageController(initialPage: 5200)); // 約100年分

class WeekViewWidget extends ConsumerWidget {
  const WeekViewWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hourHeight = ref.watch(weekViewHourHeightProvider);
    final pageController = ref.watch(weekViewPageControllerProvider);
    final events = ref.watch(eventsProvider);

    return GestureDetector(
      onScaleUpdate: (details) {
        final notifier = ref.read(weekViewHourHeightProvider.notifier);
        notifier.state = (notifier.state * details.scale).clamp(30.0, 150.0);
      },
      child: PageView.builder(
        controller: pageController,
        itemBuilder: (context, index) {
          final weekOffset = index - 5200;
          final now = DateTime.now();
          final startOfWeek = now
              .subtract(Duration(days: now.weekday % 7))
              .add(Duration(days: weekOffset * 7));
          return _buildSingleWeek(context, startOfWeek, hourHeight, events);
        },
      ),
    );
  }

  Widget _buildSingleWeek(BuildContext context, DateTime startOfWeek,
      double hourHeight, List<Event> allEvents) {
    final weekEvents = allEvents
        .where((e) =>
            e.startTime.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            e.startTime.isBefore(startOfWeek.add(const Duration(days: 7))))
        .toList();

    return Column(
      children: [
        _buildWeekHeader(startOfWeek),
        Expanded(
          child: SingleChildScrollView(
            child: SizedBox(
              height: 24 * hourHeight,
              child: Stack(
                children: [
                  _buildHourLines(hourHeight),
                  _buildDayColumns(startOfWeek, hourHeight),
                  _buildEventBlocks(startOfWeek, hourHeight, weekEvents),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekHeader(DateTime startOfWeek) {
    return Row(
      children: [
        const SizedBox(width: 50), // 時間ラベルのオフセット
        ...List.generate(7, (i) {
          final date = startOfWeek.add(Duration(days: i));
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          return Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                      color: isToday ? Colors.blue : Colors.grey.shade300,
                      width: isToday ? 2 : 1),
                ),
              ),
              child: Column(
                children: [
                  Text(DateFormat('E', 'ja').format(date),
                      style: TextStyle(
                          fontSize: 12,
                          color: isToday ? Colors.blue : Colors.black)),
                  Text(date.day.toString(),
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.normal,
                          color: isToday ? Colors.blue : Colors.black)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHourLines(double hourHeight) {
    return Stack(
      children: List.generate(24, (hour) {
        return Positioned(
          top: hour * hourHeight,
          left: 0,
          right: 0,
          child: Row(
            children: [
              SizedBox(
                width: 50,
                child: Center(
                  child: Text(
                    '${hour.toString().padLeft(2, '0')}:00',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ),
              Expanded(
                child: Container(height: 1, color: Colors.grey.shade200),
              ),
            ],
          ),
        );
      }),
    );
  }
  
  Widget _buildDayColumns(DateTime startOfWeek, double hourHeight) {
    return Row(
      children: [
        const SizedBox(width: 50),
        ...List.generate(7, (i) {
          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey.shade200))
              ),
            ),
          );
        })
      ],
    );
  }

  Widget _buildEventBlocks(
      DateTime startOfWeek, double hourHeight, List<Event> events) {
    return LayoutBuilder(builder: (context, constraints) {
      final weekWidth = constraints.maxWidth - 50;
      return Stack(
        children: events.map((event) {
          final dayIndex = event.startTime.weekday % 7;
          final left = 50 + (weekWidth / 7 * dayIndex);
          final width = weekWidth / 7;

          final top = event.startTime.hour * hourHeight +
              (event.startTime.minute / 60.0 * hourHeight);
          final height = event.endTime.difference(event.startTime).inMinutes /
              60.0 *
              hourHeight;

          return Positioned(
            top: top,
            left: left,
            width: width - 4, // 少し隙間を空ける
            height: height,
            child: Container(
              margin: const EdgeInsets.all(2),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: event.backgroundColor,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                event.title,
                style: TextStyle(color: event.textColor, fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}