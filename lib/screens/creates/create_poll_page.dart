import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teammate/services/firestore_noti_service.dart';
import 'package:teammate/services/firestore_poll_service.dart';
import 'package:teammate/theme/app_colors.dart';
import 'package:intl/intl.dart';

class CreatePollPage extends StatefulWidget {
  final String projectId;
  final String departmentId;

  const CreatePollPage({
    super.key,
    required this.projectId,
    required this.departmentId,
  });

  @override
  _CreatePollPageState createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionsControllers = <TextEditingController>[];
  DateTime? _selectedEndDate;
  final FirestorePollService _pollService = FirestorePollService();
  bool _isCreating = false;
  final FirestoreNotificationService _notificationService =
      FirestoreNotificationService();
  // Animation controller
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize with two option fields
    _optionsControllers.add(TextEditingController());
    _optionsControllers.add(TextEditingController());

    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // Start animations
    _animationController.forward();
  }

  void _addOptionField() {
    setState(() {
      _optionsControllers.add(TextEditingController());
    });
  }

  void _removeOptionField(int index) {
    setState(() {
      _optionsControllers.removeAt(index);
    });
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedEndDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  Future<void> _createPoll() async {
    if (_formKey.currentState!.validate()) {
      List<String> options =
          _optionsControllers
              .map((controller) => controller.text.trim())
              .where((option) => option.isNotEmpty)
              .toList();

      if (options.length < 2) {
        _showErrorSnackBar('Please add at least two options');
        return;
      }

      if (_selectedEndDate == null) {
        _showErrorSnackBar('Please select an end date for the poll');
        return;
      }

      setState(() {
        _isCreating = true;
      });

      try {
        String pollId = await _pollService.createPoll(
          projectId: widget.projectId,
          departmentId: widget.departmentId,
          question: _questionController.text.trim(),
          options: options,
          endDate: _selectedEndDate,
        );
        await _notificationService.sendNotificationToDepartmentMembers(
          departmentId: widget.departmentId,
          type: 'poll_created',
          message:
              '${FirebaseAuth.instance.currentUser?.displayName ?? 'A team member'} created a new poll: ${_questionController.text}',
          additionalData: {
            'pollId': pollId,
            'pollQuestion': _questionController.text,
            'creatorName':
                FirebaseAuth.instance.currentUser?.displayName ??
                'A team member',
            'projectId': widget.projectId,
          },
        );
        _showSuccessSnackBar('Poll created successfully');
        Future.delayed(Duration(milliseconds: 1500), () {
          Navigator.pop(context, pollId);
        });
      } catch (e) {
        setState(() {
          _isCreating = false;
        });
        _showErrorSnackBar('Failed to create poll: $e');
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.errorText,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'CREATE POLL',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question section
                _buildLabelText('Question'),
                SizedBox(height: 8),
                _buildInputField(
                  controller: _questionController,
                  hintText: 'Ask something...',
                  icon: Icons.help_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a poll question';
                    }
                    return null;
                  },
                ),

                SizedBox(height: 24),

                // End date section
                _buildLabelText('End Date & Time'),
                SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectEndDate(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.inputBorder.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.event, color: AppColors.secondary, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedEndDate == null
                                ? 'Select when the poll should end'
                                : _formatDateTime(_selectedEndDate!),
                            style: TextStyle(
                              color:
                                  _selectedEndDate == null
                                      ? AppColors.hintText
                                      : AppColors.labelText,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.secondary.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Options section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildLabelText('Options'),
                    TextButton.icon(
                      onPressed: _addOptionField,
                      icon: Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      label: Text(
                        'Add Option',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),

                // Option fields
                ...List.generate(
                  _optionsControllers.length,
                  (index) => _buildOptionField(index),
                ),

                SizedBox(height: 32),

                // Create Poll Button
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.buttonColor,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isCreating ? null : _createPoll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child:
                        _isCreating
                            ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              'CREATE ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabelText(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required FormFieldValidator<String> validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.inputBorder.withOpacity(0.5)),
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: AppColors.hintText),
          prefixIcon: Icon(icon, color: AppColors.secondary, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        style: TextStyle(color: AppColors.labelText, fontSize: 15),
        validator: validator,
      ),
    );
  }

  Widget _buildOptionField(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Option number
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          // Option input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.inputBorder.withOpacity(0.5),
                ),
              ),
              child: TextFormField(
                controller: _optionsControllers[index],
                decoration: InputDecoration(
                  hintText: 'Option ${index + 1}',
                  hintStyle: TextStyle(color: AppColors.hintText),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
                style: TextStyle(color: AppColors.labelText),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Option cannot be empty';
                  }
                  return null;
                },
              ),
            ),
          ),
          // Remove button
          if (_optionsControllers.length > 2)
            IconButton(
              icon: Icon(
                Icons.remove_circle_outline,
                color: AppColors.errorText.withOpacity(0.7),
                size: 20,
              ),
              splashRadius: 20,
              onPressed: () => _removeOptionField(index),
            ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final date = DateFormat('EEE, MMM d, yyyy').format(dateTime);
    final time = DateFormat('h:mm a').format(dateTime);
    return '$date at $time';
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var controller in _optionsControllers) {
      controller.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }
}
