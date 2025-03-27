import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/screens/myworks/tabbar/listwork_page.dart';
import 'package:teammate/screens/myworks/tabbar/people_page.dart';
import 'package:teammate/screens/myworks/tabbar/post_page.dart';
import 'package:teammate/services/firestore_department_service.dart';

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
  final FirestoreDepartmentService _departmentService =
      FirestoreDepartmentService();

  bool _isLoading = true;
  Map<String, dynamic>? _departmentData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDepartmentData();
  }

  Future<void> _loadDepartmentData() async {
    try {
      final docSnapshot = await _departmentService.getDepartmentById(
        widget.departmentId,
      );
      setState(() {
        _departmentData = docSnapshot.data() as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading department data: $e');
      setState(() => _isLoading = false);
    }
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
        title: Text(
          'MY WORK',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: _buildMinimalTabBar(),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PostPage(
            departmentId: widget.departmentId,
            projectId: widget.projectId,
          ),

          ListWorkPage(
            departmentId: widget.departmentId,
            projectId: widget.projectId,
          ),

          PeoplePage(
            departmentId: widget.departmentId,
            projectId: widget.projectId,
          ),
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
          labelPadding: const EdgeInsets.symmetric(horizontal: 30),
          isScrollable: true,
          tabAlignment: TabAlignment.start,
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
