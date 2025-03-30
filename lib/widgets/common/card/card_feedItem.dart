import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:teammate/widgets/works/document.dart';
import 'package:teammate/widgets/works/poll.dart';
import 'package:teammate/widgets/works/post.dart';
import 'package:teammate/widgets/works/task_content.dart';
import 'package:teammate/services/firestore_document_service.dart'; // Add this import

class FeedItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final Color themeColor;

  const FeedItemCard({super.key, required this.item, required this.themeColor});

  @override
  State<FeedItemCard> createState() => _FeedItemCardState();
}

class _FeedItemCardState extends State<FeedItemCard> {
  final FirestoreDocumentService _documentService = FirestoreDocumentService();
  bool _isLoading = false;
  Map<String, dynamic>? _documentData;

  @override
  void initState() {
    super.initState();
    _loadDocumentIfNeeded();
  }

  // If this is a document feed item with only documentId reference, load the actual document
  Future<void> _loadDocumentIfNeeded() async {
    final type = widget.item['type'];
    final data = widget.item['data'];

    if (type == 'document') {
      // Check if we need to fetch the document data
      if (data == null || (data is Map && !data.containsKey('title'))) {
        final String? documentId = widget.item['documentId'];
        if (documentId != null) {
          setState(() {
            _isLoading = true;
          });

          try {
            final docSnapshot = await _documentService.getDocumentById(
              documentId,
            );
            if (docSnapshot != null && docSnapshot.exists) {
              setState(() {
                _documentData = docSnapshot.data() as Map<String, dynamic>;
                _isLoading = false;
              });
            } else {
              setState(() {
                _isLoading = false;
              });
            }
          } catch (e) {
            print('Error loading document: $e');
            setState(() {
              _isLoading = false;
            });
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(color: widget.themeColor),
                )
                : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    final type = widget.item['type'];
    final data = widget.item['data'];
    final id = widget.item['id'];

    switch (type) {
      case 'post':
        return PostContent(data: data, themeColor: widget.themeColor);
      case 'poll':
        return PollContent(
          data: data,
          themeColor: widget.themeColor,
          pollId: id,
        );
      case 'task':
        return TaskContent(data: data, themeColor: widget.themeColor);
      case 'document':
        // Use _documentData if we had to load it, otherwise use the data from the item
        final documentData = _documentData ?? data;
        return DocumentContent(
          data: documentData,
          themeColor: widget.themeColor,
        );
      default:
        return Text('Unknown content type: $type');
    }
  }
}
