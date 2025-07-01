// lib/presentation/pages/calendar/widgets/event_detail_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/application/providers/event_provider.dart';
import 'package:sukekenn/core/models/event.dart';
import 'package:sukekenn/presentation/pages/calendar/widgets/event_form_page.dart';

class EventDetailDialog extends ConsumerWidget {
  final Event event;

  const EventDetailDialog({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDetailRow(
              icon: Icons.calendar_today,
              label: '日時',
              value:
                  '${DateFormat('M/d HH:mm').format(event.startTime)} - ${DateFormat('HH:mm').format(event.endTime)}',
            ),
            _buildDetailRow(
              icon: Icons.category_outlined,
              label: '種別',
              value: event.type.displayName,
            ),
             if(event.recruitmentDeadline != null)
              _buildDetailRow(
                icon: Icons.timer_outlined,
                label: '募集期間',
                value: '${DateFormat('M月d日').format(event.recruitmentDeadline!)}まで',
              ),
            if(event.locationPrefecture != null)
              _buildDetailRow(
                icon: Icons.location_on_outlined,
                label: '場所',
                value: '${event.locationPrefecture} ${event.locationCity ?? ''}',
              ),
            if(event.genres != null && event.genres!.isNotEmpty)
             _buildDetailRow(
                icon: Icons.sell_outlined,
                label: 'ジャンル',
                value: event.genres!.join(', '),
              ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: '削除',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('予定の削除'),
                content: Text('「${event.title}」を削除しますか？'),
                actions: [
                  TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('キャンセル')),
                  TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('削除')),
                ],
              ),
            );
            if (confirmed ?? false) {
              ref.read(eventsProvider.notifier).deleteEvent(event.id);
              Navigator.of(context).pop(); 
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          tooltip: '編集',
          onPressed: () {
            Navigator.of(context).pop(); 
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => EventFormPage(event: event),
              ),
            );
          },
        ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(
      {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}