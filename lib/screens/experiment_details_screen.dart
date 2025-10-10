import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/custom_navigation_bar.dart';
import 'homepage_screen.dart';
import 'my_experiments_screen.dart';
import 'create_experiments_screen.dart';
import 'userprofile_screen.dart';
import 'share_experiment_screen.dart';

class ExperimentDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> experimentData;
  final String? previousExperimentId; // For navigation back to previous experiment

  const ExperimentDetailsScreen({
    super.key,
    required this.experimentData,
    this.previousExperimentId,
  });

  @override
  State<ExperimentDetailsScreen> createState() => _ExperimentDetailsScreenState();
}

class _ExperimentDetailsScreenState extends State<ExperimentDetailsScreen> {
  bool _isJoined = false;
  bool _isLoading = false;
  int _joinedCount = 0;
  List<Map<String, dynamic>> _recommendedExperiments = [];
  String _creatorUsername = '';
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.experimentData);
    _loadExperimentData();
    _loadRecommendedExperiments();
    _loadCreatorUsername();
  }

  Future<void> _loadExperimentData() async {
    final experimentId = _data['id'] ?? '';
    if (experimentId.isEmpty) return;

    try {
      // Get experiment document to get updated joined count
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

      // Check if current user has joined this experiment
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
    } catch (e) {
      print('Error loading experiment data: $e');
    }
  }

  Future<void> _loadRecommendedExperiments() async {
    try {
      final currentCategory = _data['category'] as String?;
      if (currentCategory == null) return;

      final querySnapshot = await FirebaseFirestore.instance
          .collection('experiments')
          .where('category', isEqualTo: currentCategory)
          .where('published', isEqualTo: true)
          .limit(10)
          .get();

      final experiments = querySnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .where((exp) => exp['id'] != (_data['id'] ?? ''))
          .toList();

      setState(() {
        _recommendedExperiments = experiments;
      });
    } catch (e) {
      print('Error loading recommended experiments: $e');
    }
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
        setState(() {
          _creatorUsername = username;
        });
      } else {
        setState(() {
          _creatorUsername = 'Unknown User';
        });
      }
    } catch (e) {
      print('Error loading creator username: $e');
      setState(() {
        _creatorUsername = 'Unknown User';
      });
    }
  }

  Future<void> _joinExperiment() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Please sign in to join experiments');
        return;
      }

      final experimentId = _data['id'] ?? '';
      if (experimentId.isEmpty) {
        _showErrorSnackBar('Invalid experiment');
        return;
      }

      final batch = FirebaseFirestore.instance.batch();

      // Add user to experiment's joined users
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

      // Increment joined count in experiment document
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

      _showSuccessSnackBar('Successfully joined the experiment!');
    } catch (e) {
      print('Error joining experiment: $e');
      _showErrorSnackBar('Failed to join experiment. Please try again.');
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

      // Remove user from experiment's joined users
      final userExperimentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('joinedExperiments')
          .doc(experimentId);

      batch.delete(userExperimentRef);

      // Decrement joined count in experiment document
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

      _showSuccessSnackBar('Left the experiment');
    } catch (e) {
      print('Error leaving experiment: $e');
      _showErrorSnackBar('Failed to leave experiment. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _navigateToRecommendedExperiment(Map<String, dynamic> experimentData) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExperimentDetailsScreen(
          experimentData: experimentData,
          previousExperimentId: widget.experimentData['id'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = (_data['title'] as String?) ?? 'Untitled';
    final description = (_data['description'] as String?) ?? '';
    final emojis = (_data['emojis'] as List<dynamic>? ?? []).cast<String>();
    final emoji = emojis.isNotEmpty ? emojis.first : '🧪';
    final creatorId = _data['creatorId'] as String? ?? '';
    final createdAt = _data['createdAt'] as Timestamp?;
    final durationDays = (_data['durationDays'] as int?) ?? 0;

    // Format creation date
    String createdDate = 'Unknown';
    if (createdAt != null) {
      final date = createdAt.toDate();
      createdDate = '${date.day}th ${_getMonthName(date.month)}';
    }

    return Scaffold(
      backgroundColor: const Color(0xFF00432D),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and share
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ShareExperimentScreen(
                            experimentData: _data,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF00432D),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Joined count and emoji
                      Row(
                        children: [
                          Text(
                            '$_joinedCount+ joined',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 64),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Join button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : (_isJoined ? _leaveExperiment : _joinExperiment),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFCDEDC6),
                            foregroundColor: const Color(0xFF00432D),
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
                      const SizedBox(height: 24),
                      
                      // Creator and date info
                      Text(
                        'Created By: $_creatorUsername',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Published: $createdDate',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Description
                      Text(
                        description,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Recommended for you section
                      if (_recommendedExperiments.isNotEmpty) ...[
                        const Text(
                          'Recommended for you',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _recommendedExperiments.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final experiment = _recommendedExperiments[index];
                              return _RecommendedExperimentCard(
                                experiment: experiment,
                                onTap: () => _navigateToRecommendedExperiment(experiment),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Bottom navigation bar
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: 0, // Home is selected since this is a detail view
        onTap: _handleNavigation,
      ),
    );
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0: // Home
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const HomepageScreen(),
          ),
        );
        break;
      case 1: // My Experiments
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MyExperimentsScreen(),
          ),
        );
        break;
      case 2: // Create Experiment
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const CreateExperimentsScreen(),
          ),
        );
        break;
      case 3: // Profile
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const UserProfileScreen(),
          ),
        );
        break;
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}

class _RecommendedExperimentCard extends StatelessWidget {
  final Map<String, dynamic> experiment;
  final VoidCallback onTap;

  const _RecommendedExperimentCard({
    required this.experiment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = (experiment['title'] as String?) ?? 'Untitled';
    final description = (experiment['description'] as String?) ?? '';
    final emojis = (experiment['emojis'] as List<dynamic>? ?? []).cast<String>();
    final emoji = emojis.isNotEmpty ? emojis.first : '🧪';
    final joinedCount = (experiment['joinedCount'] as int?) ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2723),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              '$joinedCount+ joined',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
