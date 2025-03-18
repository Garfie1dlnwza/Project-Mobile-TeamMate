import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:teammate/storage/supabase_service.dart';
import 'package:teammate/screens/settings/securityprivacy_dialog.dart';
import 'package:teammate/widgets/common/build_setting_item.dart';
import 'package:teammate/widgets/common/card/card_editprofile.dart';
import 'package:teammate/widgets/common/header_bar.dart';

class SettingsPage extends StatefulWidget {
  final String title;
  const SettingsPage({Key? key, required this.title}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error during logout: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to logout: $e')));
    }
  }

  // Function to reload the page
  void _reloadPage() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Headbar(title: widget.title),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileEditCard(
              onImageUpdated: () {
                setState(() {}); // Refresh UI
              },
            ),
            SizedBox(height: 30),
            Padding(
              padding: EdgeInsets.fromLTRB(40, 0, 0, 0),
              child: Text(
                'Account Setting',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            buildSettingItem(
              title: 'Edit name',
              onTap: () async {
                final result = await Navigator.pushNamed(context, '/editname');
                if (result == true) {
                  _reloadPage();
                }
              },
            ),
            buildSettingItem(
              title: 'Change Password',
              onTap: () {
                Navigator.pushNamed(context, '/changepassword');
              },
            ),
            buildSettingItem(
              title: 'Security & Privacy',
              onTap: () {
                showSecurityPrivacyDialog(context);
              },
            ),
            SizedBox(height: 40),
            Padding(
              padding: EdgeInsets.fromLTRB(40, 0, 0, 0),
              child: Text(
                'Theme & Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
            ),
            buildSettingItem(title: 'Theme', onTap: () {}),
            buildSettingItem(title: 'Language', onTap: () {}),
            SizedBox(height: 40),
            // Styled Logout Button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: InkWell(
                onTap: _logout,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1), // Light red background
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3), // Light red border
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.red, // Red icon
                      ),
                      SizedBox(width: 16),
                      Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.red, // Red text
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
