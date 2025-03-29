import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:teammate/theme/app_colors.dart';

class CreateTaskPage extends StatefulWidget {
  final String departmentId;
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
  bool _isCreating = false;

  // Attachment handling
  final List<String> _attachments = [];

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
              colorScheme: ColorScheme.light(primary: AppColors.primary),
              buttonTheme: const ButtonThemeData(
                textTheme: ButtonTextTheme.primary,
              ),
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
                colorScheme: ColorScheme.light(primary: AppColors.primary),
                buttonTheme: const ButtonThemeData(
                  textTheme: ButtonTextTheme.primary,
                ),
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
    // In a real implementation, you'd use file picker
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Attachment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildAttachmentOption(
                  icon: Icons.insert_drive_file,
                  title: 'Document',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _attachments.add('Document ${_attachments.length + 1}');
                    });
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.image,
                  title: 'Photo/Image',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _attachments.add('Image ${_attachments.length + 1}');
                    });
                  },
                ),
                _buildAttachmentOption(
                  icon: Icons.link,
                  title: 'Link',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _attachments.add('Link ${_attachments.length + 1}');
                    });
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.secondary.withOpacity(0.1),
        child: Icon(icon, color: AppColors.secondary),
      ),
      title: Text(title),
      onTap: onTap,
    );
  }

  Future<void> _createTask() async {
    if (_formKey.currentState!.validate()) {
      // Validate due date
      if (_dueDate == null) {
        _showErrorSnackBar('Please select a due date and time');
        return;
      }

      setState(() {
        _isCreating = true;
      });

      try {
        // Get current user
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) {
          _showErrorSnackBar('User not authenticated');
          setState(() {
            _isCreating = false;
          });
          return;
        }

        // Reference to Firestore collections
        final FirebaseFirestore firestore = FirebaseFirestore.instance;

        // Create task document
        DocumentReference taskRef = firestore.collection('tasks').doc();
        final taskId = taskRef.id; // Get the generated task ID

        // Prepare task data
        Map<String, dynamic> taskData = {
          'taskId': taskId,
          'taskTitle': _titleController.text.trim(),
          'taskDescription': _descriptionController.text.trim(),
          'startTask': Timestamp.now(), // Current timestamp as start
          'endTask': Timestamp.fromDate(_dueDate!),
          'creatorId': currentUser.uid,
          'isSubmit': false,
          'isApproved': false,
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

        // Show success and vibrate
        HapticFeedback.mediumImpact();
        _showSuccessSnackBar('Task created successfully');

        // Navigate back with delay for snackbar visibility
        Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.of(context).pop(taskRef.id);
        });
      } catch (e) {
        setState(() {
          _isCreating = false;
        });
        _showErrorSnackBar('Error creating task: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.errorText,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
        title: const Text(
          'CREATE TASK',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Input with gradient border
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primaryGradientStart,
                          AppColors.primaryGradientEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(1.5), // Border thickness
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Task Title',
                          labelStyle: TextStyle(color: AppColors.labelText),
                          hintText: 'Enter task title',
                          hintStyle: TextStyle(color: AppColors.hintText),
                          prefixIcon: Icon(
                            Icons.title,
                            color: AppColors.secondary,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                            horizontal: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a task title';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description Input with matching style
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.inputBorder),
                      color: AppColors.background,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: AppColors.labelText),
                        hintText: 'Describe the task details (optional)',
                        hintStyle: TextStyle(color: AppColors.hintText),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(bottom: 64),
                          child: Icon(
                            Icons.description,
                            color: AppColors.secondary,
                          ),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Due Date Selection with clean design
                  Text(
                    'Due Date & Time',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDueDateTime,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.inputBorder),
                        borderRadius: BorderRadius.circular(12),
                        color: AppColors.background,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.inputBorder,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_today,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _dueDate == null
                                  ? 'Select a date and time'
                                  : DateFormat(
                                    'EEE, MMM dd, yyyy • HH:mm',
                                  ).format(_dueDate!),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    _dueDate == null
                                        ? FontWeight.normal
                                        : FontWeight.w500,
                                color:
                                    _dueDate == null
                                        ? AppColors.hintText
                                        : Colors.black87,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: AppColors.secondary.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Attachments with improved styling
                  Text(
                    'Attachments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Add attachment button with gradient outline
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient:
                          _attachments.isEmpty
                              ? const LinearGradient(
                                colors: [
                                  AppColors.primaryGradientStart,
                                  AppColors.primaryGradientEnd,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                              : null,
                      border:
                          _attachments.isNotEmpty
                              ? Border.all(color: AppColors.inputBorder)
                              : null,
                    ),
                    padding:
                        _attachments.isEmpty
                            ? const EdgeInsets.all(1.5)
                            : null, // Border thickness
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(
                          _attachments.isEmpty ? 11 : 12,
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _addAttachment,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.attach_file,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Add Attachment',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AppColors.linkText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Display attachments with better styling
                  if (_attachments.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ..._attachments.map(
                      (attachment) => _buildAttachmentItem(attachment),
                    ),
                  ],

                  const SizedBox(height: 40),

                  // Create Task Button with gradient
                  Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: AppColors.buttonColor,
                    ),
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _createTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.buttonText,
                        disabledBackgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child:
                          _isCreating
                              ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Creating task...',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              )
                              : const Text(
                                'CREATE TASK',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentItem(String attachment) {
    IconData iconData;

    if (attachment.startsWith('Document')) {
      iconData = Icons.insert_drive_file;
    } else if (attachment.startsWith('Image')) {
      iconData = Icons.image;
    } else {
      iconData = Icons.link;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: AppColors.secondary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              attachment,
              style: TextStyle(fontSize: 14, color: AppColors.labelText),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.secondary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () {
              setState(() {
                _attachments.remove(attachment);
              });
            },
          ),
        ],
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
