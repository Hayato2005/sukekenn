// lib/application/providers/event_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sukekenn/core/models/event.dart';

// イベントのリストを管理するStateNotifier
class EventNotifier extends StateNotifier<List<Event>> {
  EventNotifier() : super([
    // 初期データ
    Event(
      id: '1',
      ownerId: 'user1',
      title: 'ミーティング',
      startTime: DateTime.now().add(const Duration(hours: 10)),
      endTime: DateTime.now().add(const Duration(hours: 11)),
      type: EventType.fixed,
      isFixed: true,
    ),
    Event(
      id: '2',
      ownerId: 'user2',
      title: 'ランチ',
      startTime: DateTime.now().add(const Duration(days: 2, hours: 12)),
      endTime: DateTime.now().add(const Duration(days: 2, hours: 13)),
      type: EventType.anyone,
      locationPrefecture: '東京都',
      locationCity: '渋谷区',
      genres: ['カフェ', 'おしゃべり'],
      recruitmentDeadline: DateTime.now().add(const Duration(days: 1))
    ),
  ]);

  void addEvent(Event event) {
    state = [...state, event];
  }

  void updateEvent(Event event) {
    state = [
      for (final e in state)
        if (e.id == event.id) event else e,
    ];
  }

  void deleteEvent(String eventId) {
    state = state.where((e) => e.id != eventId).toList();
  }
}

// eventsProviderをStateNotifierProviderに変更
final eventsProvider = StateNotifierProvider<EventNotifier, List<Event>>((ref) {
  return EventNotifier();
});