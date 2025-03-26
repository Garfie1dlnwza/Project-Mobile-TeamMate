import 'package:flutter/material.dart';
import 'package:teammate/screens/myworks/add_admin_page.dart';
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) =>
                          AddAdminPage(title: 'ADD ADMIN', data: widget.data),
                ),
              );
              print(widget.data);
            },
            child: Image.asset('assets/images/plus_icon.png'),
          ),
          const SizedBox(width: 16.0),
          Image.asset('assets/images/noti.png'),
        ],
        actionsPadding: EdgeInsets.fromLTRB(0, 0, 20, 0),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(20, 40, 0, 0),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 50,
                  width: 8.5,
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                SizedBox(width: 15),
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
            SizedBox(height: 20),
            CardDepartments(data: widget.data),
            SizedBox(height: 20),
            Row(
              children: [
                Container(
                  height: 50,
                  width: 8.5,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 249, 72, 255),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),

                SizedBox(width: 15),
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
            // CardOngoingTasks(data: widget.data),
          ],
        ),
      ),
    );
  }
}
