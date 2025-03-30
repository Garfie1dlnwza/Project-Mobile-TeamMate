import 'package:flutter/material.dart';
import 'package:teammate/utils/date.dart';
import 'package:url_launcher/url_launcher.dart';

class DocumentContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const DocumentContent({
    Key? key,
    required this.data,
    required this.themeColor,
  }) : super(key: key);

  Future<void> _openDocument() async {
    if (data.containsKey('downloadUrl')) {
      final String url = data['downloadUrl'];
      final Uri uri = Uri.parse(url);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: themeColor.withOpacity(0.2),
      child: ListTile(
        title: Text(data['title'] ?? 'Untitled'),
        subtitle: Text('Uploaded on: ${data['uploadDate']}'),
        trailing: IconButton(
          icon: Icon(Icons.open_in_new, color: themeColor),
          onPressed: _openDocument,
        ),
      ),
    );
  }
}
