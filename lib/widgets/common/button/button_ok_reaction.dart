import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OkReactionButton extends StatefulWidget {
  final String contentId;
  final String contentType; // 'post', 'poll', or 'task'
  final Color themeColor;

  const OkReactionButton({
    Key? key,
    required this.contentId,
    required this.contentType,
    required this.themeColor,
  }) : super(key: key);

  @override
  State<OkReactionButton> createState() => _OkReactionButtonState();
}

class _OkReactionButtonState extends State<OkReactionButton>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _hasReacted = false;
  bool _isLoading = true;
  int _reactionCount = 0;

  // Animation controller for the reaction animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _checkInitialReaction();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.5), weight: 50),
      TweenSequenceItem(tween: Tween<double>(begin: 1.5, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkInitialReaction() async {
    try {
      // Check if user has already reacted
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final docSnap =
          await _firestore
              .collection('${widget.contentType}s')
              .doc(widget.contentId)
              .get();

      if (!docSnap.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = docSnap.data() as Map<String, dynamic>;
      final List<dynamic> okReactions = data['okReactions'] ?? [];
      final int okCount = data['okCount'] ?? 0;

      if (mounted) {
        setState(() {
          _hasReacted = okReactions.contains(currentUser.uid);
          _reactionCount = okCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error checking initial reaction: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleReaction() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Play the animation
      _animationController.forward(from: 0.0);

      // Optimistic update for better UX
      setState(() {
        _hasReacted = !_hasReacted;
        _reactionCount += _hasReacted ? 1 : -1;
      });

      // Add haptic feedback
      HapticFeedback.lightImpact();

      // Update in Firestore
      if (_hasReacted) {
        await _firestore
            .collection('${widget.contentType}s')
            .doc(widget.contentId)
            .update({
              'okReactions': FieldValue.arrayUnion([currentUser.uid]),
              'okCount': FieldValue.increment(1),
            });
      } else {
        await _firestore
            .collection('${widget.contentType}s')
            .doc(widget.contentId)
            .update({
              'okReactions': FieldValue.arrayRemove([currentUser.uid]),
              'okCount': FieldValue.increment(-1),
            });
      }
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _hasReacted = !_hasReacted;
        _reactionCount += _hasReacted ? 1 : -1;
      });
      print('Error toggling reaction: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _toggleReaction,
      borderRadius: BorderRadius.circular(8),
      splashColor: widget.themeColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Icon(
                    _hasReacted ? Icons.thumb_up : Icons.thumb_up_outlined,
                    size: 18,
                    color: _hasReacted ? widget.themeColor : Colors.grey[700],
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
            _isLoading
                ? SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _hasReacted ? widget.themeColor : Colors.grey[700]!,
                    ),
                  ),
                )
                : Text(
                  _reactionCount > 0 ? 'OK · $_reactionCount' : 'OK',
                  style: TextStyle(
                    fontSize: 13,
                    color: _hasReacted ? widget.themeColor : Colors.grey[700],
                    fontWeight: _hasReacted ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
