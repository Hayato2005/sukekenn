// lib/presentation/widgets/week_calendar_view.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';

class WeekCalendarView extends StatefulWidget {
  final DateTime startOfWeek;
  final List<Schedule> schedules;
  final Function(DateTime) onGridTapped;
  final Function(Schedule) onScheduleTapped;
  final Function(Schedule) onScheduleUpdated;
  final Function(Schedule) onTemporaryScheduleUpdated;
  final bool isSelectionMode;
  final List<String> selectedScheduleIds;
  final VoidCallback? onDragStart;
  final VoidCallback? onDragEnd;


  const WeekCalendarView({
    super.key,
    required this.startOfWeek,
    required this.schedules,
    required this.onGridTapped,
    required this.onScheduleTapped,
    required this.onScheduleUpdated,
    required this.onTemporaryScheduleUpdated,
    required this.isSelectionMode,
    required this.selectedScheduleIds,
    this.onDragStart,
    this.onDragEnd,
  });

  @override
  State<WeekCalendarView> createState() => _WeekCalendarViewState();
}

class _WeekCalendarViewState extends State<WeekCalendarView> {
  final ScrollController _scrollController = ScrollController();
  Timer? _timeIndicatorTimer;
  Timer? _autoScrollTimer;
  final GlobalKey _gridKey = GlobalKey();

  double _hourHeight = 60.0;
  bool _showZoomResetButton = false;

  Schedule? _draggingSchedule;
  Schedule? _ghostSchedule;

  final double _leftColumnWidth = 50.0;

