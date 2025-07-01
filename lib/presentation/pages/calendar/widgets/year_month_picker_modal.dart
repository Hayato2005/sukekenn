// lib/presentation/pages/calendar/widgets/year_month_picker_modal.dart
import 'package:flutter/material.dart';

class YearMonthPickerModal extends StatefulWidget {
  final DateTime initialDate;

  const YearMonthPickerModal({super.key, required this.initialDate});

  @override
  State<YearMonthPickerModal> createState() => _YearMonthPickerModalState();
}

class _YearMonthPickerModalState extends State<YearMonthPickerModal> {
  late int selectedYear;
  late int selectedMonth;

  @override
  void initState() {
    super.initState();
    selectedYear = widget.initialDate.year;
    selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  final newDate = DateTime(selectedYear, selectedMonth);
                  Navigator.of(context).pop(newDate);
                },
                child: const Text('完了'),
              ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 50,
                    onSelectedItemChanged: (index) =>
                        selectedYear = 2020 + index,
                    controller: FixedExtentScrollController(
                        initialItem: selectedYear - 2020),
                    physics: const FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) =>
                          Center(child: Text('${2020 + index}年')),
                      childCount: 11, // 2020-2030
                    ),
                  ),
                ),
                Expanded(
                  child: ListWheelScrollView.useDelegate(
                    itemExtent: 50,
                    onSelectedItemChanged: (index) => selectedMonth = index + 1,
                    controller:
                        FixedExtentScrollController(initialItem: selectedMonth - 1),
                    physics: const FixedExtentScrollPhysics(),
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) =>
                          Center(child: Text('${index + 1}月')),
                      childCount: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}