import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/presentation/widgets/month_calendar_view.dart';
import 'package:sukekenn/presentation/widgets/week_calendar_view.dart';
import 'package:sukekenn/presentation/pages/calendar/widgets/app_drawer.dart';
import 'package:sukekenn/schedule_creation_sheet.dart';
import 'package:sukekenn/filter_dialog.dart';
import 'package:sukekenn/models/schedule_model.dart';
import 'package:sukekenn/repositories/schedule_repository.dart';

enum CalendarDisplayMode { month, week }

class CalendarViewScreen extends StatefulWidget {
  const CalendarViewScreen({super.key});

  @override
  State<CalendarViewScreen> createState() => _CalendarViewScreenState();
}

class _CalendarViewScreenState extends State<CalendarViewScreen> {
  CalendarDisplayMode _displayMode = CalendarDisplayMode.month;
  DateTime _focusedDate = DateTime.now();
  bool _isSelectionMode = false;
  final List<Schedule> _selectedSchedules = [];
  bool _showTodayButton = false;

  late PageController _monthPageController;
  late PageController _weekPageController;

  List<Schedule> _schedules = [];

  static const int initialPageOffset = 5000;

  @override
  void initState() {
    super.initState();
    _monthPageController = PageController(initialPage: initialPageOffset);
    _weekPageController = PageController(initialPage: initialPageOffset);
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final loaded = await ScheduleRepository().loadSchedules();
    setState(() => _schedules = loaded);
  }

  @override
  void dispose() {
    _monthPageController.dispose();
    _weekPageController.dispose();
    super.dispose();
  }

  void _setDisplayMode(CalendarDisplayMode mode) {
    if (mounted) {
      setState(() => _displayMode = mode);
      if (Navigator.canPop(context)) Navigator.of(context).pop();
    }
  }

  void _onDateDoubleTapped(DateTime date) {
    final now = DateTime.now();
    final startOfWeekToday = now.subtract(Duration(days: now.weekday - 1));
    final startOfWeekTarget = date.subtract(Duration(days: date.weekday - 1));
    final weekDifference = DateUtils.dateOnly(startOfWeekTarget).difference(DateUtils.dateOnly(startOfWeekToday)).inDays ~/ 7;
    final targetWeekPage = initialPageOffset + weekDifference;

    setState(() {
      _displayMode = CalendarDisplayMode.week;
      _focusedDate = date;
      _weekPageController.jumpToPage(targetWeekPage);
    });
  }

  void _onMonthPageChanged(int page) {
    final monthOffset = page - initialPageOffset;
    if (mounted) {
      setState(() {
        _focusedDate = DateTime(DateTime.now().year, DateTime.now().month + monthOffset);
        _checkIfTodayButtonNeeded();
      });
    }
  }

  void _onWeekPageChanged(int page) {
    final now = DateTime.now();
    final startOfWeekToday = now.subtract(Duration(days: now.weekday - 1));
    final weekOffset = page - initialPageOffset;
    if (mounted) {
      setState(() {
        _focusedDate = DateUtils.dateOnly(startOfWeekToday).add(Duration(days: weekOffset * 7));
        _checkIfTodayButtonNeeded();
      });
    }
  }

  void _checkIfTodayButtonNeeded() {
    final now = DateTime.now();
    final difference = _focusedDate.difference(now).inDays.abs();
    bool needed = (_displayMode == CalendarDisplayMode.month && difference > 30) ||
                  (_displayMode == CalendarDisplayMode.week && difference > 7);
    if (_showTodayButton != needed) {
      if (mounted) setState(() => _showTodayButton = needed);
    }
  }

  void _returnToToday() {
    setState(() {
      _focusedDate = DateTime.now();
      _monthPageController.jumpToPage(initialPageOffset);
      _weekPageController.jumpToPage(initialPageOffset);
    });
  }

