import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teammate/services/firestore_task_service.dart';
import 'package:teammate/theme/app_colors.dart';

class Calendar extends StatefulWidget {
  const Calendar({super.key});
  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  FirestoreTaskService _taskService = FirestoreTaskService();
  int currentYear = DateTime.now().year;
  late List<Map<String, dynamic>> monthsWithDays;

  @override
  void initState() {
    super.initState();
    monthsWithDays = getMonthsWithDays(currentYear);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: buildCard(monthsWithDays),
    );
  }

  Widget buildCard(List<Map<String, dynamic>> monthsData) {
    int currentMonth = DateTime.now().month - 1;
    int currentDay = DateTime.now().day;
    int daysInMonth = monthsData[currentMonth]['days'];

    return Row(
      children: List.generate(daysInMonth, (index) {
        int day = index + 1;

        bool isToday = day == currentDay;
        bool isPast = day < currentDay;
        bool isYesterday = day == currentDay - 1;

        final date = DateTime(currentYear, currentMonth + 1, day);
        final dayName = DateFormat(
          'E',
        ).format(date).toUpperCase().substring(0, 3);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: cardDate(day, dayName, isToday, isPast, isYesterday),
        );
      }),
    );
  }

  Widget cardDate(
    int day,
    String dayName,
    bool isToday,
    bool isPast,
    bool isYesterday,
  ) {
    // Determine card color based on date status
    Color cardColor;
    if (isToday) {
      cardColor = Colors.green;
    } else if (isPast) {
      cardColor = Colors.grey.shade300; // Gray for past days
    } else {
      cardColor = Colors.white; // White for future days
    }

    Color dayNameColor =
        isToday
            ? const Color.fromARGB(255, 255, 255, 255)
            : AppColors.secondary;
    Color dayNumberColor = isToday ? Colors.white : AppColors.labelText;

    // Add border for white cards to make them visible
    BoxBorder? border =
        cardColor == Colors.white
            ? Border.all(color: Colors.grey.shade200, width: 1.5)
            : null;

    return Card(
      shadowColor: Colors.transparent,
      color: cardColor,
      elevation: isToday ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 90,
        width: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: border,
        ),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                color: dayNameColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Text(
                day.toString(),
                style: TextStyle(
                  color: dayNumberColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
            ),
            if (isToday)
              Container(
                width: 5,
                height: 5,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

List<Map<String, dynamic>> getMonthsWithDays(int year) {
  bool isLeapYear = (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);

  return [
    {'month': 'January', 'days': 31},
    {'month': 'February', 'days': isLeapYear ? 29 : 28},
    {'month': 'March', 'days': 31},
    {'month': 'April', 'days': 30},
    {'month': 'May', 'days': 31},
    {'month': 'June', 'days': 30},
    {'month': 'July', 'days': 31},
    {'month': 'August', 'days': 31},
    {'month': 'September', 'days': 30},
    {'month': 'October', 'days': 31},
    {'month': 'November', 'days': 30},
    {'month': 'December', 'days': 31},
  ];
}
