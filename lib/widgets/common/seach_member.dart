import 'package:flutter/material.dart';

class PeopleSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String searchQuery;
  final Function(String) onChanged;
  final VoidCallback onClear;

  const PeopleSearchBar({
    super.key,
    required this.controller,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Search members...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            suffixIcon:
                searchQuery.isNotEmpty
                    ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.grey),
                      onPressed: onClear,
                    )
                    : null,
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
