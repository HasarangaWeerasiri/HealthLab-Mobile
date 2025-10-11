import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExperimentDetailsModal extends StatefulWidget {
  final Map<String, dynamic> experimentData;

  const ExperimentDetailsModal({super.key, required this.experimentData});

  @override
  State<ExperimentDetailsModal> createState() => _ExperimentDetailsModalState();
}

class _ExperimentDetailsModalState extends State<ExperimentDetailsModal> {
  bool _isJoined = false;
  bool _isLoading = false;
  int _joinedCount = 0;
  String _creatorUsername = '';
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.experimentData);
    _loadExperimentData();
    _loadCreatorUsername();
  }

  Future<void> _loadExperimentData() async {
    final experimentId = _data['id'] ?? '';
    if (experimentId.isEmpty) return;

    try {
      final experimentDoc = await FirebaseFirestore.instance
          .collection('experiments')
          .doc(experimentId)
          .get();

      if (experimentDoc.exists) {
        final data = experimentDoc.data()!;
        setState(() {
          _joinedCount = data['joinedCount'] ?? 0;
          _data = {
            'id': experimentId,
            ...data,
          };
        });
      }

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userExperimentDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('joinedExperiments')
            .doc(experimentId)
            .get();

        setState(() {
          _isJoined = userExperimentDoc.exists;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadCreatorUsername() async {
    try {
      final creatorId = _data['creatorId'] as String?;
      if (creatorId == null || creatorId.isEmpty) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(creatorId)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final username = userData['username'] as String? ?? 'Unknown User';
        setState(() => _creatorUsername = username);
      } else {
        setState(() => _creatorUsername = 'Unknown User');
      }
    } catch (_) {
      setState(() => _creatorUsername = 'Unknown User');
    }
  }

  Future<void> _joinExperiment() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showSnack('Please sign in to join experiments', Colors.red);
        return;
      }

      final experimentId = _data['id'] ?? '';
      if (experimentId.isEmpty) {
        _showSnack('Invalid experiment', Colors.red);
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      final userExperimentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('joinedExperiments')
          .doc(experimentId);

      batch.set(userExperimentRef, {
        'joinedAt': FieldValue.serverTimestamp(),
        'experimentTitle': _data['title'],
        'experimentCategory': _data['category'],
      });

      final experimentRef = FirebaseFirestore.instance
          .collection('experiments')
          .doc(experimentId);

      batch.update(experimentRef, {
        'joinedCount': FieldValue.increment(1),
      });

      await batch.commit();
      setState(() {
        _isJoined = true;
        _joinedCount++;
      });
      _showSnack('Successfully joined the experiment!', Colors.green);
    } catch (_) {
      _showSnack('Failed to join experiment. Please try again.', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _leaveExperiment() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final experimentId = _data['id'] ?? '';
      if (experimentId.isEmpty) return;

      final batch = FirebaseFirestore.instance.batch();

      final userExperimentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('joinedExperiments')
          .doc(experimentId);
      batch.delete(userExperimentRef);

      final experimentRef = FirebaseFirestore.instance
          .collection('experiments')
          .doc(experimentId);
      batch.update(experimentRef, {
        'joinedCount': FieldValue.increment(-1),
      });

      await batch.commit();
      setState(() {
        _isJoined = false;
        _joinedCount = (_joinedCount - 1).clamp(0, double.infinity).toInt();
      });
      _showSnack('Left the experiment', Colors.green);
    } catch (_) {
      _showSnack('Failed to leave experiment. Please try again.', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final title = (_data['title'] as String?) ?? 'Untitled';
    final description = (_data['description'] as String?) ?? '';
    final emojis = (_data['emojis'] as List<dynamic>? ?? []).cast<String>();
    final emoji = emojis.isNotEmpty ? emojis.first : '🧪';
    final createdAt = _data['createdAt'] as Timestamp?;

    String createdDate = 'Unknown';
    if (createdAt != null) {
      final date = createdAt.toDate();
      createdDate = '${date.day}th ${_getMonthName(date.month)}';
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF00432D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$_joinedCount+ joined',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : (_isJoined ? _leaveExperiment : _joinExperiment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFCDEDC6),
                    foregroundColor: const Color(0xFF00432D),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00432D)),
                          ),
                        )
                      : Text(
                          _isJoined ? 'Leave Experiment' : 'Join Experiment',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Created By: ${_creatorUsername.isEmpty ? '...' : _creatorUsername}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Published: $createdDate',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showExperimentDetailsModal(BuildContext context, Map<String, dynamic> experimentData) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        minChildSize: 0.45,
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, controller) {
          return ExperimentDetailsModal(experimentData: experimentData);
        },
      );
    },
  );
}