  void _showYearMonthPicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _focusedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('ja'),
    );
    if (picked != null && picked != _focusedDate) {
      final now = DateTime.now();
      final monthDifference = (picked.year - now.year) * 12 + picked.month - now.month;
      _monthPageController.jumpToPage(initialPageOffset + monthDifference);
    }
  }

  Future<void> _onScheduleSaved(Schedule schedule) async {
    final updatedSchedules = [..._schedules, schedule];
    await ScheduleRepository().saveSchedules(updatedSchedules);
    setState(() => _schedules = updatedSchedules);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: AppDrawer(
        currentMode: _displayMode,
        onNavigate: _setDisplayMode,
      ),
      body: IndexedStack(
        index: _displayMode.index,
        children: [
          MonthCalendarView(
            pageController: _monthPageController,
            onPageChanged: _onMonthPageChanged,
            onDateDoubleTapped: _onDateDoubleTapped,
            isSelectionMode: _isSelectionMode,
            selectedSchedules: _selectedSchedules,
            onSelectionChanged: (schedule) {
              setState(() {
                final idx = _selectedSchedules.indexWhere((s) => s.id == schedule.id);
                if (idx >= 0) {
                  _selectedSchedules.removeAt(idx);
                } else {
                  _selectedSchedules.add(schedule);
                }
              });
            },
            schedules: _schedules,
          ),
          WeekCalendarView(
            pageController: _weekPageController,
            onPageChanged: _onWeekPageChanged,
            focusedDate: _focusedDate,
            schedules: _schedules,
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
      bottomSheet: _isSelectionMode ? _buildActionBar() : null,
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String title = _displayMode == CalendarDisplayMode.month
        ? DateFormat('yyyy年 M月', 'ja').format(_focusedDate)
        : (() {
            final startOfWeek = _focusedDate.subtract(Duration(days: _focusedDate.weekday % 7));
            final weekOfMonth = ((startOfWeek.day - 1) / 7).floor() + 1;
            return '${DateFormat('yyyy年 M月', 'ja').format(startOfWeek)} 第$weekOfMonth週';
          })();

    return AppBar(
      leading: IconButton(
        icon: Icon(_displayMode == CalendarDisplayMode.month ? Icons.view_week : Icons.calendar_view_month),
        onPressed: () {
          _setDisplayMode(_displayMode == CalendarDisplayMode.month
              ? CalendarDisplayMode.week
              : CalendarDisplayMode.month);
        },
      ),
      title: Center(
        child: GestureDetector(
          onTap: _showYearMonthPicker,
          child: Text(title),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(_isSelectionMode ? Icons.cancel : Icons.check_box_outline_blank),
          onPressed: () => setState(() {
            _isSelectionMode = !_isSelectionMode;
            if (!_isSelectionMode) _selectedSchedules.clear();
          }),
        ),
        IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        IconButton(icon: const Icon(Icons.person_add), onPressed: () {}),
      ],
      backgroundColor: Colors.grey[200],
      elevation: 1,
    );
  }

  Widget? _buildFloatingActionButtons() {
    final isAddButtonVisible = (_displayMode == CalendarDisplayMode.week || _displayMode == CalendarDisplayMode.month) && !_isSelectionMode;

    return Stack(
      children: [
        Positioned(
          bottom: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton(
                heroTag: 'filter_button', mini: true,
                onPressed: () => showDialog(context: context, builder: (_) => const FilterDialog()),
                child: const Icon(Icons.filter_list),
              ),
              const SizedBox(height: 16),
              Opacity(
                opacity: isAddButtonVisible ? 1.0 : 0.0,
                child: IgnorePointer(
                  ignoring: !isAddButtonVisible,
                  child: FloatingActionButton(
                    heroTag: 'add_button',
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => DraggableScrollableSheet(
                        initialChildSize: 0.9,
                        builder: (_, controller) => ScheduleCreationSheet(
                          controller: controller,
                          onSave: _onScheduleSaved,
                        ),
                      ),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          TextButton.icon(icon: const Icon(Icons.delete), label: const Text('削除'), onPressed: _selectedSchedules.isEmpty ? null : () {}),
          TextButton.icon(icon: const Icon(Icons.share), label: const Text('共有'), onPressed: _selectedSchedules.isEmpty ? null : () {}),
          TextButton.icon(icon: const Icon(Icons.group_add), label: const Text('招待'), onPressed: _selectedSchedules.isEmpty ? null : () {}),
        ],
      ),
    );
  }
}
