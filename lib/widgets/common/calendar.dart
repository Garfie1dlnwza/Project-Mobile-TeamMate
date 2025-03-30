import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:teammate/services/firestore_task_service.dart';
import 'package:teammate/theme/app_colors.dart';

class Calendar extends StatefulWidget {
  final Function(DateTime)? onDateSelect;
  final DateTime? selectedDate;

  const Calendar({super.key, this.onDateSelect, this.selectedDate});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  final FirestoreTaskService _taskService = FirestoreTaskService();
  int currentYear = DateTime.now().year;
  late List<Map<String, dynamic>> monthsWithDays;
  late DateTime _selectedDate;
  int currentMonth = DateTime.now().month - 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    monthsWithDays = getMonthsWithDays(currentYear);
    _selectedDate = widget.selectedDate ?? DateTime.now();

    // ทำการเลื่อนไปที่วันที่ต้องการหลังจาก widget ถูกสร้าง
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTargetDay();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ฟังก์ชันสำหรับเลื่อนไปที่วันที่ต้องการ
  void _scrollToTargetDay() {
    // กำหนดวันที่ต้องการเลื่อนไป (วันปัจจุบัน)
    int targetDay = DateTime.now().day;
    int daysInMonth = monthsWithDays[currentMonth]['days'];

    // แต่ละวันมีความกว้าง 60 pixel + padding 12 pixel (6x2)
    double itemWidth = 72.0; // 60 + 12
    double screenWidth = MediaQuery.of(context).size.width;

    // จำนวนวันที่แสดงได้ในหน้าจอ
    int visibleDays = (screenWidth / itemWidth).floor();

    // คำนวณจุดกึ่งกลางของหน้าจอ
    double centerOffset = screenWidth / 2;

    // ตำแหน่งที่ต้องเลื่อนไป
    double targetOffset;

    // ในกรณีปกติ - ให้วันที่เลือกอยู่ตรงกลาง
    targetOffset = (targetDay - 1) * itemWidth - centerOffset + (itemWidth / 2);

    // สำหรับวันที่อยู่ใกล้ต้นเดือน
    if (targetDay <= visibleDays / 2) {
      targetOffset = 0; // เริ่มต้นที่วันแรกของเดือน
    }

    // สำหรับวันที่อยู่ใกล้ท้ายเดือน
    if (targetDay > daysInMonth - (visibleDays / 2)) {
      // คำนวณตำแหน่งสุดท้ายที่แสดงวันสุดท้ายของเดือน
      double maxOffset = (daysInMonth * itemWidth) - screenWidth;
      targetOffset = maxOffset > 0 ? maxOffset : 0;
    }

    // ปรับให้ไม่เลื่อนติดลบ
    if (targetOffset < 0) {
      targetOffset = 0;
    }

    // เลื่อนไปยังตำแหน่งที่คำนวณได้
    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      child: buildCard(monthsWithDays),
    );
  }

  Widget buildCard(List<Map<String, dynamic>> monthsData) {
    int currentDay = DateTime.now().day;
    int daysInMonth = monthsData[currentMonth]['days'];

    return Row(
      children: List.generate(daysInMonth, (index) {
        int day = index + 1;
        final date = DateTime(currentYear, currentMonth + 1, day);

        bool isToday =
            day == currentDay &&
            date.month == DateTime.now().month &&
            date.year == DateTime.now().year;

        bool isSelected =
            day == _selectedDate.day &&
            date.month == _selectedDate.month &&
            date.year == _selectedDate.year;

        bool isPast = date.isBefore(DateTime.now()) && !isToday;
        bool isYesterday =
            day == currentDay - 1 &&
            date.month == DateTime.now().month &&
            date.year == DateTime.now().year;

        final dayName = DateFormat(
          'E',
        ).format(date).toUpperCase().substring(0, 3);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });

              if (widget.onDateSelect != null) {
                widget.onDateSelect!(date);
              }
            },
            child: cardDate(
              day,
              dayName,
              isToday,
              isPast,
              isYesterday,
              isSelected,
            ),
          ),
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
    bool isSelected,
  ) {
    // Determine card color based on date status
    Color cardColor;
    if (isSelected && !isToday) {
      cardColor = AppColors.buttonColor;
    } else if (isToday) {
      cardColor = isSelected ? Colors.green.shade600 : Colors.green;
    } else if (isPast) {
      cardColor = Colors.grey.shade300; // Gray for past days
    } else {
      cardColor = Colors.white; // White for future days
    }

    Color dayNameColor =
        (isToday || isSelected) ? Colors.white : AppColors.secondary;

    Color dayNumberColor =
        (isToday || isSelected) ? Colors.white : AppColors.labelText;

    // Add border for white cards to make them visible
    BoxBorder? border =
        cardColor == Colors.white
            ? Border.all(color: Colors.grey.shade200, width: 1.5)
            : null;

    return Card(
      shadowColor: Colors.transparent,
      color: cardColor,
      elevation: (isToday || isSelected) ? 4 : 2,
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
            if (isToday || isSelected)
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
