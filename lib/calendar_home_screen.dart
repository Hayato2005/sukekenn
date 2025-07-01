import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'week_view_screen.dart';
import 'package:sukekenn/presentation/pages/calendar/widgets/month_drawer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');
  runApp(MaterialApp(home: CalendarHomeScreen()));
}

class CalendarHomeScreen extends StatefulWidget {
  const CalendarHomeScreen({super.key});
  @override
  State<CalendarHomeScreen> createState() => _CalendarHomeScreenState();
}

class _CalendarHomeScreenState extends State<CalendarHomeScreen> {
  DateTime displayedMonth = DateTime.now();
  final PageController _pageController = PageController(viewportFraction: 1.0, initialPage: 5000);
  int currentPage = 5000;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const MonthDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            buildAppBar(),
            buildWeekBar(),
            Expanded(
              child: NotificationListener<ScrollEndNotification>(
                onNotification: (notification) {
                  final page = _pageController.page?.round() ?? currentPage;
                  setState(() {
                    currentPage = page;
                    displayedMonth = DateTime(DateTime.now().year, DateTime.now().month + (page - 5000));
                  });
                  return true;
                },
                child: PageView.builder(
                  controller: _pageController,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    final monthOffset = index - 5000;
                    final month = DateTime(DateTime.now().year, DateTime.now().month + monthOffset);
                    return buildMonthView(month);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildAppBar() {
    return Container(
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
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
          IconButton(icon: const Icon(Icons.person_add), onPressed: () {}),
        ],
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
  
  Widget buildMonthView(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = DateUtils.getDaysInMonth(month.year, month.month);
    final totalCells = ((firstWeekday + daysInMonth) / 7).ceil() * 7;

    return Column(
      children: List.generate(totalCells ~/ 7, (row) {
        return Expanded(
          child: Row(
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final dayNum = cellIndex - firstWeekday + 1;
              DateTime date;
              bool isCurrentMonth = true;

              if (dayNum < 1) {
                final prevMonth = DateTime(month.year, month.month, 0);
                date = DateTime(prevMonth.year, prevMonth.month, prevMonth.day + dayNum);
                isCurrentMonth = false;
              } else if (dayNum > daysInMonth) {
                date = DateTime(month.year, month.month + 1, dayNum - daysInMonth);
                isCurrentMonth = false;
              } else {
                date = DateTime(month.year, month.month, dayNum);
              }

              final isTodayCell = isToday(date);
              final fakeSchedules = (isCurrentMonth && dayNum % 4 != 0)
                  ? List.generate(dayNum % 3 + 1, (i) => {
                        'title': '予定${i + 1}',
                        'color': i == 0 ? Colors.green : i == 1 ? Colors.blue : Colors.red,
                        'startHour': 8 + i * 2,
                        'endHour': 9 + i * 2,
                      })
                  : [];

              return Expanded(
                child: GestureDetector(
                  onLongPress: isCurrentMonth ? () => showDayTimeline(date, fakeSchedules.cast<Map<String, dynamic>>()) : null,
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
                        ...fakeSchedules.take(2).map((s) => Container(
                              margin: const EdgeInsets.symmetric(vertical: 1),
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              decoration: BoxDecoration(
                                color: s['color'],
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: Text(
                                s['title'],
                                style: TextStyle(
                                  fontSize: 9,
                                  color: (s['color'] as Color).computeLuminance() < 0.5 ? Colors.white : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
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
  }

  bool isToday(DateTime date) {
    final today = DateTime.now();
    return today.year == date.year && today.month == date.month && today.day == date.day;
  }

  void showDayTimeline(DateTime date, List<Map<String, dynamic>> schedules) {
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
                                  SizedBox(width: 50, child: Text('${hour.toString().padLeft(2, '0')}:00')),
                                  Expanded(child: Container(height: 1, color: Colors.grey.shade400)),
                                ],
                              ),
                            )),
                        ...schedules.map((s) => Positioned(
                              top: s['startHour'] * initialHourHeight * scale,
                              left: 50,
                              right: 0,
                              height: (s['endHour'] - s['startHour']) * initialHourHeight * scale,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: s['color'],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.all(4),
                                child: Text(
                                  '${s['title']} (ユーザー)',
                                  style: TextStyle(
                                    color: (s['color'] as Color).computeLuminance() < 0.5 ? Colors.white : Colors.black,
                                    fontSize: 10,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )),
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
      ),
    );
  }

  void jumpToWeekView(DateTime date) {
    final weekStart = date.subtract(Duration(days: date.weekday % 7));
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WeekViewScreen(startDate: weekStart)),
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

  Widget buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'ホーム'),
        BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'チャット'),
        BottomNavigationBarItem(icon: Icon(Icons.group), label: 'フレンド'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'マッチング'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'マイページ'),
      ],
      currentIndex: 0,
      onTap: (index) {},
    );
  }
}
