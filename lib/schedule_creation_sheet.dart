import 'package:flutter/material.dart';
import 'package:sukekenn/models/schedule_model.dart';
import 'package:sukekenn/repositories/schedule_repository.dart';

class ScheduleCreationSheet extends StatefulWidget {
  final ScrollController controller;
  final Function(Schedule) onSave;

  const ScheduleCreationSheet({
    super.key,
    required this.controller,
    required this.onSave,
  });

  @override
  State<ScheduleCreationSheet> createState() => _ScheduleCreationSheetState();
}

class _ScheduleCreationSheetState extends State<ScheduleCreationSheet> {
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  DateTime _selectedDate = DateTime.now();
  Color _selectedColor = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('予定作成'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blue),
            onPressed: _saveSchedule,
          ),
        ],
      ),
      body: ListView(
        controller: widget.controller,
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 24),
            decoration: const InputDecoration(labelText: 'タイトル'),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('日付'),
            subtitle: Text('${_selectedDate.year}/${_selectedDate.month}/${_selectedDate.day}'),
            onTap: _pickDate,
          ),
          ListTile(
            title: const Text('開始時間'),
            subtitle: Text(_startTime.format(context)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _startTime);
              if (picked != null) setState(() => _startTime = picked);
            },
          ),
          ListTile(
            title: const Text('終了時間'),
            subtitle: Text(_endTime.format(context)),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _endTime);
              if (picked != null) setState(() => _endTime = picked);
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('色:'),
              const SizedBox(width: 8),
              ...[Colors.blue, Colors.green, Colors.orange].map((color) => GestureDetector(
                onTap: () => setState(() => _selectedColor = color),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: CircleAvatar(backgroundColor: color, radius: 12),
                ),
              )),
            ],
          ),
        ],
      ),
    );
  }

  void _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveSchedule() {
    final newSchedule = Schedule(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.isEmpty ? '無題' : _titleController.text,
      date: _selectedDate,
      startHour: _startTime.hour + _startTime.minute / 60,
      endHour: _endTime.hour + _endTime.minute / 60,
      color: _selectedColor,
    );

    ScheduleRepository().addSchedule(newSchedule);
    widget.onSave(newSchedule);
    Navigator.of(context).pop();
  }
}
