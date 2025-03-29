import 'package:flutter/material.dart';

class PollContent extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color themeColor;

  const PollContent({Key? key, required this.data, required this.themeColor})
    : super(key: key);

  @override
  State<PollContent> createState() => _PollContentState();
}

class _PollContentState extends State<PollContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _selectedOption;
  bool _hasVoted = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String question = widget.data['question'] ?? '';
    final List<dynamic> options = widget.data['options'] ?? [];
    final Map<String, dynamic> votes = widget.data['votes'] ?? {};
    final bool isActive = widget.data['isActive'] ?? true;

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
        // Poll author info
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.poll, color: Colors.grey[700], size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Poll',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${totalVotes} votes so far',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Poll question
        Text(
          question,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
            height: 1.3,
          ),
        ),

        const SizedBox(height: 20),

        // Poll options with vote counts and animations
        ...List.generate(options.length, (index) {
          final String optionText =
              options[index] is String ? options[index] : '';
          final List<dynamic> optionVotes = votes[optionText] ?? [];
          final int voteCount = optionVotes.length;
          final double percentage =
              totalVotes > 0 ? (voteCount / totalVotes) * 100 : 0;

          final bool isSelected = _selectedOption == index;

          // Create animated progress
          final Animation<double> progressAnimation = Tween<double>(
            begin: 0.0,
            end: percentage / 100,
          ).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(
                0.2 + (index * 0.1), // Staggered start
                0.7 + (index * 0.1),
                curve: Curves.easeOutCubic,
              ),
            ),
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Option selection area
                InkWell(
                  onTap:
                      isActive && !_hasVoted
                          ? () {
                            setState(() {
                              _selectedOption = index;
                            });
                          }
                          : null,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 4,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                isSelected
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Colors.grey[800]!
                                      : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child:
                              isSelected
                                  ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                  : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            optionText,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight:
                                  isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        if (_hasVoted || !isActive) ...[
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Progress bar - only show if voted or poll is inactive
                if (_hasVoted || !isActive) ...[
                  const SizedBox(height: 6),
                  AnimatedBuilder(
                    animation: progressAnimation,
                    builder: (context, child) {
                      return Stack(
                        children: [
                          // Background
                          Container(
                            height: 8,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          // Progress
                          Container(
                            height: 8,
                            width:
                                MediaQuery.of(context).size.width *
                                0.8 *
                                progressAnimation.value,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey[600]!, Colors.grey[700]!],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      '$voteCount votes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        // Poll action button
        if (isActive && !_hasVoted) ...[
          Center(
            child: ElevatedButton(
              onPressed:
                  _selectedOption != null
                      ? () {
                        setState(() {
                          _hasVoted = true;
                          _controller.reset();
                          _controller.forward();
                        });
                        // TODO: Implement actual vote submission logic
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Submit Vote',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ] else if (!isActive) ...[
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'This poll is closed',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ] else if (_hasVoted) ...[
          Center(
            child: Text(
              'Thanks for voting!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
