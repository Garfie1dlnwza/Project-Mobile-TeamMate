import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:teammate/services/firestore_poll_service.dart';

class PollContent extends StatefulWidget {
  final Map<String, dynamic> data;
  final Color themeColor;
  final String pollId;

  const PollContent({
    super.key,
    required this.data,
    required this.themeColor,
    required this.pollId,
  });

  @override
  State<PollContent> createState() => _PollContentState();
}

class _PollContentState extends State<PollContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _selectedOption;
  bool _hasVoted = false;
  bool _isSubmitting = false;
  final FirestorePollService _pollService = FirestorePollService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _checkIfUserVoted();
    _controller.forward();
  }

  Future<void> _checkIfUserVoted() async {
    final hasVoted = await _pollService.hasUserVoted(widget.pollId);
    
    if (mounted) {
      setState(() {
        _hasVoted = hasVoted;
      });
    }
    
    // If user has voted, find which option they voted for
    if (hasVoted) {
      final String? userId = _auth.currentUser?.uid;
      if (userId != null) {
        Map<String, dynamic> votes = widget.data['votes'] ?? {};
        
        for (int i = 0; i < widget.data['options'].length; i++) {
          String option = widget.data['options'][i];
          List<dynamic> voters = votes[option] ?? [];
          
          if (voters.contains(userId)) {
            if (mounted) {
              setState(() {
                _selectedOption = i;
              });
            }
            break;
          }
        }
      }
    }
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
    
    // Get total votes either from field or by counting
    int totalVotes = widget.data['totalVotes'] ?? 0;
    
    // Fallback calculation in case totalVotes field is missing
    if (totalVotes == 0) {
      votes.forEach((key, value) {
        if (value is List) {
          totalVotes += value.length;
        }
      });
    }

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
                  '$totalVotes ${totalVotes == 1 ? 'vote' : 'votes'} so far',
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
                  onTap: isActive && (!_hasVoted || _selectedOption == index)
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
                            color: isSelected ? widget.themeColor : Colors.grey[200],
                            border: Border.all(
                              color: isSelected ? widget.themeColor : Colors.grey[400]!,
                              width: 2,
                            ),
                          ),
                          child: isSelected
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
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
                            width: MediaQuery.of(context).size.width *
                                0.8 *
                                progressAnimation.value,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  widget.themeColor.withOpacity(0.7),
                                  widget.themeColor,
                                ],
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (isSelected)
                        Text(
                          'Your vote',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.themeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '$voteCount ${voteCount == 1 ? 'vote' : 'votes'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        // Poll action button
        if (isActive) ...[
          Center(
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : (_selectedOption != null)
                      ? () async {
                          setState(() {
                            _isSubmitting = true;
                          });
                          
                          try {
                            await _pollService.submitVote(
                              widget.pollId,
                              options[_selectedOption!].toString(),
                            );
                            
                            if (mounted) {
                              setState(() {
                                _hasVoted = true;
                                _isSubmitting = false;
                                _controller.reset();
                                _controller.forward();
                              });
                              
                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_hasVoted ? 'Vote updated!' : 'Vote submitted!'),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() {
                                _isSubmitting = false;
                              });
                              
                              // Show error message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                              );
                            }
                          }
                        }
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.themeColor,
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
              child: _isSubmitting
                  ? SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _hasVoted ? 'Update Vote' : 'Submit Vote',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ] else ...[
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
        ],
      ],
    );
  }
}