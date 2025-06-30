// lib/calendar_home_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'week_view_screen.dart'; // 週表示画面
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sukekenn/core/models/event.dart'; // Eventモデル
import 'package:sukekenn/add_event_screen.dart'; // 予定追加画面

class CalendarHomeScreen extends StatefulWidget {
  const CalendarHomeScreen({super.key});

  @override
  State<CalendarHomeScreen> createState() => _CalendarHomeScreenState();
}

class _CalendarHomeScreenState extends State<CalendarHomeScreen> {
  DateTime displayedMonth = DateTime.now();
  final PageController _pageController = PageController(viewportFraction: 1.0, initialPage: 5000);
  int currentPage = 5000;

  List<Event> _events = [];

  // 現在のユーザーUID
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && user.uid != _currentUserId) {
        setState(() {
          _currentUserId = user.uid;
        });
        _fetchEvents();
      } else if (user == null && _currentUserId != null) {
        setState(() {
          _currentUserId = null;
          _events = [];
        });
      }
    });

    if (_currentUserId != null) {
      _fetchEvents();
    }
  }

  Future<void> _fetchEvents() async {
    if (_currentUserId == null) return;

    final userEventsStream = FirebaseFirestore.instance
        .collection('events')
        .where('userId', isEqualTo: _currentUserId)
        .snapshots();

    final publicEventsStream = FirebaseFirestore.instance
        .collection('events')
        .where('isPublic', isEqualTo: true)
        .snapshots();

    userEventsStream.listen((userSnapshot) {
      final userEvents = userSnapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
      _updateCombinedEvents(userEvents, _events);
    });

    publicEventsStream.listen((publicSnapshot) {
      final publicEvents = publicSnapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
      _updateCombinedEvents(_events, publicEvents);
    });
  }

  void _updateCombinedEvents(List<Event> newEvents, List<Event> existingEvents) {
    final combinedEvents = <Event>[];
    final eventIds = <String>{};

    for (var event in existingEvents) {
      if (eventIds.add(event.id)) {
        combinedEvents.add(event);
      }
    }
    for (var event in newEvents) {
      if (eventIds.add(event.id)) {
        combinedEvents.add(event);
      }
    }

    combinedEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

    setState(() {
      _events = combinedEvents;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            buildAppBar(),
            buildWeekBar(),
            Expanded(
              child: Stack(
                children: [
                  NotificationListener<ScrollEndNotification>(
                    onNotification: (notification) {
                      final page = _pageController.page?.round() ?? currentPage;
                      setState(() {
                        currentPage = page;
                        final baseDate = DateTime.now(); // ここを修正: base -> baseDate
                        displayedMonth = DateTime(baseDate.year, baseDate.month + (page - 5000));
                      });
                      return true;
                    },
                    child: PageView.builder(
                      controller: _pageController,
                      scrollDirection: Axis.vertical,
                      itemBuilder: (context, index) {
                        final monthOffset = index - 5000;
                        final baseDate = DateTime.now();
                        final month = DateTime(baseDate.year, baseDate.month + monthOffset);
                        return buildMonthView(month);
                      },
                    ),
                  ),

                  Positioned(
                    bottom: 16.0,
                    right: 16.0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton(
                          heroTag: 'addEventBtn',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddEventScreen()),
                            );
                          },
                          child: const Icon(Icons.add),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton(
                          heroTag: 'filterBtn',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('フィルター設定画面へ！'))
                            );
                            // TODO: フィルター設定ポップアップの表示ロジック
                          },
                          child: const Icon(Icons.filter_list),
                        ),
                      ],
                    ),
                  ),
                  if (!_isCurrentMonth(_pageController.hasClients ? DateTime(DateTime.now().year, DateTime.now().month + (_pageController.page?.round() ?? currentPage) - 5000) : displayedMonth))
                  Positioned(
                    bottom: 120.0,
                    right: 16.0,
                    child: FloatingActionButton.small(
                      heroTag: 'goToTodayBtn',
                      onPressed: () {
                        setState(() {
                          _pageController.animateToPage(
                            5000,
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeOut,
                          );
                          displayedMonth = DateTime.now();
                        });
                      },
                      child: const Icon(Icons.today),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  // PreferredSizeWidget を返すように修正
  PreferredSizeWidget buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(50), // AppBarの高さ
      child: Container(
        height: 50,
        color: Colors.grey[200],
        child: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: showYearMonthPicker,
                child: Center(
                  child: Text(
                    DateFormat('yyyy年M月', 'ja').format(displayedMonth),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.settings), onPressed: () { /* 設定画面へ */ }),
            IconButton(icon: const Icon(Icons.person_add), onPressed: () { /* フレンド追加 */ }),
          ],
        ),
      ),
    );
  }

  Widget buildWeekBar() {
    return Container(
      height: 30,
      color: Colors.grey[100],
      child: Row(
        children: List.generate(7, (index) {
          const weekDays = ['日', '月', '火', '水', '木', '金', '土'];
          return Expanded(
            child: Center(
              child: Text(
                weekDays[index],
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget buildDrawer() {
    DateTime startDate = displayedMonth;
    DateTime endDate = displayedMonth.add(const Duration(days: 6));
    return Drawer(
      child: ListView(
        children: [
          const DrawerHeader(child: Text('表示切替')),
          ListTile(
            title: const Text('週表示'),
            onTap: () {
              Navigator.pop(context);
              final firstDayOfDisplayedMonth = DateTime(displayedMonth.year, displayedMonth.month, 1);
              final startOfWeek = firstDayOfDisplayedMonth.subtract(Duration(days: firstDayOfDisplayedMonth.weekday % 7));
              jumpToWeekView(startOfWeek);
            },
          ),
          ListTile(
            title: const Text('月表示'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('月表示に切替')));
            },
          ),
          ListTile(
            title: const Text('自由範囲選択'),
            subtitle: Text('${DateFormat('yyyy/MM/dd').format(startDate)}〜${DateFormat('yyyy/MM/dd').format(endDate)}'),
            onTap: () async {
              final pickedRange = await showDateRangePicker(
                context: context,
                initialDateRange: DateTimeRange(start: startDate, end: endDate),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (pickedRange != null) {
                final rangeDays = pickedRange.end.difference(pickedRange.start).inDays + 1;
                if (rangeDays > 42) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('43日以上は選択できません')),
                  );
                } else {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${rangeDays}日間を表示')));
                  // TODO: 自由範囲表示ロジック
                }
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget buildMonthView(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double calendarGridHeight = constraints.maxHeight;
        final int numberOfWeeks = totalCells ~/ 7;
        final double weekHeight = calendarGridHeight / numberOfWeeks;

        return Column(
          children: List.generate(numberOfWeeks, (row) {
            return SizedBox(
              height: weekHeight,
              child: Row(
                children: List.generate(7, (col) {
                  final cellIndex = row * 7 + col;
                  final dayNum = cellIndex - firstWeekday + 1;
                  DateTime date;
                  bool isCurrentMonth = true;

                  if (dayNum < 1) {
                    final prevMonthLastDay = DateTime(month.year, month.month, 0);
                    date = DateTime(prevMonthLastDay.year, prevMonthLastDay.month, prevMonthLastDay.day + dayNum);
                    isCurrentMonth = false;
                  } else if (dayNum > daysInMonth) {
                    date = DateTime(month.year, month.month + 1, dayNum - daysInMonth);
                    isCurrentMonth = false;
                  } else {
                    date = DateTime(month.year, month.month, dayNum);
                  }

                  final isTodayCell = isToday(date);
                  final eventsForDay = _events.where((event) =>
                      event.startTime.year == date.year &&
                      event.startTime.month == date.month &&
                      event.startTime.day == date.day
                  ).toList();

                  return Expanded(
                    child: GestureDetector(
                      onTap: isCurrentMonth ? () => showDayTimeline(date, eventsForDay) : null,
                      onDoubleTap: isCurrentMonth ? () => jumpToWeekView(date) : null,
                      child: Container(
                        margin: const EdgeInsets.all(1),
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isTodayCell ? Colors.red[100] : null,
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${date.day}',
                              style: TextStyle(
                                fontWeight: isTodayCell ? FontWeight.bold : FontWeight.normal,
                                color: isCurrentMonth ? (isTodayCell ? Colors.red : Colors.black) : Colors.grey,
                              ),
                            ),
                            ...eventsForDay.take(2).map((event) => Container(
                                  margin: const EdgeInsets.symmetric(vertical: 1),
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  decoration: BoxDecoration(
                                    color: event.type.defaultColor,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  child: Text(
                                    event.title,
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: (event.type.defaultColor).computeLuminance() < 0.5 ? Colors.white : Colors.black,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                            if (eventsForDay.length > 2)
                              Text(
                                '+${eventsForDay.length - 2}件',
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }

  bool isToday(DateTime date) {
    final today = DateTime.now();
    return today.year == date.year && today.month == date.month && today.day == date.day;
  }

  void showDayTimeline(DateTime date, List<Event> schedules) {
    final double initialHourHeight = 28.75;
    ValueNotifier<double> scaleNotifier = ValueNotifier(1.0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${DateFormat('M月d日').format(date)}の予定'),
        content: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          child: ValueListenableBuilder<double>(
            valueListenable: scaleNotifier,
            builder: (context, scale, _) {
              return GestureDetector(
                onScaleUpdate: (details) {
                  double newScale = (scale * details.scale).clamp(0.5, 4.0);
                  scaleNotifier.value = newScale;
                },
                child: SingleChildScrollView(
                  child: SizedBox(
                    height: 25 * initialHourHeight * scale,
                    child: Stack(
                      children: [
                        ...List.generate(25, (hour) => Positioned(
                              top: hour * initialHourHeight * scale,
                              left: 0,
                              right: 0,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 50,
                                    child: Text('${hour.toString().padLeft(2, '0')}:00'),
                                  ),
                                  Expanded(
                                    child: Container(height: 1, color: Colors.grey.shade400),
                                  ),
                                ],
                              ),
                            )),
                        ...schedules.map((event) {
                          final double startHour = event.startTime.hour + event.startTime.minute / 60.0;
                          final double endHour = event.endTime.hour + event.endTime.minute / 60.0;
                          final double durationHours = endHour - startHour;

                          return Positioned(
                              top: startHour * initialHourHeight * scale,
                              left: 50,
                              right: 0,
                              height: durationHours * initialHourHeight * scale,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: event.type.defaultColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  '${event.title}',
                                  style: TextStyle(
                                    color: (event.type.defaultColor).computeLuminance() < 0.5 ? Colors.white : Colors.black,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            );
                        }),
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
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${DateFormat('M月d日').format(date)}に予定を追加'))
              );
              // TODO: この日付を初期値として予定追加画面へ遷移するロジック
            },
            child: const Text('この日に追加'),
          ),
        ],
      ),
    );
  }

  void jumpToWeekView(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday % 7)); // その週の日曜
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeekViewScreen(startDate: weekStart),
      ),
    );
  }

  void showYearMonthPicker() async {
    int selectedYear = displayedMonth.year;
    int selectedMonth = displayedMonth.month;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('年月を選択'),
        content: Row(
          children: [
            Expanded(
              child: ListWheelScrollView.useDelegate(
                itemExtent: 50,
                onSelectedItemChanged: (index) => selectedYear = 2000 + index,
                controller: FixedExtentScrollController(initialItem: selectedYear - 2000),
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) => Center(child: Text('${2000 + index}年')),
                  childCount: 101,
                ),
              ),
            ),
            Expanded(
              child: ListWheelScrollView.useDelegate(
                itemExtent: 50,
                onSelectedItemChanged: (index) => selectedMonth = index + 1,
                controller: FixedExtentScrollController(initialItem: selectedMonth - 1),
                childDelegate: ListWheelChildBuilderDelegate(
                  builder: (context, index) => Center(child: Text('${index + 1}月')),
                  childCount: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                displayedMonth = DateTime(selectedYear, selectedMonth);
              });
              Navigator.pop(context);
            },
            child: const Text('完了'),
          ),
        ],
      ),
    );
  }
}