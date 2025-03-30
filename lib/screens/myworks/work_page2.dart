import 'package:flutter/material.dart';
import 'package:teammate/widgets/common/card/card_ongoingTask.dart';
import 'package:teammate/widgets/common/dialog/dialog_addAdmin.dart';
import 'package:teammate/widgets/common/card/card_departments.dart';


class WorkPageTwo extends StatefulWidget {
  final String title;
  final Map<String, dynamic> data;

  const WorkPageTwo({super.key, required this.title, required this.data});

  @override
  State<WorkPageTwo> createState() => _WorkPageTwoState();
}

class _WorkPageTwoState extends State<WorkPageTwo> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AddAdminDialog(data: widget.data),
              );
            },
            child: Image.asset('assets/images/plus_icon.png'),
          ),
          const SizedBox(width: 16.0),
          Image.asset('assets/images/noti.png'),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(0, 0, 20, 0),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(20, 40, 0, 0),
        child: Column(
          children: [
            // Departments Section
            Row(
              children: [
                Container(
                  height: 50,
                  width: 8.5,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 160, 164, 168),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  'Departments',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CardDepartments(data: widget.data),
            const SizedBox(height: 20),

            // Ongoing Tasks Section
            Row(
              children: [
                Container(
                  height: 50,
                  width: 8.5,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 160, 164, 168),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(width: 15),
                Text(
                  'Ongoing Tasks',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Added the CardOngoingTasks widget
            CardOngoingTasks(data: widget.data),
          ],
        ),
      ),
    );
  }
}
