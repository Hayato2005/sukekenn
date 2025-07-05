import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';
import 'package:sukekenn/presentation/widgets/calendar/event_tile.dart';
import 'dart:ui' as ui;

enum DragMode { none, move, resizeTop, resizeBottom }

class WeekCalendarView extends StatefulWidget {
  final DateTime startOfWeek;
  final List<Schedule> schedules;
  final Function(Schedule) onScheduleTapped;
  final Function(Schedule) onScheduleUpdated;
  final Function(DateTime) onWeekHeaderTapped;
  final Function(int) onPageRequested;
  
  final Schedule? temporarySchedule;
  final Function(Schedule) onTemporaryScheduleCreated;
  final Function(Schedule) onTemporaryScheduleUpdated;
  final VoidCallback onTemporaryScheduleCleared;


  final bool isSelectionMode;
  final List<String> selectedScheduleIds;
  
  const WeekCalendarView({
    super.key,
    required this.startOfWeek,
    required this.schedules,
    required this.onScheduleTapped,
    required this.onScheduleUpdated,
    required this.onWeekHeaderTapped,
    required this.onPageRequested,
    this.temporarySchedule,
    required this.onTemporaryScheduleCreated,
    required this.onTemporaryScheduleUpdated,
    required this.onTemporaryScheduleCleared,
    this.isSelectionMode = false,
    this.selectedScheduleIds = const [],
  });

  @override
  State<WeekCalendarView> createState() => _WeekCalendarViewState();
}

class _WeekCalendarViewState extends State<WeekCalendarView> {
  late final ScrollController _scrollController;
  final GlobalKey _gridKey = GlobalKey();

  final double _hourHeight = 60.0;
  final double _leftColumnWidth = 50.0;
  final double _headerHeight = 60.0;
  final double _allDayAreaHeight = 30.0;

  // --- 状態管理 ---
  Schedule? _draggingSchedule;
  Offset? _dragStartOffset;
  Schedule? _ghostAtOriginalPosition;
  
  DragMode _dragMode = DragMode.none;
  DateTime? _dragGuideTime;
  Offset _panStartOffsetInSchedule = Offset.zero;


  // --- オートスクロール関連 ---
  Timer? _vScrollTimer;
  Timer? _hScrollTimer;
  DateTime? _lastHScrollTime;

