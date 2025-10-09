import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'sign_in_screen.dart';
import 'homepage_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic> _userData = {};
  bool _loading = true;
  int _selectedIndex = 3; // Profile tab is selected

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = AuthService();
      final userData = await authService.getStoredUserData();
      setState(() {
        _userData = userData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      final authService = AuthService();
      await authService.signOut();
      
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF201E1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF00432D),
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Color(0xFFE6FDD8),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE6FDD8)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFFE6FDD8),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00432D),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'User Information',
                          style: TextStyle(
                            color: Color(0xFFE6FDD8),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Email', _userData['email'] ?? 'Not available'),
                        const SizedBox(height: 8),
                        _buildInfoRow('Username', _userData['username'] ?? 'Not set'),
                        const SizedBox(height: 8),
                        _buildInfoRow('User ID', _userData['userId'] ?? 'Not available'),
                        if (_userData['lastLogin'] != null) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            'Last Login',
                            DateTime.tryParse(_userData['lastLogin'])?.toString().split('.')[0] ?? 'Unknown',
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Preferences Card
                  if (_userData['preferences'] != null && (_userData['preferences'] as List).isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00432D),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Preferences',
                            style: TextStyle(
                              color: Color(0xFFE6FDD8),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: (_userData['preferences'] as List)
                                .map<Widget>((pref) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE6FDD8).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: const Color(0xFFE6FDD8).withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        pref.toString(),
                                        style: const TextStyle(
                                          color: Color(0xFFE6FDD8),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Sign Out Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _signOut,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Sign Out',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      // Floating Navigation Bar
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF366A49),
          borderRadius: BorderRadius.circular(35),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(0, 'assets/icons/home (2).png'),
              _buildNavItem(1, 'assets/icons/chemistry.png'),
              _buildNavItem(2, 'assets/icons/plus.png'),
              _buildNavItem(3, 'assets/icons/user (3).png'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String iconPath) {
    final isSelected = _selectedIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          
          // Navigate based on selected tab
          if (index == 0) {
            // Home tab
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const HomepageScreen(),
              ),
            );
          } else if (index == 3) {
            // Profile tab - already here, do nothing
            return;
          }
          // Add other navigation logic for chemistry and plus tabs as needed
        },
        child: Container(
          height: 60,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected 
                ? const Color(0xFFEDFDDE) 
                : const Color(0xFF1F412A),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Image.asset(
              iconPath,
              width: 28,
              height: 28,
              color: isSelected 
                  ? Colors.black.withOpacity(0.8) // Dark for selected
                  : Colors.white.withOpacity(0.6), // Light with 60% opacity for unselected
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              color: Color(0xFFE6FDD8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFFE6FDD8),
            ),
          ),
        ),
      ],
    );
  }
}