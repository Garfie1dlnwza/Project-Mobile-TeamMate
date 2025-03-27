import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CreateTaskPage extends StatefulWidget {
  final String departmentId; // Pass the department ID when creating the page
  final String projectId;
  const CreateTaskPage({
    super.key,
    required this.projectId,
    required this.departmentId,
  });

  @override
  _CreateTaskPageState createState() => _CreateTaskPageState();
}

class _CreateTaskPageState extends State<CreateTaskPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // Date and Time
  DateTime? _dueDate;

  // Attachment handling
  List<String> _attachments = [];

  void _selectDueDateTime() async {
    // Date selection
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder:
          (context, child) => Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(primary: Colors.black),
            ),
            child: child!,
          ),
    );

    if (pickedDate != null) {
      // Time selection
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder:
            (context, child) => Theme(
              data: ThemeData.light().copyWith(
                colorScheme: ColorScheme.light(primary: Colors.black),
              ),
              child: child!,
            ),
      );

      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _addAttachment() {
    // Placeholder for attachment logic
    // You might want to implement file picking
    setState(() {
      _attachments.add('Attachment ${_attachments.length + 1}');
    });
  }

  Future<void> _createTask() async {
    if (_formKey.currentState!.validate()) {
      // Validate due date
      if (_dueDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a due date and time')),
        );
        return;
      }

      try {
        // Get current user
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('User not authenticated')));
          return;
        }

        // Reference to Firestore collections
        final FirebaseFirestore firestore = FirebaseFirestore.instance;

        // Create task document
        DocumentReference taskRef = firestore.collection('tasks').doc();

        // Prepare task data
        Map<String, dynamic> taskData = {
          'taskTitle': _titleController.text.trim(),
          'taskDescription': _descriptionController.text.trim(),
          'startTask': Timestamp.now(), // Current timestamp as start
          'endTask': Timestamp.fromDate(_dueDate!),
          'creatorId': currentUser.uid,
          'isSubmit': false,
          'attachments': _attachments,
          'createdAt': FieldValue.serverTimestamp(),
          'departmentId': widget.departmentId, // Add department ID
        };

        // Save task to Firestore
        await taskRef.set(taskData);

        // Add task ID to department's tasks array
        await firestore
            .collection('departments')
            .doc(widget.departmentId)
            .update({
              'tasks': FieldValue.arrayUnion([taskRef.id]),
            });

        // Show success and pop the page
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Task created successfully')));
        Navigator.of(context).pop(taskRef.id);
      } catch (e) {
        // Handle any errors
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error creating task: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Create Work',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Title Input
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.title, color: Colors.black),
                  hintText: 'Work title (required)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a work title';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Description Input
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.description, color: Colors.black),
                  hintText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              SizedBox(height: 16),

              // Attachment Button
              ElevatedButton.icon(
                onPressed: _addAttachment,
                icon: Icon(Icons.attachment),
                label: Text(
                  'Add Attachment',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 95, 90, 90),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // Display attachments
              if (_attachments.isNotEmpty)
                Column(
                  children:
                      _attachments
                          .map(
                            (attachment) => ListTile(
                              title: Text(attachment),
                              trailing: IconButton(
                                icon: Icon(Icons.close),
                                onPressed: () {
                                  setState(() {
                                    _attachments.remove(attachment);
                                  });
                                },
                              ),
                            ),
                          )
                          .toList(),
                ),
              SizedBox(height: 16),

              // Due Date Selection
              GestureDetector(
                onTap: _selectDueDateTime,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.black),
                      SizedBox(width: 16),
                      Text(
                        _dueDate == null
                            ? 'Set due date'
                            : DateFormat('MM/dd/yyyy HH:mm').format(_dueDate!),
                        style: TextStyle(
                          color: _dueDate == null ? Colors.grey : Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // Create Work Button
              ElevatedButton(
                onPressed: _createTask,
                child: Text('Create Work'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
