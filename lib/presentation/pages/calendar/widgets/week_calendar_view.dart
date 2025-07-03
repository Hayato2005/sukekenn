// lib/presentation/widgets/week_calendar_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeekCalendarView extends StatefulWidget {
  final PageController pageController;
  final Function(int) onPageChanged;
  final DateTime focusedDate;

  const WeekCalendarView({
    super.key,
    required this.pageController,
    required this.onPageChanged,
    required this.focusedDate,
  });

  @override
  State<WeekCalendarView> createState() => _WeekCalendarViewState();
}

class _WeekCalendarViewState extends State<WeekCalendarView> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildWeekDayHeader(widget.focusedDate),
        Expanded(
          child: PageView.builder(
            controller: widget.pageController,
            onPageChanged: widget.onPageChanged,
            itemBuilder: (context, index) {
              // ここでは簡易的に現在の週のみ表示
              // 将来的にはindexに応じて週を計算する
              return _buildWeekGrid(widget.focusedDate);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeekDayHeader(DateTime dateInWeek) {
    final startOfWeek = dateInWeek.subtract(Duration(days: dateInWeek.weekday % 7));
    final formatter = DateFormat('d\nE', 'ja');
    return Container(
       padding: const EdgeInsets.symmetric(vertical: 4.0),
       decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 50), // 時間表示用の余白
          ...List.generate(7, (i) {
            final day = startOfWeek.add(Duration(days: i));
            final isToday = DateUtils.isSameDay(day, DateTime.now());
            return Expanded(
              child: Column(
                children: [
                  Text(
                    formatter.format(day).split('\n')[1], // 曜日
                     style: TextStyle(
                      fontSize: 12,
                      color: day.weekday == DateTime.sunday ? Colors.red : (day.weekday == DateTime.saturday ? Colors.blue : Colors.black),
                    ),
                  ),
                  const SizedBox(height: 4),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isToday ? Colors.blue : Colors.transparent,
                    child: Text(
                      formatter.format(day).split('\n')[0], // 日付
                      style: TextStyle(
                        fontSize: 14,
                        color: isToday ? Colors.white : (day.weekday == DateTime.sunday ? Colors.red : (day.weekday == DateTime.saturday ? Colors.blue : Colors.black)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          })
        ],
      ),
    );
  }

  Widget _buildWeekGrid(DateTime startOfWeek) {
    final hourHeight = 60.0; // 1時間あたりの高さ

    return SingleChildScrollView(
      controller: _scrollController,
      child: GestureDetector( // ドラッグやズームのイベントはここでハンドリング
        onLongPressStart: (details) {
          // ドラッグで予定作成開始
        },
        child: Stack(
          children: [
            // 時間軸のグリッド線
            _buildTimeGrid(hourHeight),
            // ここに予定をPositionedで配置する
          ],
        ),
      ),
    );
  }

  Widget _buildTimeGrid(double hourHeight) {
    return Column(
      children: List.generate(24, (hour) {
        return Row(
          children: [
            SizedBox(
              width: 50,
              height: hourHeight,
              child: Center(
                child: Text(
                  hour == 0 ? '' : '$hour:00',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: hourHeight,
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
              ),
            )
          ],
        );
      }),
    );
  }
}