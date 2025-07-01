// lib/presentation/pages/calendar/calendar_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/application/providers/calendar_providers.dart';
import 'package:sukekenn/application/providers/event_provider.dart';
import 'package:sukekenn/core/models/event.dart';
import 'package:sukekenn/presentation/pages/calendar/widgets/calendar_day_cell.dart';
import 'package:sukekenn/presentation/pages/calendar/widgets/day_timeline_popup.dart';
import 'package:sukekenn/presentation/pages/calendar/widgets/event_form_page.dart';
// --- 修正点：app_drawer.dartのimportパスを修正 ---
import 'widgets/app_drawer.dart'; 
import 'package:sukekenn/presentation/pages/calendar/widgets/year_month_picker_modal.dart';
import 'package:sukekenn/presentation/pages/calendar/widgets/week_view_widget.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarFormat = ref.watch(calendarFormatProvider);
    final focusedDay = ref.watch(focusedDayProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final globalKey = GlobalKey<ScaffoldState>();

    final events = ref.watch(eventsProvider);

    List<Event> getEventsForDay(DateTime day) {
      return events.where((event) => isSameDay(event.startTime, day)).toList();
    }
    
    return Scaffold(
      key: globalKey,
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            globalKey.currentState?.openDrawer();
          },
        ),
        title: GestureDetector(
          onTap: () async {
            final newDate = await showModalBottomSheet<DateTime>(
              context: context,
              builder: (_) => YearMonthPickerModal(initialDate: focusedDay),
            );
            if (newDate != null) {
              ref.read(focusedDayProvider.notifier).state = newDate;
            }
          },
          child: Text(DateFormat('yyyy年M月', 'ja').format(focusedDay)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), 
            onPressed: () {}),
          IconButton(
            icon: const Icon(Icons.person_add), 
            onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
           Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EventFormPage(),
              ),
            );
        },
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: calendarFormat == CalendarFormat.month
            ? TableCalendar<Event>( 
                locale: 'ja_JP',
                availableGestures: AvailableGestures.verticalSwipe,
                headerVisible: false,
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: focusedDay,
                calendarFormat: calendarFormat,
                selectedDayPredicate: (day) => isSameDay(selectedDay, day),
                onDaySelected: (newSelectedDay, newFocusedDay) {
                  ref.read(selectedDayProvider.notifier).state = newSelectedDay;
                  
                  showDialog(
                    context: context,
                    builder: (context) {
                      return DayTimelinePopup(
                        date: newSelectedDay,
                        events: getEventsForDay(newSelectedDay),
                      );
                    },
                  );
                },
                onPageChanged: (newFocusedDay) {
                  ref.read(focusedDayProvider.notifier).state = newFocusedDay;
                },
                eventLoader: getEventsForDay,
                calendarBuilders: CalendarBuilders(
                   defaultBuilder: (context, day, focusedDay) {
                    return CalendarDayCell(day: day, events: getEventsForDay(day));
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return CalendarDayCell(day: day, events: getEventsForDay(day), isToday: true);
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    return CalendarDayCell(day: day, events: getEventsForDay(day), isSelected: true);
                  },
                  outsideBuilder: (context, day, focusedDay) {
                    return CalendarDayCell(day: day, events: getEventsForDay(day), isOutside: true);
                  },
                ),
              )
            : const WeekViewWidget(), 
      ),
    );
  }
}