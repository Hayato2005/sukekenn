import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/presentation/pages/calendar/widgets/week_drawer.dart'; // ドロワー

class WeekViewScreen extends StatefulWidget {
  final DateTime startDate;
  const WeekViewScreen({Key? key, required this.startDate}) : super(key: key);

  @override
  State<WeekViewScreen> createState() => _WeekViewScreenState();
}

class _WeekViewScreenState extends State<WeekViewScreen> {
  final DateTime startDate = DateTime(0, 1, 1);
  final DateTime endDate = DateTime(3000, 12, 31);
  late final int totalDays;
  late final int initialPage;
  late final PageController _pageController;
  final ScrollController _scrollController = ScrollController();

  double hourHeight = 50.0;

  @override
  void initState() {
    super.initState();
    totalDays = endDate.difference(startDate).inDays;
    initialPage = widget.startDate.difference(startDate).inDays;
    _pageController = PageController(initialPage: initialPage);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final eightAM = 8 * hourHeight;
      _scrollController.jumpTo(eightAM);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const WeekDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.black),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  DateFormat('yyyy年M月', 'ja').format(
                    startDate.add(Duration(days: _pageController.hasClients ? _pageController.page?.round() ?? initialPage : initialPage)),
                  ),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.check_box, color: Colors.black), onPressed: () {}),
            IconButton(icon: const Icon(Icons.settings, color: Colors.black), onPressed: () {}),
            IconButton(icon: const Icon(Icons.person_add, color: Colors.black), onPressed: () {}),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: totalDays,
        itemBuilder: (context, index) {
          final currentDate = startDate.add(Duration(days: index));
          final startOfWeek = currentDate.subtract(Duration(days: currentDate.weekday % 7));
          return buildWeekView(startOfWeek);
        },
      ),
    );
  }

  Widget buildWeekView(DateTime startOfWeek) {
    return Column(
      children: [
        buildWeekHeader(startOfWeek),
        Expanded(
          child: GestureDetector(
            onScaleUpdate: (details) {
              setState(() {
                hourHeight = (hourHeight * details.scale).clamp(20.0, 150.0);
              });
            },
            child: SingleChildScrollView(
              controller: _scrollController,
              child: SizedBox(
                height: 25 * hourHeight,
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Stack(
                        children: List.generate(25, (hour) {
                          final topPosition = hour == 0
                              ? 0
                              : hour == 24
                                  ? 24 * hourHeight - 14
                                  : hour * hourHeight - 14;
                          return Positioned(
                            top: topPosition.toDouble(),
                            right: 4,
                            child: Text('${hour.toString().padLeft(2, '0')}:00', style: const TextStyle(fontSize: 14)),
                          );
                        }),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: List.generate(7, (i) {
                          final date = startOfWeek.add(Duration(days: i));
                          return Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  right: BorderSide(color: Colors.grey[300]!),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Column(
                                    children: List.generate(25, (hour) {
                                      return Stack(
                                        children: [
                                          Container(
                                            height: hourHeight,
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: Colors.grey[400]!,
                                                  width: 1.0,
                                                ),
                                              ),
                                            ),
                                          ),
                                          if (hour < 24)
                                            Positioned(
                                              top: hourHeight / 2,
                                              left: 0,
                                              right: 0,
                                              child: Container(
                                                height: 0.5,
                                                color: Colors.grey.withOpacity(0.3),
                                              ),
                                            ),
                                        ],
                                      );
                                    }),
                                  ),
                                  if (i % 2 == 0)
                                    Positioned(
                                      top: 8 * hourHeight,
                                      height: hourHeight * 2,
                                      left: 2,
                                      right: 2,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Center(
                                          child: Text('予定', style: TextStyle(fontSize: 10, color: Colors.white)),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget buildWeekHeader(DateTime startOfWeek) {
    return Container(
      height: 40,
      color: Colors.grey[300],
      child: Row(
        children: [
          const SizedBox(width: 60),
          Expanded(
            child: Row(
              children: List.generate(7, (i) {
                final date = startOfWeek.add(Duration(days: i));
                final isToday = isSameDate(date, DateTime.now());
                return Expanded(
                  child: Container(
                    color: isToday ? Colors.red[100] : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('MM/dd', 'ja').format(date),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          DateFormat('E', 'ja').format(date),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  bool isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
