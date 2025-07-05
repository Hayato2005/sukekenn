import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sukekenn/models/schedule_model.dart';

// クイック登録時に表示するヘッダー部分
class ScheduleSheetHeader extends StatefulWidget {
  final Schedule schedule;
  final Function(String) onTitleChanged;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onTapHeader;

  const ScheduleSheetHeader({
    super.key,
    required this.schedule,
    required this.onTitleChanged,
    required this.onClose,
    required this.onSave,
    required this.onTapHeader,
  });

  @override
  State<ScheduleSheetHeader> createState() => _ScheduleSheetHeaderState();
}

class _ScheduleSheetHeaderState extends State<ScheduleSheetHeader> {
  late final TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.schedule.title);
  }

  @override
  void didUpdateWidget(covariant ScheduleSheetHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(widget.schedule.title != oldWidget.schedule.title && widget.schedule.title != _titleController.text) {
      _titleController.text = widget.schedule.title;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        height: kToolbarHeight + 10,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: widget.onClose,
            ),
            Expanded(
              child: GestureDetector(
                 onTap: widget.onTapHeader,
                 child: AbsorbPointer(
                   child: TextField(
                     controller: _titleController,
                     focusNode: _titleFocusNode,
                     decoration: const InputDecoration.collapsed(hintText: '予定のタイトル'),
                     onChanged: widget.onTitleChanged,
                   ),
                 ),
              ),
            ),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _titleController,
              builder: (context, value, child) {
                return TextButton(
                  onPressed: value.text.trim().isEmpty ? null : widget.onSave,
                  child: const Text('登録'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


// フル表示用のモーダルシート本体
class ScheduleCreationSheet extends StatefulWidget {
  final Schedule schedule;
  final ScrollController scrollController;

  const ScheduleCreationSheet({
    super.key,
    required this.schedule,
    required this.scrollController,
  });

  @override
  State<ScheduleCreationSheet> createState() => _ScheduleCreationSheetState();
}

class _ScheduleCreationSheetState extends State<ScheduleCreationSheet> {
  late Schedule _currentSchedule;
  late TextEditingController _titleController;
  final FocusNode _titleFocusNode = FocusNode();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentSchedule = widget.schedule;
    _titleController = TextEditingController(text: _currentSchedule.title);

    // ★★★★★ 修正点 ★★★★★
    // シートがドラッグで閉じられたことを検知するリスナー
    widget.scrollController.addListener(_onScroll);
  }
  
  // ★★★★★ 修正点 ★★★★★
  void _onScroll() {
    // DraggableScrollableSheetが下にドラッグされて閉じる寸前の挙動を検知
    if (widget.scrollController.position.atEdge && widget.scrollController.position.pixels == 0) {
      // isSwitchingToQuickModeフラグを立てて、編集中のデータを返す
      final result = {
        'isSwitchingToQuickMode': true,
        'savedSchedule': _currentSchedule.copyWith(title: _titleController.text.trim()),
      };
      // 多重実行を防ぐためにリスナーを解除
      widget.scrollController.removeListener(_onScroll);
      Navigator.pop(context, result);
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _titleController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }
  
  void _saveSchedule() async {
    if (_titleController.text.trim().isEmpty || _isSaving) return;
    setState(() => _isSaving = true);
    final finalSchedule = _currentSchedule.copyWith(title: _titleController.text.trim());
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) Navigator.pop(context, {'savedSchedule': finalSchedule});
  }

  void _deleteSchedule() {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('予定の削除'),
          content: const Text('この予定を完全に削除しますか？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context, {'isDeleted': true, 'savedSchedule': _currentSchedule});
              },
              child: const Text('削除', style: TextStyle(color: Colors.red))
            ),
          ],
        )
      );
  }
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      clipBehavior: Clip.antiAlias,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          controller: widget.scrollController,
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).cardColor,
              elevation: 1,
              leading: IconButton(
                icon: const Icon(Icons.close),
                tooltip: '閉じる',
                onPressed: () => Navigator.pop(context),
              ),
              title: TextField(
                controller: _titleController,
                focusNode: _titleFocusNode,
                decoration: const InputDecoration.collapsed(hintText: '予定のタイトル'),
                onChanged: (text) => setState(() {
                   _currentSchedule = _currentSchedule.copyWith(title: text);
                }),
                textInputAction: TextInputAction.done,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _titleController,
                    builder: (context, value, child) {
                      return TextButton(
                        onPressed: value.text.trim().isEmpty || _isSaving ? null : _saveSchedule,
                        child: _isSaving 
                          ? const SizedBox(width:20, height:20, child: CircularProgressIndicator(strokeWidth: 2,)) 
                          : const Text('登録'),
                      );
                    },
                  ),
                )
              ],
            ),
            SliverList(delegate: SliverChildListDelegate(
              [
                _FullDisplayContent(
                  schedule: _currentSchedule,
                  onChanged: (newSchedule) {
                    setState(() => _currentSchedule = newSchedule);
                  },
                  onDelete: _deleteSchedule,
                )
              ]
            )),
          ],
        ),
      ),
    );
  }
}


