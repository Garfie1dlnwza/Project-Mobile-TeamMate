import 'package:flutter/material.dart';
import 'package:teammate/screens/myworks/listwork_page.dart';
import 'package:teammate/screens/myworks/people_page.dart';
import 'package:teammate/screens/myworks/post_page.dart';

class WorkPageThree extends StatefulWidget {
  final String departmentId;
  final String departmentName;
  final Color color;
  final String projectId;

  const WorkPageThree({
    Key? key,
    required this.departmentId,
    required this.departmentName,
    required this.color,
    required this.projectId,
  }) : super(key: key);

  @override
  State<WorkPageThree> createState() => _WorkPageThreeState();
}

class _WorkPageThreeState extends State<WorkPageThree>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'MY WORK',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: _buildMinimalTabBar(),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                PostPage(),
                ListWorkPage(),
                PeoplePage(
                  projectId: widget.projectId,
                  departmentId: widget.departmentId,
                ),
              ],
            ),
          ),
          // ข้อความ "test" จะไม่แสดงอีกต่อไป
        ],
      ),
    );
  }

  PreferredSizeWidget _buildMinimalTabBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Color.fromARGB(255, 236, 236, 236),
              width: 1,
            ),
            bottom: BorderSide(
              color: Color.fromARGB(255, 236, 236, 236),
              width: 1,
            ),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          dividerColor: Colors.transparent,
          // ลบหรือลดระยะห่างระหว่าง tab ให้น้อยที่สุด
          labelPadding: EdgeInsets.symmetric(horizontal: 30),
          isScrollable: true,
          tabAlignment: TabAlignment.start, // ทำให้ tab กระจายเต็มความกว้าง
          tabs: const [
            Tab(text: 'Post'),
            Tab(text: 'Work'),
            Tab(text: 'People'),
          ],
        ),
      ),
    );
  }
}
