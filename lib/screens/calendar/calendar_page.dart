import 'package:flutter/material.dart';
import 'package:teammate/widgets/common/calendar.dart';
import 'package:teammate/widgets/common/daily.dart';

import 'package:teammate/widgets/common/header_bar.dart';

class CalendarPage extends StatefulWidget {
  final String title;
  const CalendarPage({super.key, required this.title});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDate;
  final Color _themeColor = Colors.blue; // You can customize this

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headbar(title: widget.title),
      body: Column(
        children: [
          // Date selector at the top
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
            child: Calendar(
              selectedDate: _selectedDate,
              onDateSelect: (date) {
                setState(() {
                  _selectedDate = date;
                });
              },
            ),
          ),

          // Divider between calendar and schedule
          Divider(color: Colors.grey[300], height: 1),

          // Daily schedule view (time slots with events)
          Expanded(
            child: DailySchedule(
              selectedDate: _selectedDate,
              themeColor: _themeColor,
            ),
          ),
        ],
      ),
    );
  }
}
