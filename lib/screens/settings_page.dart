import 'package:flutter/material.dart';

import 'package:teammate/widgets/common/header_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  final String title;
  final VoidCallback? onThemeToggle;

  const SettingsPage({Key? key, required this.title, this.onThemeToggle})
    : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = false;
  Image userImage = Image.network(
    FirebaseAuth.instance.currentUser?.photoURL ??
        'https://example.com/default.png', // รูป default
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headbar(title: widget.title),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              fit: BoxFit.cover, // ปรับให้รูปเต็มพื้นที่
                              image:
                                  FirebaseAuth.instance.currentUser?.photoURL !=
                                          null
                                      ? NetworkImage(
                                        FirebaseAuth
                                            .instance
                                            .currentUser!
                                            .photoURL!,
                                      )
                                      : AssetImage('assets/images/default.png')
                                          as ImageProvider,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () {
                              // Add profile picture edit functionality
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      FirebaseAuth.instance.currentUser!.displayName.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Account Setting section
              const Text(
                "Account Setting",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildSettingItem("Edit Name", Icons.arrow_forward_ios, () {
                _navigateToEditName(context);
              }),
              const Divider(),
              _buildSettingItem("Change Password", Icons.arrow_forward_ios, () {
                _navigateToChangePassword(context);
              }),
              const Divider(),
              _buildSettingItem(
                "Security & Privacy",
                Icons.arrow_forward_ios,
                () {
                  _navigateToSecurityPrivacy(context);
                },
              ),
              const Divider(),

              const SizedBox(height: 32),

              // Theme & Language section
              const Text(
                "Theme & Language",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildThemeToggle(),
              const Divider(),
              _buildSettingItem("Language", Icons.arrow_forward_ios, () {
                _navigateToLanguageSettings(context);
              }),
              const Divider(),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    IconData iconData,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 16)),
            Icon(iconData, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Theme", style: TextStyle(fontSize: 16)),
          Switch(
            value: _isDarkMode,
            onChanged: (value) async {
              setState(() {
                _isDarkMode = value;
              });

              // Toggle theme in app
              if (widget.onThemeToggle != null) {
                widget.onThemeToggle!();
              }
            },
          ),
        ],
      ),
    );
  }

  void _navigateToEditName(BuildContext context) {
    // Implementation for edit name navigation
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Name'),
            content: TextField(
              decoration: const InputDecoration(hintText: 'Enter new name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Implement name update logic
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _navigateToChangePassword(BuildContext context) {
    // Implementation for change password navigation
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Current password',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(hintText: 'New password'),
                ),
                const SizedBox(height: 8),
                TextField(
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: 'Confirm new password',
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  // Implement password change logic
                  Navigator.pop(context);
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  void _navigateToSecurityPrivacy(BuildContext context) {
    // For now, show a simple dialog
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Security & Privacy'),
            content: const Text(
              'Security and privacy settings will be implemented here.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _navigateToLanguageSettings(BuildContext context) {
    // For now, show a simple dialog with language options
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Language'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text('English'),
                  onTap: () {
                    // Implement language change logic
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  title: const Text('Thai'),
                  onTap: () {
                    // Implement language change logic
                    Navigator.pop(context);
                  },
                ),
                // Add more languages as needed
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
    );
  }
}
