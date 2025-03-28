import 'package:flutter/material.dart';
import 'package:flutter_polls/flutter_polls.dart';
import 'package:teammate/services/firestore_poll_service.dart';

class CreatePollPage extends StatefulWidget {
  final String projectId;
  final String departmentId;

  const CreatePollPage({
    Key? key,
    required this.projectId,
    required this.departmentId,
  }) : super(key: key);

  @override
  _CreatePollPageState createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionsControllers = <TextEditingController>[];
  DateTime? _selectedEndDate;
  final FirestorePollService _pollService = FirestorePollService();

  @override
  void initState() {
    super.initState();
    // Initialize with two option fields
    _optionsControllers.add(TextEditingController());
    _optionsControllers.add(TextEditingController());
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
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedEndDate) {
      setState(() {
        _selectedEndDate = picked;
      });
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please add at least two options')),
        );
        return;
      }

      try {
        String pollId = await _pollService.createPoll(
          projectId: widget.projectId,
          departmentId: widget.departmentId,
          question: _questionController.text.trim(),
          options: options,
          endDate: _selectedEndDate,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Poll created successfully with ID: $pollId')),
        );

        Navigator.pop(context, pollId);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create poll: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Create New Poll',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Question Input
              TextFormField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Poll Question',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.help_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a poll question';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // End Date Picker
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedEndDate == null
                          ? 'Select Poll End Date'
                          : 'End Date: ${_selectedEndDate!.toLocal()}'.split(
                            ' ',
                          )[0],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () => _selectEndDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dynamic Poll Options
              const Text(
                'Poll Options',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ...List.generate(
                _optionsControllers.length,
                (index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _optionsControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Option ${index + 1}',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            prefixIcon: const Icon(Icons.ballot_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Option cannot be empty';
                            }
                            return null;
                          },
                        ),
                      ),
                      if (_optionsControllers.length > 2)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () => _removeOptionField(index),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Add Option Button
              OutlinedButton.icon(
                onPressed: _addOptionField,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Another Option',
                  style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                ),
              ),
              const SizedBox(height: 16),

              // Create Poll Button
              ElevatedButton(
                onPressed: _createPoll,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Create Poll',
                  style: TextStyle(fontSize: 18, color: Colors.white),
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
    _questionController.dispose();
    for (var controller in _optionsControllers) {
      controller.dispose();
    }
    super.dispose();
  }
}
