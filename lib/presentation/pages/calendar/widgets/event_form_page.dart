// lib/presentation/pages/calendar/widgets/event_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sukekenn/application/providers/event_provider.dart';
import 'package:sukekenn/core/models/event.dart';
import 'package:uuid/uuid.dart';

class EventFormPage extends ConsumerStatefulWidget {
  final Event? event;
  const EventFormPage({super.key, this.event});

  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _startTime = widget.event?.startTime ?? DateTime.now();
    _endTime = widget.event?.endTime ?? DateTime.now().add(const Duration(hours: 1));
  }

  @override
  void dispose(){
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final eventNotifier = ref.read(eventsProvider.notifier);
      if (widget.event == null) {
        // 新規作成
        eventNotifier.addEvent(
          Event(
            id: const Uuid().v4(),
            ownerId: 'currentUser', // TODO: 実際のユーザーIDに置き換え
            title: _titleController.text,
            startTime: _startTime,
            endTime: _endTime,
            type: EventType.anyone,
          ),
        );
      } else {
        // 更新
        eventNotifier.updateEvent(
          widget.event!.copyWith(
            title: _titleController.text,
            startTime: _startTime,
            endTime: _endTime,
          ),
        );
      }
      if(mounted){
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? '予定の追加' : '予定の編集'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _submit,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'タイトル'),
              validator: (value) =>
                  value!.isEmpty ? 'タイトルを入力してください' : null,
            ),
            // TODO: 日時選択などのUIをここに追加
          ],
        ),
      ),
    );
  }
}