import 'package:flutter/material.dart';
import '../widgets/custom_navigation_bar.dart';
import '../services/experiment_service.dart';
import 'homepage_screen.dart';
import 'create_experiments_screen.dart';
import 'userprofile_screen.dart';
import 'experiment_screen.dart';

class MyExperimentsScreen extends StatefulWidget {
  const MyExperimentsScreen({super.key});

  @override
  State<MyExperimentsScreen> createState() => _MyExperimentsScreenState();
}

class _MyExperimentsScreenState extends State<MyExperimentsScreen> {
  int _selectedIndex = 1; // Chemistry icon selected
  final TextEditingController _searchController = TextEditingController();
  final ExperimentService _experimentService = ExperimentService();
  
  List<Map<String, dynamic>> _joinedExperiments = [];
  List<Map<String, dynamic>> _createdExperiments = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadExperiments();
  }

  Future<void> _loadExperiments() async {
    print('DEBUG: Starting to load experiments');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('DEBUG: Fetching joined experiments...');
      final joinedExperiments = await _experimentService.getJoinedExperiments();
      print('DEBUG: Got ${joinedExperiments.length} joined experiments');
      
      print('DEBUG: Fetching created experiments...');
      final createdExperiments = await _experimentService.getCreatedExperiments();
      print('DEBUG: Got ${createdExperiments.length} created experiments');
      
      setState(() {
        _joinedExperiments = joinedExperiments;
        _createdExperiments = createdExperiments;
        _isLoading = false;
      });
      
      print('DEBUG: Successfully loaded experiments');
    } catch (e) {
      print('DEBUG: Error loading experiments: $e');
      setState(() {
        _errorMessage = 'Failed to load experiments. Please try again.';
        _isLoading = false;
      });
    }
  }

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
                        const Expanded(
                          child: Text(
                            'Your Experiments',
                            style: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _loadExperiments,
                          icon: const Icon(
                            Icons.refresh,
                            color: Color(0xFFE0E0E0),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFA0C49D),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search experiments',
                          hintStyle: TextStyle(
                            color: Color(0xFF616161),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF616161),
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF212121),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Main content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA0C49D)),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage,
                                style: const TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _loadExperiments,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA0C49D),
                                  foregroundColor: const Color(0xFF1A4D3B),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Joined Experiments Section
                              const Text(
                                'Joined Experiments',
                                style: TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _joinedExperiments.isEmpty
                                  ? Container(
                                      height: 100,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A4D3B),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'No joined experiments yet',
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 280,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _joinedExperiments.length,
                                        itemBuilder: (context, index) {
                                          final experiment = _joinedExperiments[index];
                                          return _buildExperimentCard(
                                            experiment: experiment,
                                            isJoined: true,
                                          );
                                        },
                                      ),
                                    ),
                              const SizedBox(height: 30),
                              
                              // Created by You Section
                              const Text(
                                'Created by You',
                                style: TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _createdExperiments.isEmpty
                                  ? Container(
                                      height: 100,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A4D3B),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'No created experiments yet',
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 280,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _createdExperiments.length,
                                        itemBuilder: (context, index) {
                                          final experiment = _createdExperiments[index];
                                          return _buildExperimentCard(
                                            experiment: experiment,
                                            isJoined: false,
                                          );
                                        },
                                      ),
                                    ),
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

  Widget _buildExperimentCard({
    required Map<String, dynamic> experiment,
    required bool isJoined,
  }) {
    // Get the first emoji from the emojis list, or use a default
    final emojis = experiment['emojis'] as List<dynamic>? ?? [];
    final icon = emojis.isNotEmpty ? emojis.first.toString() : '🧪';
    
    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 15),
      decoration: BoxDecoration(
        color: const Color(0xFF1A4D3B),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Experiment Icon
            Row(
              children: [
                Text(
                  icon,
                  style: const TextStyle(fontSize: 30),
                ),
                const Spacer(),
                // Show joined count if available
                if (experiment['joinedCount'] != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA0C49D),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${experiment['joinedCount']} joined',
                      style: const TextStyle(
                        color: Color(0xFF1A4D3B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            
            // Experiment Title
            Text(
              experiment['title'] ?? 'Untitled Experiment',
              style: const TextStyle(
                color: Color(0xFFE0E0E0),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            // Experiment Category
            if (experiment['category'] != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFA0C49D).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  experiment['category'],
                  style: const TextStyle(
                    color: Color(0xFFA0C49D),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 10),
            
            // Experiment Description
            Expanded(
              child: Text(
                experiment['description'] ?? 'No description available',
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 14,
                  height: 1.4,
                ),
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 15),
            
            // View Details Button
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ExperimentScreen(
                        experimentTitle: experiment['title'] ?? 'Untitled Experiment',
                        experimentDescription: experiment['description'] ?? 'No description available',
                        isJoined: isJoined,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA0C49D),
                  foregroundColor: const Color(0xFF1A4D3B),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
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
      case 1: // My Experiments (current screen)
        // Already on this screen, do nothing
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
