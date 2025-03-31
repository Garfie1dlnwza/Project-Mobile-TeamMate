import 'package:flutter/material.dart';
import 'package:teammate/services/firestore_dataMigration.dart';

class MigrationRunner extends StatefulWidget {
  final Widget child;

  const MigrationRunner({super.key, required this.child});

  @override
  State<MigrationRunner> createState() => _MigrationRunnerState();
}

class _MigrationRunnerState extends State<MigrationRunner> {
  final FirestoreDataMigration _migrationService = FirestoreDataMigration();
  bool _isMigrating = false;
  bool _migrationComplete = false;
  String _migrationStatus = "Not started";
  Map<String, dynamic> _migrationDetails = {};

  @override
  void initState() {
    super.initState();
    _checkMigrationStatus();
  }

  Future<void> _checkMigrationStatus() async {
    try {
      final status = await _migrationService.checkMigrationStatus();

      bool isComplete = true;
      for (final collection in status.keys) {
        if (status[collection]['migrationComplete'] != true) {
          isComplete = false;
          break;
        }
      }

      setState(() {
        _migrationComplete = isComplete;
        _migrationDetails = status;
        _migrationStatus =
            isComplete ? "Migration complete" : "Migration needed";
      });

      if (!isComplete) {
        _showMigrationDialog();
      }
    } catch (e) {
      setState(() {
        _migrationStatus = "Error checking migration status: $e";
      });
    }
  }

  Future<void> _runMigration() async {
    if (_isMigrating) return;

    setState(() {
      _isMigrating = true;
      _migrationStatus = "Migration in progress...";
    });

    try {
      await _migrationService.migrateDataForInteractions();
      await _checkMigrationStatus();
      setState(() {
        _isMigrating = false;
        _migrationStatus = "Migration completed successfully";
      });
    } catch (e) {
      setState(() {
        _isMigrating = false;
        _migrationStatus = "Migration failed: $e";
      });
    }
  }

  void _showMigrationDialog() {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Database Update Required'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your app needs to update the database to support the latest features (comments and reactions).',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status: $_migrationStatus',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            _migrationComplete ? Colors.green : Colors.orange,
                      ),
                    ),
                    if (_migrationDetails.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Details:'),
                      ...(_migrationDetails.entries
                          .map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(
                                left: 8.0,
                                top: 4.0,
                              ),
                              child: Text(
                                '${entry.key}: ${entry.value['migrationComplete'] == true ? '✓' : '✗'}',
                              ),
                            ),
                          )
                          .toList()),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      _isMigrating
                          ? null
                          : () {
                            Navigator.of(context).pop();
                          },
                  child: const Text('Skip'),
                ),
                ElevatedButton(
                  onPressed:
                      _isMigrating
                          ? null
                          : () async {
                            await _runMigration();
                            if (mounted && _migrationComplete) {
                              Navigator.of(context).pop();
                            }
                          },
                  child:
                      _isMigrating
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Text('Update Now'),
                ),
              ],
            ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