// フル表示モードの詳細入力エリア
class _FullDisplayContent extends StatelessWidget {
  final Schedule schedule;
  final Function(Schedule) onChanged;
  final VoidCallback onDelete;

  const _FullDisplayContent({
    required this.schedule,
    required this.onChanged,
    required this.onDelete,
  });
  
  DateTime? _getDateTimeFromHour(double hour) {
    final date = schedule.date;
    if (date == null) return null;
    final baseDate = DateTime(date.year, date.month, date.day);
    return baseDate.add(Duration(minutes: (hour * 60).round()));
  }

  @override
  Widget build(BuildContext context) {
    final startDateTime = _getDateTimeFromHour(schedule.startHour);
    final endDateTime = _getDateTimeFromHour(schedule.endHour);
    bool isEditing = !schedule.id.startsWith('temporary');

    Future<void> pickStartTime() async {
      if(startDateTime == null) return;
      final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(startDateTime));
      if (picked != null) {
        final duration = endDateTime!.difference(startDateTime);
        final newStartDateTime = DateTime(schedule.date!.year, schedule.date!.month, schedule.date!.day, picked.hour, picked.minute);
        final newEndDateTime = newStartDateTime.add(duration);
        onChanged(schedule.copyWith(
          startHour: newStartDateTime.hour + newStartDateTime.minute / 60.0,
          endHour: newEndDateTime.hour + newEndDateTime.minute / 60.0,
        ));
      }
    }

    Future<void> pickEndTime() async {
      if(endDateTime == null || startDateTime == null) return;
      final picked = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(endDateTime));
      if (picked != null) {
        final newEndDateTime = DateTime(schedule.date!.year, schedule.date!.month, schedule.date!.day, picked.hour, picked.minute);
        if (newEndDateTime.isBefore(startDateTime) || newEndDateTime.isAtSameMomentAs(startDateTime)) {
          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('終了時刻は開始時刻より後に設定してください。')));
          return;
        }
        onChanged(schedule.copyWith(endHour: picked.hour + picked.minute / 60.0));
      }
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          Center(
            child: SegmentedButton<ScheduleType>(
              segments: const [
                ButtonSegment(value: ScheduleType.available, label: Text('空き日程'), icon: Icon(Icons.people_outline)),
                ButtonSegment(value: ScheduleType.fixed, label: Text('固定予定'), icon: Icon(Icons.lock_outline)),
              ],
              selected: {schedule.scheduleType},
              onSelectionChanged: (newSelection) => onChanged(schedule.copyWith(scheduleType: newSelection.first)),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.calendar_today_outlined),
            title: Text(schedule.date != null ? DateFormat('y年M月d日 (E)', 'ja').format(schedule.date!) : '日付未設定'),
            onTap: () async {
              final picked = await showDatePicker(context: context, initialDate: schedule.date ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
              if (picked != null) onChanged(schedule.copyWith(date: picked));
            },
          ),
          if (!schedule.isAllDay)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(onPressed: pickStartTime, child: Text(startDateTime != null ? DateFormat('HH:mm').format(startDateTime) : '--:--', style: Theme.of(context).textTheme.headlineSmall)),
                const Text('〜', style: TextStyle(fontSize: 20)),
                TextButton(onPressed: pickEndTime, child: Text(endDateTime != null ? DateFormat('HH:mm').format(endDateTime) : '--:--', style: Theme.of(context).textTheme.headlineSmall)),
              ],
            ),
          CheckboxListTile(
            title: const Text('終日'),
            value: schedule.isAllDay,
            onChanged: (val) => onChanged(schedule.copyWith(isAllDay: val ?? false)),
            secondary: const Icon(Icons.wb_sunny_outlined),
          ),
          const Divider(),
          if (schedule.scheduleType == ScheduleType.available) ...[
            ListTile(
              leading: const Icon(Icons.how_to_reg_outlined),
              title: const Text('マッチングタイプ'),
              trailing: DropdownButton<MatchingType>(
                value: schedule.matchingType,
                items: MatchingType.values.map((MatchingType value) {
                  return DropdownMenuItem<MatchingType>(value: value, child: Text(value.displayName));
                }).toList(),
                onChanged: (MatchingType? newValue) {
                  if (newValue != null) onChanged(schedule.copyWith(matchingType: newValue));
                },
              ),
            ),
            SwitchListTile(
              title: const Text('公開する'),
              subtitle: const Text('OFFにすると検索結果に表示されません'),
              value: schedule.isPublic,
              onChanged: (val) => onChanged(schedule.copyWith(isPublic: val)),
              secondary: const Icon(Icons.visibility_outlined),
            ),
            const Divider(),
          ],
          ListTile(
            leading: const Icon(Icons.group_add_outlined),
            title: const Text('招待するメンバーを追加...'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () { /* TODO: 招待ポップアップ表示 */ },
          ),
          ListTile(
            leading: const Icon(Icons.tune_outlined),
            title: const Text('詳細設定...'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () { /* TODO: 詳細設定ポップアップ表示 */ },
          ),
          if (isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 32.0, bottom: 32.0),
                child: Center(
                  child: TextButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('この予定を削除する'),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}