  Timer? _timeIndicatorTimer;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(
      initialScrollOffset: _hourHeight * 7,
    );
    _startTimeIndicatorTimer();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _timeIndicatorTimer?.cancel();
    _stopAllAutoScroll();
    super.dispose();
  }

  void _startTimeIndicatorTimer() {
    _timeIndicatorTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  // --- 座標・時間変換ユーティリティ ---
  double _snapToMinutes(double hour, int minutes) {
    final totalMinutes = hour * 60;
    final snappedTotalMinutes = (totalMinutes / minutes).round() * minutes;
    return snappedTotalMinutes / 60.0;
  }

  DateTime? _offsetToDateTime(Offset positionInGrid) {
    final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return null;

    final dayColumnWidth = (gridBox.size.width - _leftColumnWidth) / 7;
    
    final dx = positionInGrid.dx.clamp(_leftColumnWidth, gridBox.size.width);
    final dy = positionInGrid.dy; 

    final int dayIndex = ((dx - _leftColumnWidth) / dayColumnWidth).floor().clamp(0, 6);
    final date = widget.startOfWeek.add(Duration(days: dayIndex));

    final double hour = dy / _hourHeight;
    
    return date.copyWith(
      hour: hour.floor(),
      minute: ((hour - hour.floor()) * 60).floor()
    );
  }

  // --- ジェスチャーハンドリング ---
  void _onTapUp(TapUpDetails details) {
    if (widget.isSelectionMode || widget.temporarySchedule != null || _draggingSchedule != null) return;
    
    final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final localPosition = gridBox.globalToLocal(details.globalPosition);
    final adjustedPosition = Offset(localPosition.dx, localPosition.dy + _scrollController.offset);

    final tappedDateTime = _offsetToDateTime(adjustedPosition);
    if (tappedDateTime == null) return;
    
    final tappedHour = tappedDateTime.hour + tappedDateTime.minute / 60.0;
    final centeredStartHour = _snapToMinutes(tappedHour - 0.5, 15);
    
    final tempSchedule = Schedule.empty().copyWith(
      id: 'temporary_schedule_${DateTime.now().millisecondsSinceEpoch}',
      title: '', 
      color: Colors.amber,
      date: DateUtils.dateOnly(tappedDateTime),
      startHour: centeredStartHour.clamp(0.0, 23.0),
      endHour: (centeredStartHour + 1.0).clamp(1.0, 24.0),
    );

    widget.onTemporaryScheduleCreated(tempSchedule);
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (widget.isSelectionMode || widget.temporarySchedule != null) return;
    
    final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final localPosition = gridBox.globalToLocal(details.globalPosition);
    final adjustedPosition = Offset(localPosition.dx, localPosition.dy + _scrollController.offset);

    Schedule? targetSchedule;
    for (var schedule in widget.schedules.reversed) {
      final hitRect = _getScheduleRect(schedule, gridBox.size);
      if (hitRect != null && hitRect.contains(adjustedPosition)) {
        targetSchedule = schedule;
        break;
      }
    }
    
    if (targetSchedule != null) {
      setState(() {
        _draggingSchedule = targetSchedule;
        _ghostAtOriginalPosition = targetSchedule;
        _dragStartOffset = adjustedPosition;
        _dragMode = DragMode.move;
      });
    }
  }

  void _onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (_draggingSchedule == null || _dragStartOffset == null) return;
    
    _handleAutoScroll(details.globalPosition);

    final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;
    
    final localPosition = gridBox.globalToLocal(details.globalPosition);
    final adjustedPosition = Offset(localPosition.dx, localPosition.dy + _scrollController.offset);

    final dragDeltaHours = (adjustedPosition.dy - _dragStartOffset!.dy) / _hourHeight;
    
    final originalStartHour = _ghostAtOriginalPosition!.startHour;
    final newStartHourRaw = originalStartHour + dragDeltaHours;
    final newStartHourSnapped = _snapToMinutes(newStartHourRaw, 15);

    final duration = _ghostAtOriginalPosition!.endHour - _ghostAtOriginalPosition!.startHour;
    
    final newDateTime = _offsetToDateTime(adjustedPosition);
    if (newDateTime == null) return;
    
    final newStartHourClamped = newStartHourSnapped.clamp(0.0, 24.0 - duration);
    
    setState(() {
      _draggingSchedule = _ghostAtOriginalPosition!.copyWith(
        date: DateUtils.dateOnly(newDateTime),
        startHour: newStartHourClamped,
        endHour: newStartHourClamped + duration,
      );
      // ★★★★★ 修正点 ★★★★★
      // 点線ガイドの時刻を確実に更新
      _dragGuideTime = newDateTime.copyWith(
          hour: newStartHourClamped.floor(),
          minute: ((newStartHourClamped - newStartHourClamped.floor()) * 60).round()
      );
    });
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_draggingSchedule != null) {
      if(_draggingSchedule!.startHour >= 0 && _draggingSchedule!.endHour <= 24) {
        widget.onScheduleUpdated(_draggingSchedule!);
      }
    }
    _stopAllAutoScroll();
    setState(() {
      _draggingSchedule = null;
      _ghostAtOriginalPosition = null;
      _dragStartOffset = null;
      _dragGuideTime = null;
      _dragMode = DragMode.none;
    });
  }
  
  Rect? _getScheduleRect(Schedule schedule, Size gridSize) {
    if (schedule.date == null) return null;

    final dayColumnWidth = (gridSize.width - _leftColumnWidth) / 7;
    final dayIndex = schedule.date!.weekday % 7; 

    final dailySchedules = widget.schedules.where((s) => s.date != null && DateUtils.isSameDay(s.date, schedule.date) && !s.isAllDay).toList();
    final layoutColumns = _calculateLayoutColumns(dailySchedules);
    int colIndex = -1;
    int colCount = 1;

    for (int i = 0; i < layoutColumns.length; i++) {
      if (layoutColumns[i].any((s) => s.id == schedule.id)) {
        colIndex = i;
        colCount = layoutColumns.length;
        break;
      }
    }
    if (colIndex == -1) return null;

    final eventWidth = dayColumnWidth / colCount;
    final eventLeftOffset = colIndex * eventWidth;
    final left = _leftColumnWidth + (dayIndex * dayColumnWidth) + eventLeftOffset;
    final top = schedule.startHour * _hourHeight;
    final height = (schedule.endHour - schedule.startHour) * _hourHeight;
    
    return Rect.fromLTWH(left, top, eventWidth, height.clamp(0, double.infinity));
  }

  // --- オートスクロール ---
  void _handleAutoScroll(Offset globalPosition) {
    final RenderBox? view = context.findRenderObject() as RenderBox?;
    if (view == null) return;

    final x = globalPosition.dx;
    final y = globalPosition.dy;
    
    const vScrollThreshold = 80.0;
    const vScrollSpeed = 10.0;
    final headerTotalHeight = _headerHeight + _allDayAreaHeight + 1;
    if (y < vScrollThreshold + headerTotalHeight) {
      _startVScroll(-vScrollSpeed);
    } else if (y > view.size.height - vScrollThreshold) {
      _startVScroll(vScrollSpeed);
    } else {
      _stopVScroll();
    }
    
    final dayColumnWidth = (view.size.width - _leftColumnWidth) / 7;
    final rightTriggerAreaStart = _leftColumnWidth + (dayColumnWidth * 6.5);

    if (x < _leftColumnWidth + 20) {
      _startHScroll(-1);
    } else if (x > rightTriggerAreaStart) {
      _startHScroll(1);
    } else {
      _stopHScroll();
    }
  }

  void _startVScroll(double speed) {
    if (_vScrollTimer?.isActive ?? false) return;
    _vScrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if(!_scrollController.hasClients) return;
      _scrollController.jumpTo((_scrollController.offset + speed).clamp(
        _scrollController.position.minScrollExtent,
        _scrollController.position.maxScrollExtent
      ));
    });
  }

  void _stopVScroll() {
    _vScrollTimer?.cancel();
  }

  void _startHScroll(int direction) {
      if (_hScrollTimer?.isActive ?? false) return;
      if (_lastHScrollTime != null && DateTime.now().difference(_lastHScrollTime!) < const Duration(seconds: 1)) {
        return;
      }
      _lastHScrollTime = DateTime.now();
      widget.onPageRequested(direction);
      _hScrollTimer = Timer(const Duration(seconds: 1), () => _hScrollTimer = null);
  }

  void _stopHScroll() {
    _hScrollTimer?.cancel();
  }

  void _stopAllAutoScroll() {
    _stopVScroll();
    _stopHScroll();
  }
  
  // ★★★★★ 修正点 ★★★★★
  // --- 仮予定の操作 (ロジックを全面的に見直し、正常に動作するように修正) ---
  void _onTemporaryPanStart(DragStartDetails details) {
    final baseSchedule = widget.temporarySchedule;
    if (baseSchedule == null) return;
    
    final localY = details.localPosition.dy;
    final height = (baseSchedule.endHour - baseSchedule.startHour) * _hourHeight;
    const handleSize = 25.0; // 当たり判定を広めに

    if (localY < handleSize) { 
        setState(() => _dragMode = DragMode.resizeTop);
    } else if (localY > height - handleSize) {
        setState(() => _dragMode = DragMode.resizeBottom);
    } else {
        setState(() => _dragMode = DragMode.move);
        _panStartOffsetInSchedule = details.localPosition;
    }
  }

  void _onTemporaryPanUpdate(DragUpdateDetails details) {
    final baseSchedule = widget.temporarySchedule;
    if (baseSchedule == null || _dragMode == DragMode.none) return;
    
    // 将来のオートスクロール機能のために、既存のドラッグと同じ処理を呼ぶ
    _handleAutoScroll(details.globalPosition);
    
    final RenderBox? gridBox = _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (gridBox == null) return;

    final localPosition = gridBox.globalToLocal(details.globalPosition);
    final adjustedPosition = Offset(localPosition.dx, localPosition.dy + _scrollController.offset);
    
    Schedule? newTempSchedule;

    if (_dragMode == DragMode.move) {
        final currentY = adjustedPosition.dy - _panStartOffsetInSchedule.dy;
        final newStartHour = _snapToMinutes(currentY / _hourHeight, 15);
        final duration = baseSchedule.endHour - baseSchedule.startHour;
        
        newTempSchedule = baseSchedule.copyWith(
          startHour: newStartHour.clamp(0.0, 24.0 - duration),
          endHour: (newStartHour + duration).clamp(duration, 24.0),
        );
    } else { // resizeTop or resizeBottom
        final currentHour = _snapToMinutes(adjustedPosition.dy / _hourHeight, 15);
        if (_dragMode == DragMode.resizeTop) {
            if (currentHour < baseSchedule.endHour - 0.25) {
                newTempSchedule = baseSchedule.copyWith(startHour: currentHour);
            }
        } else { // resizeBottom
            if (currentHour > baseSchedule.startHour + 0.25) {
                newTempSchedule = baseSchedule.copyWith(endHour: currentHour);
            }
        }
    }

    if (newTempSchedule != null) {
        final guideTimeHour = _dragMode == DragMode.resizeBottom ? newTempSchedule.endHour : newTempSchedule.startHour;
        final currentGuideDate = newTempSchedule.date;

        if (currentGuideDate != null) {
            setState(() {
                _dragGuideTime = currentGuideDate.copyWith(
                    hour: guideTimeHour.floor(),
                    minute: ((guideTimeHour - guideTimeHour.floor()) * 60).round()
                );
            });
        }
        widget.onTemporaryScheduleUpdated(newTempSchedule);
    }
  }

  void _onTemporaryPanEnd(DragEndDetails details) {
    setState(() {
      _dragMode = DragMode.none;
      _dragGuideTime = null;
      _panStartOffsetInSchedule = Offset.zero;
    });
    _stopAllAutoScroll();
  }
  
  // --- ビルドメソッド ---
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWeekDayHeader(),
        _buildAllDayArea(),
        const Divider(height: 1, thickness: 1),
        Expanded(
          child: GestureDetector(
            key: _gridKey,
            onTapUp: _onTapUp,
            onLongPressStart: _onLongPressStart,
            onLongPressMoveUpdate: _onLongPressMoveUpdate,
            onLongPressEnd: _onLongPressEnd,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
              child: SizedBox(
                height: _hourHeight * 24,
                child: LayoutBuilder(builder: (context, constraints) {
                  return Stack(
                    children: [
                      CustomPaint(
                        size: constraints.biggest,
                        painter: _WeekGridPainter(
                          hourHeight: _hourHeight,
                          leftColumnWidth: _leftColumnWidth,
                          context: context,
                          dragGuideTime: _dragGuideTime,
                        ),
                      ),
                      _buildTimeAxis(),
                      ..._buildScheduleBlocks(constraints.biggest),
                      if (_ghostAtOriginalPosition != null)
                        _buildGhostScheduleBlock(_ghostAtOriginalPosition!, constraints.biggest, isOriginalPosition: true),
                      if (_draggingSchedule != null)
                         _buildGhostScheduleBlock(_draggingSchedule!, constraints.biggest, isOriginalPosition: false),
                      if (widget.temporarySchedule != null)
                        _buildTemporaryScheduleBlock(widget.temporarySchedule!, constraints.biggest),
                      _buildTimeIndicator(constraints.biggest),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDayHeader() {
    return Container(
      height: _headerHeight,
      padding: EdgeInsets.only(left: _leftColumnWidth),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey.shade300))
      ),
      child: Row(
        children: List.generate(7, (index) {
          final date = widget.startOfWeek.add(Duration(days: index));
          final isToday = DateUtils.isSameDay(date, DateTime.now());
          return Expanded(
            child: GestureDetector(
              onTap: () => widget.onWeekHeaderTapped(date),
              child: Container(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat.E('ja').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isToday ? Theme.of(context).primaryColor : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: isToday ? BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ) : null,
                      child: Center(
                        child: Text(
                          date.day.toString(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isToday ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAllDayArea() {
    return Container(
      height: _allDayAreaHeight,
      padding: EdgeInsets.only(left: _leftColumnWidth),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200))
      ),
      child: const Center(child: Text("終日", style: TextStyle(color: Colors.grey, fontSize: 12))),
    );
  }

  Widget _buildTimeAxis() {
    return Positioned(
      left: 0,
      top: 0,
      width: _leftColumnWidth,
      bottom: 0,
      child: Column(
        children: List.generate(24, (hour) {
          return Container(
            height: _hourHeight,
            alignment: Alignment.topCenter,
            child: Transform.translate(
              offset: const Offset(0, -7),
              child: Text(
                hour == 0 ? '' : '$hour',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ),
          );
        }),
      ),
    );
  }

  List<Widget> _buildScheduleBlocks(Size gridSize) {
    return widget.schedules.map((schedule) {
      if (_draggingSchedule?.id == schedule.id) {
        return const SizedBox.shrink();
      }
      final rect = _getScheduleRect(schedule, gridSize);
      if (rect == null) return const SizedBox.shrink();

      return Positioned.fromRect(
        rect: rect,
        child: EventTile(
          schedule: schedule,
          isSelected: widget.isSelectionMode && widget.selectedScheduleIds.contains(schedule.id),
          onTap: (tappedSchedule) => widget.onScheduleTapped(tappedSchedule),
        ),
      );
    }).toList();
  }
  
  List<List<Schedule>> _calculateLayoutColumns(List<Schedule> dailySchedules) {
    if (dailySchedules.isEmpty) return [];

    List<List<Schedule>> columns = [];
    dailySchedules.sort((a, b) => a.startHour.compareTo(b.startHour));

    for (var schedule in dailySchedules) {
      bool placed = false;
      for (var column in columns) {
        if (column.every((s) => schedule.startHour >= s.endHour || schedule.endHour <= s.startHour)) {
          column.add(schedule);
          placed = true;
          break;
        }
      }
      if (!placed) {
        columns.add([schedule]);
      }
    }
    return columns;
  }
  
  Widget _buildGhostScheduleBlock(Schedule schedule, Size gridSize, {required bool isOriginalPosition}) {
    Rect? rect;
    if(isOriginalPosition) {
        rect = _getScheduleRect(schedule, gridSize);
    } else {
        if (schedule.date == null) return const SizedBox.shrink();
        final dayColumnWidth = (gridSize.width - _leftColumnWidth) / 7;
        final dayIndex = schedule.date!.weekday % 7;
        final left = _leftColumnWidth + (dayIndex * dayColumnWidth);
        final top = schedule.startHour * _hourHeight;
        final height = (schedule.endHour - schedule.startHour) * _hourHeight;
        rect = Rect.fromLTWH(left, top, dayColumnWidth, height.clamp(0, double.infinity));
    }

    if (rect == null) return const SizedBox.shrink();

    return Positioned.fromRect(
      rect: rect,
      child: Opacity(
        opacity: isOriginalPosition ? 0.3 : 0.6,
        child: Container(
          margin: const EdgeInsets.only(right: 2.0),
          padding: const EdgeInsets.all(4.0),
          decoration: BoxDecoration(
            color: schedule.color,
            borderRadius: BorderRadius.circular(4),
            border: !isOriginalPosition ? Border.all(color: Colors.grey.shade700, style: BorderStyle.solid) : null,
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
  
  Widget _buildTemporaryScheduleBlock(Schedule schedule, Size gridSize) {
    if (schedule.date == null) return const SizedBox.shrink();
    final dayColumnWidth = (gridSize.width - _leftColumnWidth) / 7;
    final dayIndex = schedule.date!.weekday % 7;
    final top = schedule.startHour * _hourHeight;
    final height = (schedule.endHour - schedule.startHour) * _hourHeight;
    final left = _leftColumnWidth + (dayIndex * dayColumnWidth);

    return Positioned(
      top: top,
      left: left,
      width: dayColumnWidth,
      height: height.clamp(0, double.infinity),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onTemporaryPanStart,
        onPanUpdate: _onTemporaryPanUpdate,
        onPanEnd: _onTemporaryPanEnd,
        child: Container(
          margin: const EdgeInsets.only(right: 2.0),
          decoration: BoxDecoration(
            color: schedule.color.withOpacity(0.8),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade700)
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Center(
                  child: Text(
                    schedule.title,
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Positioned(
                top: -8, left: 0, right: 0,
                child: Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: Container(width: 24, height: 16,
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade400))
                    ),
                  ),
                ),
              ),
               Positioned(
                bottom: -8, left: 0, right: 0,
                child: Center(
                  child: MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: Container(width: 24, height: 16,
                       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade400))
                    ),
                  ),
                ),
              ),
            ],
          )
        ),
      ),
    );
  }

  Widget _buildTimeIndicator(Size gridSize) {
    final now = DateTime.now();
    if (now.isBefore(widget.startOfWeek) || now.isAfter(widget.startOfWeek.add(const Duration(days: 7)))) {
      return const SizedBox.shrink();
    }

    final dayColumnWidth = (gridSize.width - _leftColumnWidth) / 7;
    final top = (now.hour + now.minute / 60.0) * _hourHeight;
    final dayIndex = now.weekday % 7;
    final left = _leftColumnWidth + (dayIndex * dayColumnWidth);

    return Positioned(
      top: top,
      left: left,
      width: dayColumnWidth,
      child: Row(
        children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
          ),
          Expanded(child: Container(height: 1.5, color: Colors.red)),
        ],
      ),
    );
  }
}

class _WeekGridPainter extends CustomPainter {
  final double hourHeight;
  final double leftColumnWidth;
  final BuildContext context;
  final DateTime? dragGuideTime;

  _WeekGridPainter({required this.hourHeight, required this.leftColumnWidth, required this.context, this.dragGuideTime});

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1.0;
    
    final dayColumnWidth = (size.width - leftColumnWidth) / 7;

    for (int hour = 0; hour < 24; hour++) {
      final y = hour * hourHeight;
      canvas.drawLine(Offset(leftColumnWidth, y), Offset(size.width, y), linePaint);
    }

    for (int day = 0; day <= 7; day++) {
      final x = leftColumnWidth + day * dayColumnWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
    
    if (dragGuideTime != null) {
        final guidePaint = Paint()
          ..color = Theme.of(context).primaryColor.withOpacity(0.7)
          ..strokeWidth = 1.5;
        
        final snappedHour = _snapToMinutes(((dragGuideTime!.hour + dragGuideTime!.minute / 60.0)), 15);
        final y = snappedHour * hourHeight;

        const dashWidth = 4;
        const dashSpace = 4;
        double startX = leftColumnWidth;
        final path = Path();
        while (startX < size.width) {
          path.moveTo(startX, y);
          path.lineTo(startX + dashWidth, y);
          startX += dashWidth + dashSpace;
        }
        canvas.drawPath(path, guidePaint);

        final timeText = DateFormat('HH:mm').format(dragGuideTime!);
        final textPainter = TextPainter(
            text: TextSpan(
                text: timeText,
                style: TextStyle(fontSize: 12, color: Colors.white, backgroundColor: Theme.of(context).primaryColor.withOpacity(0.9)),
            ),
            textDirection: ui.TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: leftColumnWidth -4);
        textPainter.paint(canvas, Offset(4, y - textPainter.height / 2));
    }
  }

  double _snapToMinutes(double hour, int minutes) {
    final totalMinutes = hour * 60;
    final snappedTotalMinutes = (totalMinutes / minutes).round() * minutes;
    return snappedTotalMinutes / 60.0;
  }

  @override
  bool shouldRepaint(covariant _WeekGridPainter oldDelegate) {
    return oldDelegate.hourHeight != hourHeight || oldDelegate.dragGuideTime != dragGuideTime;
  }
}