  @override
  void initState() {
    super.initState();
    _timeIndicatorTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !context.mounted) return;
      final now = DateTime.now();
      final initialScrollOffset = now.hour * _hourHeight - (context.size?.height ?? 800) / 3;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(initialScrollOffset.clamp(0.0, _scrollController.position.maxScrollExtent));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timeIndicatorTimer?.cancel();
    _autoScrollTimer?.cancel();
    super.dispose();
  }

  double _getDayColumnWidth(double viewWidth) => (viewWidth - _leftColumnWidth) / 7;
  double _hourToY(double hour) => hour * _hourHeight;

  DateTime? _positionToDateTime(Offset globalPosition) {
    final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null || !gridBox.hasSize) return null;

    final localPosition = gridBox.globalToLocal(globalPosition);

    if (localPosition.dx < 0 || localPosition.dx > gridBox.size.width) return null;
    if (localPosition.dy < 0 || localPosition.dy > gridBox.size.height) return null;

    final viewWidth = gridBox.size.width;
    final dayColumnWidth = _getDayColumnWidth(viewWidth);

    int dayIndex = ((localPosition.dx - _leftColumnWidth) / dayColumnWidth).floor().clamp(0, 6);
    DateTime date = DateUtils.dateOnly(widget.startOfWeek).add(Duration(days: dayIndex));

    double totalMinutes = (localPosition.dy / _hourHeight) * 60;
    int snappedMinutes = (totalMinutes / 15).round() * 15;

    return date.add(Duration(minutes: snappedMinutes));
  }

  void _handleAutoScroll(Offset globalPosition) {
    final RenderBox? containerBox = context.findRenderObject() as RenderBox?;
    if (containerBox == null) return;
    final localY = containerBox.globalToLocal(globalPosition).dy;
    final viewHeight = containerBox.size.height;
    const scrollAreaHeight = 60.0;
    const scrollSpeed = 10.0;
    if (localY < scrollAreaHeight) {
      _startAutoScroll(-scrollSpeed);
    } else if (localY > viewHeight - scrollAreaHeight) {
      _startAutoScroll(scrollSpeed);
    } else {
      _stopAutoScroll(isDragEnd: false);
    }
  }

  void _startAutoScroll(double speed) {
    _autoScrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_scrollController.hasClients) {
        final newOffset = (_scrollController.offset + speed).clamp(0.0, _scrollController.position.maxScrollExtent);
        _scrollController.jumpTo(newOffset);
      }
    });
  }

  void _stopAutoScroll({bool isDragEnd = true}) {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
    if (isDragEnd) {
      widget.onDragEnd?.call();
    }
  }

  void _onDragEnd() {
    _stopAutoScroll();
    if (_draggingSchedule != null && _ghostSchedule != null) {
      if(!_draggingSchedule!.id.startsWith("temporary")){
         widget.onScheduleUpdated(_ghostSchedule!);
      }
    }
    setState(() {
      _draggingSchedule = null;
      _ghostSchedule = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWeekDayHeader(widget.startOfWeek),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: GestureDetector(
            onTapUp: (details) {
              final tappedTime = _positionToDateTime(details.globalPosition);
              if (tappedTime != null) {
                widget.onGridTapped(tappedTime);
              }
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: _hourHeight * 24,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      key: _gridKey,
                      children: [
                        _buildGridWithTime(constraints.maxWidth),
                        ..._buildTimedScheduleBlocks(constraints.maxWidth),
                      ],
                    );
                  }
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDayHeader(DateTime startOfWeek) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(color: Theme.of(context).canvasColor, border: Border(bottom: BorderSide(color: Colors.grey[300]!))),
      child: Row(
        children: [
          SizedBox(width: _leftColumnWidth),
          ...List.generate(7, (i) {
            final day = startOfWeek.add(Duration(days: i));
            final isToday = DateUtils.isSameDay(day, DateTime.now());
            final weekDayColor = day.weekday == DateTime.sunday ? Colors.red : (day.weekday == DateTime.saturday ? Colors.blue : Theme.of(context).textTheme.bodyLarge?.color);
            return Expanded(
              child: Column(
                children: [
                  Text(DateFormat('E', 'ja').format(day), style: TextStyle(fontSize: 12, color: weekDayColor)),
                  const SizedBox(height: 4),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isToday ? Colors.blue : Colors.transparent,
                    child: Text(
                      DateFormat('d').format(day),
                      style: TextStyle(fontSize: 14, fontWeight: isToday ? FontWeight.bold : FontWeight.normal, color: isToday ? Colors.white : weekDayColor),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildGridWithTime(double totalWidth) {
    return Stack(
      children: [
        ...List.generate(24, (hour) => Positioned(
          top: _hourToY(hour.toDouble()), left: _leftColumnWidth, right: 0,
          child: Container(height: _hourHeight, decoration: BoxDecoration(border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)))),
        )),
        ...List.generate(6, (day) => Positioned(
          top: 0, bottom: 0, left: _leftColumnWidth + (day + 1) * _getDayColumnWidth(totalWidth),
          child: Container(width: 1, color: Colors.grey.shade200),
        )),
        ...List.generate(24, (hour) => Positioned(
          top: _hourToY(hour.toDouble()) - 8, left: 0, width: _leftColumnWidth - 4,
          child: Text(
            hour == 0 ? '' : DateFormat('H').format(DateTime(2000,1,1,hour)),
            textAlign: TextAlign.right, style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        )),
        _buildTimeIndicator(totalWidth),
      ],
    );
  }

  List<Widget> _buildTimedScheduleBlocks(double viewWidth) {
      final dayColumnWidth = _getDayColumnWidth(viewWidth);
      List<Widget> layoutedEvents = [];

      final Set<String> seenIds = {};
      final uniqueSchedules = widget.schedules.where((schedule) => seenIds.add(schedule.id)).toList();

      for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
        final day = widget.startOfWeek.add(Duration(days: dayIndex));
        final eventsInDay = uniqueSchedules.where((s) => DateUtils.isSameDay(s.date, day)).toList();
        if (eventsInDay.isEmpty) continue;

        final columns = _calculateLayoutColumns(eventsInDay);
        final maxOverlap = columns.length;

        for (int colIndex = 0; colIndex < maxOverlap; colIndex++) {
          for (final schedule in columns[colIndex]) {
            final eventWidth = dayColumnWidth / maxOverlap;
            final eventLeftOffset = colIndex * eventWidth;

            layoutedEvents.add(Positioned(
              key: ValueKey('tile_${schedule.id}'),
              top: _hourToY(schedule.startHour),
              left: _leftColumnWidth + dayIndex * dayColumnWidth + eventLeftOffset,
              width: eventWidth,
              height: max(20.0, _hourToY(schedule.endHour) - _hourToY(schedule.startHour)),
              child: _buildEventTile(schedule),
            ));
          }
        }
      }

      if (_draggingSchedule != null) {
        layoutedEvents.add(_buildOriginalPositionPlaceholder(_draggingSchedule!, viewWidth));
      }
      if (_ghostSchedule != null) {
        layoutedEvents.add(_buildGhostScheduleBlock(_ghostSchedule!, viewWidth));
      }

      return layoutedEvents;
  }

  Widget _buildOriginalPositionPlaceholder(Schedule schedule, double viewWidth) {
      final dayIndex = schedule.date.difference(widget.startOfWeek).inDays.clamp(0, 6);
      if (dayIndex < 0 || dayIndex > 6) return const SizedBox.shrink();

      final dayColumnWidth = _getDayColumnWidth(viewWidth);

      return Positioned(
          key: ValueKey('placeholder_${schedule.id}'),
          top: _hourToY(schedule.startHour),
          left: _leftColumnWidth + dayIndex * dayColumnWidth,
          width: dayColumnWidth - 1,
          height: max(20.0, _hourToY(schedule.endHour) - _hourToY(schedule.startHour)),
          child: Container(
            margin: const EdgeInsets.only(right: 1.0),
            decoration: BoxDecoration(
              color: schedule.color.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4)
            ),
          ),
      );
  }

  Widget _buildEventTile(Schedule schedule) {
    final bool isTemporary = schedule.id.startsWith('temporary');
    final bool isSelected = widget.isSelectionMode && widget.selectedScheduleIds.contains(schedule.id);

    // ★★★ エラー修正：ドラッグ中はジェスチャーを受け取るためにウィジェットは消さず、中身を透明にする ★★★
    return GestureDetector(
      onTap: () => widget.onScheduleTapped(schedule),
      onLongPressStart: (details) {
        if (widget.isSelectionMode || isTemporary) return;
        widget.onDragStart?.call();
        setState(() {
          _draggingSchedule = schedule;
          _ghostSchedule = schedule;
        });
      },
      onLongPressMoveUpdate: (details) {
        if (_draggingSchedule == null) return;
        _handleAutoScroll(details.globalPosition);
        final newDateTime = _positionToDateTime(details.globalPosition);
        if (newDateTime == null) return;

        final duration = _draggingSchedule!.endHour - _draggingSchedule!.startHour;
        final newStartHour = (newDateTime.hour + newDateTime.minute / 60.0).clamp(0.0, 24.0 - duration);

        setState(() {
          _ghostSchedule = _draggingSchedule!.copyWith(
            date: newDateTime,
            startHour: newStartHour,
            endHour: newStartHour + duration,
          );
        });
      },
      onLongPressEnd: (details) => _onDragEnd(),
      child: Opacity(
        // ドラッグ中は元のタイルを透明にするが、ウィジェット自体は残す
        opacity: _draggingSchedule?.id == schedule.id ? 0.0 : 1.0,
        child: isTemporary
          ? _buildTemporaryScheduleBlock(schedule)
          : Container(
              margin: const EdgeInsets.only(right: 2.0),
              padding: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                color: schedule.color.withOpacity(isSelected ? 0.6 : 1.0),
                borderRadius: BorderRadius.circular(4),
                border: isSelected ? Border.all(color: Colors.blue.shade700, width: 2) : null,
              ),
              child: Text(
                schedule.title,
                style: TextStyle(fontSize: 12, color: schedule.color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
      ),
    );
  }

  Widget _buildTemporaryScheduleBlock(Schedule schedule) {
    const double handleInteractiveHeight = 24.0;
    const double handleVisualHeight = 8.0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: (details) {
            widget.onDragStart?.call();
            setState(() {
              _draggingSchedule = schedule;
              _ghostSchedule = schedule;
            });
          },
          onPanUpdate: (details) {
            _handleAutoScroll(details.globalPosition);
            final newDateTime = _positionToDateTime(details.globalPosition);
            if (newDateTime == null) return;

            final duration = schedule.endHour - schedule.startHour;
            final newStartHour = newDateTime.hour + newDateTime.minute / 60.0;

            final updatedSchedule = schedule.copyWith(
                date: newDateTime,
                startHour: newStartHour,
                endHour: newStartHour + duration);

            widget.onTemporaryScheduleUpdated(updatedSchedule);
            setState(() => _ghostSchedule = updatedSchedule);
          },
          onPanEnd: (details) => _onDragEnd(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.orange.shade700, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  schedule.title.isEmpty ? '(タイトル未入力)' : schedule.title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        Positioned( top: -handleInteractiveHeight / 2, left: 0, right: 0, height: handleInteractiveHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: (details) => widget.onDragStart?.call(),
            onVerticalDragUpdate: (details) {
              _handleAutoScroll(details.globalPosition);
              final newStart = _positionToDateTime(details.globalPosition);
              if (newStart == null) return;
              final newStartHour = newStart.hour + newStart.minute / 60.0;
              if (newStartHour >= schedule.endHour - (15/60.0)) return;
              widget.onTemporaryScheduleUpdated(schedule.copyWith(date: newStart, startHour: newStartHour));
            },
            onVerticalDragEnd: (details) => _onDragEnd(),
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(width: 24, height: handleVisualHeight, decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(4)))
            ),
          ),
        ),
        Positioned( bottom: -handleInteractiveHeight / 2, left: 0, right: 0, height: handleInteractiveHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onVerticalDragStart: (details) => widget.onDragStart?.call(),
            onVerticalDragUpdate: (details) {
              _handleAutoScroll(details.globalPosition);
              final newEnd = _positionToDateTime(details.globalPosition);
              if (newEnd == null) return;
              final newEndHour = newEnd.hour + newEnd.minute/60.0;
              if (newEndHour <= schedule.startHour + (15/60.0)) return;
              widget.onTemporaryScheduleUpdated(schedule.copyWith(endHour: newEndHour));
            },
            onVerticalDragEnd: (details) => _onDragEnd(),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(width: 24, height: handleVisualHeight, decoration: BoxDecoration(color: Colors.orange.shade700, borderRadius: BorderRadius.circular(4)))
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGhostScheduleBlock(Schedule schedule, double viewWidth) {
    final dayIndex = schedule.date.difference(widget.startOfWeek).inDays.clamp(0, 6);
    if (dayIndex < 0 || dayIndex > 6) return const SizedBox.shrink();

    final dayColumnWidth = _getDayColumnWidth(viewWidth);
    final top = _hourToY(schedule.startHour);
    final timeLabel = DateFormat('H:mm').format(schedule.date);

    return Stack(
      children: [
        Positioned(
          top: top, left: 0, width: viewWidth,
          child: IgnorePointer(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  top: -8, left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    color: Theme.of(context).canvasColor,
                    child: Text(timeLabel, style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold))
                  )
                ),
                Container(
                  margin: EdgeInsets.only(left: _leftColumnWidth),
                  width: viewWidth - _leftColumnWidth,
                  child: CustomPaint(painter: DottedLinePainter())
                ),
              ],
            ),
          )
        ),
        Positioned(
          key: ValueKey('ghost_body_${schedule.id}'),
          top: top,
          left: _leftColumnWidth + dayIndex * dayColumnWidth,
          width: dayColumnWidth,
          height: max(20.0, _hourToY(schedule.endHour) - _hourToY(schedule.startHour)),
          child: IgnorePointer(
            child: Opacity(
              opacity: 0.7,
              child: Container(
                margin: const EdgeInsets.only(right: 2.0),
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(color: schedule.color, borderRadius: BorderRadius.circular(4)),
                child: Text(
                  schedule.title,
                  style: TextStyle(fontSize: 12, color: schedule.color.computeLuminance() > 0.5 ? Colors.black : Colors.white),
                  overflow: TextOverflow.ellipsis,
                )
              ),
            ),
          ),
        ),
      ]
    );
  }

  Widget _buildTimeIndicator(double viewWidth) {
      final now = DateTime.now();
      final dayIndex = DateUtils.dateOnly(now).difference(DateUtils.dateOnly(widget.startOfWeek)).inDays;
      if (dayIndex < 0 || dayIndex >= 7) return const SizedBox.shrink();

      final top = _hourToY(now.hour + now.minute / 60.0);
      return Positioned(
          top: top,
          left: _leftColumnWidth + dayIndex * _getDayColumnWidth(viewWidth),
          width: _getDayColumnWidth(viewWidth),
          child: IgnorePointer(
              child: Row(
                  children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      Expanded(child: Container(height: 2, color: Colors.red)),
                  ],
              ),
          ),
      );
  }

  List<List<Schedule>> _calculateLayoutColumns(List<Schedule> events) {
    if (events.isEmpty) return [];
    events.sort((a, b) => a.startHour.compareTo(b.startHour));
    List<List<Schedule>> columns = [[]];
    for (final event in events) {
      bool placed = false;
      for (final column in columns) {
        if (column.isEmpty || (column.last.endHour) <= event.startHour) {
          column.add(event);
          placed = true;
          break;
        }
      }
      if (!placed) { columns.add([event]); }
    }
    return columns;
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade400
      ..strokeWidth = 1.5;
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}