// lib/add_event_screen.dart の全文

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/core/models/event.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();

  // ここから以下の変数の宣言が正しく存在することを確認してください
  DateTime _selectedStartDate = DateTime.now();
  TimeOfDay _selectedStartTime = TimeOfDay.now();
  DateTime _selectedEndDate = DateTime.now();
  TimeOfDay _selectedEndTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

  EventType _selectedEventType = EventType.fixed;
  bool _isPublic = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _selectedStartDate : _selectedEndDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedStartDate = picked;
          if (_selectedEndDate.isBefore(_selectedStartDate)) {
            _selectedEndDate = _selectedStartDate;
          }
        } else {
          _selectedEndDate = picked;
          if (_selectedStartDate.isAfter(_selectedEndDate)) {
            _selectedStartDate = _selectedEndDate;
          }
        }
      });
    }
  }

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _selectedStartTime : _selectedEndTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _selectedStartTime = picked;
        } else {
          _selectedEndTime = picked;
        }
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ログインしていません。')),
      );
      return;
    }

    final DateTime startDateTime = DateTime(
      _selectedStartDate.year,
      _selectedStartDate.month,
      _selectedStartDate.day,
      _selectedStartTime.hour,
      _selectedStartTime.minute,
    );
    final DateTime endDateTime = DateTime(
      _selectedEndDate.year,
      _selectedEndDate.month,
      _selectedEndDate.day,
      _selectedEndTime.hour,
      _selectedEndTime.minute,
    );

    if (endDateTime.isBefore(startDateTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('終了時間は開始時間より後に設定してください。')),
      );
      return;
    }

    final newEvent = Event(
      id: FirebaseFirestore.instance.collection('events').doc().id,
      userId: user.uid,
      title: _titleController.text,
      startTime: startDateTime,
      endTime: endDateTime,
      type: _selectedEventType,
      isPublic: _selectedEventType != EventType.fixed ? _isPublic : false,
    );

    try {
      await FirebaseFirestore.instance
          .collection('events')
          .doc(newEvent.id)
          .set(newEvent.toJson());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('予定が保存されました！')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('予定の保存に失敗しました: $e')),
      );
    }
  }

  // ここから下の build メソッドが正しく存在することを確認してください
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('予定の追加')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '予定タイトル',
                  hintText: '例: ランチ会、打ち合わせ',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'タイトルは必須です';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              ListTile(
                title: Text('開始日時: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime(_selectedStartDate.year, _selectedStartDate.month, _selectedStartDate.day, _selectedStartTime.hour, _selectedStartTime.minute))}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  await _selectDate(context, true);
                  await _selectTime(context, true);
                },
              ),

              ListTile(
                title: Text('終了日時: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime(_selectedEndDate.year, _selectedEndDate.month, _selectedEndDate.day, _selectedEndTime.hour, _selectedEndTime.minute))}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  await _selectDate(context, false);
                  await _selectTime(context, false);
                },
              ),
              const SizedBox(height: 20),

              DropdownButtonFormField<EventType>(
                value: _selectedEventType,
                decoration: const InputDecoration(labelText: '予定のタイプ'),
                items: EventType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.displayName),
                  );
                }).toList(),
                onChanged: (EventType? newValue) {
                  setState(() {
                    _selectedEventType = newValue!;
                    if (_selectedEventType == EventType.fixed) {
                      _isPublic = false;
                    }
                  });
                },
              ),
              const SizedBox(height: 10),

              if (_selectedEventType != EventType.fixed)
                SwitchListTile(
                  title: const Text('公開予定にする'),
                  subtitle: const Text('ONにすると他のユーザーに空き予定として表示されます'),
                  value: _isPublic,
                  onChanged: (bool value) {
                    setState(() {
                      _isPublic = value;
                    });
                  },
                ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: _saveEvent,
                child: const Text('予定を保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}