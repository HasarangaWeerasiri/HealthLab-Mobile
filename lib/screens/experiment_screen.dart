import 'package:flutter/material.dart';
import '../widgets/custom_navigation_bar.dart';
import 'homepage_screen.dart';
import 'create_experiments_screen.dart';
import 'userprofile_screen.dart';
import 'my_experiments_screen.dart';

class ExperimentScreen extends StatefulWidget {
  final String experimentTitle;
  final String experimentDescription;
  final bool isJoined;

  const ExperimentScreen({
    super.key,
    required this.experimentTitle,
    required this.experimentDescription,
    this.isJoined = false,
  });

  @override
  State<ExperimentScreen> createState() => _ExperimentScreenState();
}

class _ExperimentScreenState extends State<ExperimentScreen> {
  int _selectedIndex = 1; // Chemistry icon selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A4D3B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const MyExperimentsScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Experiment Details',
                            style: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Experiment Title
                    Text(
                      widget.experimentTitle,
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Experiment Image/Icon
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A4D3B),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          '🏃‍♂️',
                          style: TextStyle(fontSize: 80),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Experiment Description
                    const Text(
                      'Description',
                      style: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.experimentDescription,
                      style: const TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Action Buttons
                    if (widget.isJoined) ...[
                      // Joined experiment actions
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle experiment actions
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA0C49D),
                            foregroundColor: const Color(0xFF1A4D3B),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Continue Experiment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // Handle leave experiment
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE0E0E0),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Leave Experiment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Created experiment actions
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Handle edit experiment
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA0C49D),
                            foregroundColor: const Color(0xFF1A4D3B),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Edit Experiment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            // Handle delete experiment
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFE0E0E0),
                            side: const BorderSide(color: Color(0xFFE0E0E0)),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Delete Experiment',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating Navigation Bar
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _handleNavigation,
      ),
    );
  }

  void _handleNavigation(int index) {
    setState(() {
      _selectedIndex = index;
    });

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
}
