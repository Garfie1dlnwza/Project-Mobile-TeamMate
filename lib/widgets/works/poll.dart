import 'package:flutter/material.dart';

class PollContent extends StatelessWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const PollContent({Key? key, required this.data, required this.themeColor})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String question = data['question'] ?? '';
    final List<dynamic> options = data['options'] ?? [];
    final Map<String, dynamic> votes = data['votes'] ?? {};
    final bool isActive = data['isActive'] ?? true;

    // Calculate total votes
    int totalVotes = 0;
    votes.forEach((key, value) {
      if (value is List) {
        totalVotes += value.length;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Poll question
        Text(
          question,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 16),

        // Poll options with vote counts
        ...options.map((option) {
          final String optionText = option is String ? option : '';
          final List<dynamic> optionVotes = votes[optionText] ?? [];
          final int voteCount = optionVotes.length;
          final double percentage =
              totalVotes > 0 ? (voteCount / totalVotes) * 100 : 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        optionText,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '$voteCount votes',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Progress bar
                Stack(
                  children: [
                    Container(
                      height: 8,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Container(
                      height: 8,
                      width:
                          percentage > 0
                              ? MediaQuery.of(context).size.width *
                                  (percentage / 100) *
                                  0.8
                              : 0,
                      decoration: BoxDecoration(
                        color: themeColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),

        const SizedBox(height: 12),

        // Poll action button
        Center(
          child: ElevatedButton(
            onPressed:
                isActive
                    ? () {
                      // Vote on poll
                    }
                    : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: themeColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              disabledBackgroundColor: Colors.grey[300],
            ),
            child: Text(isActive ? 'Vote' : 'Poll Closed'),
          ),
        ),
      ],
    );
  }
}
