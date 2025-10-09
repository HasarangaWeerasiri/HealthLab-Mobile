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
  bool _isEditingUsername = false;
  final TextEditingController _usernameController = TextEditingController();
  String? _usernameValidationError;
  bool _isCheckingUsername = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _usernameController.addListener(_onUsernameChanged);
  }

  void _onUsernameChanged() {
    if (!_isEditingUsername) return;
    
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() {
        _usernameValidationError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    // Validate format first
    final authService = AuthService();
    final formatError = authService.validateUsername(username);
    
    if (formatError != null) {
      setState(() {
        _usernameValidationError = formatError;
        _isCheckingUsername = false;
      });
      return;
    }

    // Check availability after a delay to avoid too many requests
    setState(() {
      _isCheckingUsername = true;
      _usernameValidationError = null;
    });

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_usernameController.text.trim() == username && mounted) {
        try {
          final isTaken = await authService.isUsernameTaken(username);
          if (mounted) {
            setState(() {
              _isCheckingUsername = false;
              _usernameValidationError = isTaken ? 'Username is already taken' : null;
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isCheckingUsername = false;
              _usernameValidationError = 'Error checking username availability';
            });
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _usernameController.removeListener(_onUsernameChanged);
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      final authService = AuthService();
      final userData = await authService.getStoredUserData();
      setState(() {
        _userData = userData;
        _usernameController.text = userData['username'] ?? '';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _updateUsername() async {
    final newUsername = _usernameController.text.trim();
    
    // Don't proceed if there are validation errors or checking is in progress
    if (_usernameValidationError != null || _isCheckingUsername || newUsername.isEmpty) {
      return;
    }

    // Check if username is the same as current
    if (newUsername.toLowerCase() == _userData['username']?.toLowerCase()) {
      setState(() {
        _isEditingUsername = false;
        _usernameValidationError = null;
        _isCheckingUsername = false;
      });
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE6FDD8)),
      ),
    );

    try {
      final authService = AuthService();
      await authService.updateUsername(newUsername);
      
      // Reload user data to reflect changes
      await _loadUserData();
      
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      setState(() {
        _isEditingUsername = false;
        _usernameValidationError = null;
        _isCheckingUsername = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Username updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();
      
      String errorMessage = 'Error updating username';
      
      // Handle specific error messages
      if (e.toString().contains('Username is already taken')) {
        errorMessage = 'This username is already taken. Please choose a different one.';
      } else if (e.toString().contains('must be at least')) {
        errorMessage = 'Username must be at least 3 characters long.';
      } else if (e.toString().contains('cannot exceed')) {
        errorMessage = 'Username cannot exceed 20 characters.';
      } else if (e.toString().contains('can only contain')) {
        errorMessage = 'Username can only contain letters, numbers, and underscores.';
      } else if (e.toString().contains('must start with')) {
        errorMessage = 'Username must start with a letter.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF00432D),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Profile Picture',
              style: TextStyle(
                color: Color(0xFFE6FDD8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFE6FDD8)),
              title: const Text(
                'Take Photo',
                style: TextStyle(color: Color(0xFFE6FDD8)),
              ),
              onTap: () {
                Navigator.pop(context);
                _showComingSoonDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFFE6FDD8)),
              title: const Text(
                'Choose from Gallery',
                style: TextStyle(color: Color(0xFFE6FDD8)),
              ),
              onTap: () {
                Navigator.pop(context);
                _showComingSoonDialog();
              },
            ),
            if (_userData['profilePicture'] != null && 
                _userData['profilePicture']!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeProfilePicture();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showComingSoonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF00432D),
        title: const Text(
          'Coming Soon',
          style: TextStyle(color: Color(0xFFE6FDD8)),
        ),
        content: const Text(
          'Profile picture upload functionality will be available in a future update.',
          style: TextStyle(color: Color(0xFFE6FDD8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFFE6FDD8)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeProfilePicture() async {
    try {
      final authService = AuthService();
      await authService.updateProfilePicture('');
      
      // Reload user data to reflect changes
      await _loadUserData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture removed successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error removing profile picture: ${e.toString()}')),
        );
      }
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
                  // Profile Picture and Username Section
                  Center(
                    child: Column(
                      children: [
                        // Profile Picture
                        GestureDetector(
                          onTap: _showProfilePictureOptions,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00432D),
                              border: Border.all(
                                color: const Color(0xFFE6FDD8),
                                width: 3,
                              ),
                            ),
                            child: ClipOval(
                              child: _userData['profilePicture'] != null && 
                                     _userData['profilePicture']!.isNotEmpty
                                  ? Image.network(
                                      _userData['profilePicture']!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Color(0xFFE6FDD8),
                                        );
                                      },
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Color(0xFFE6FDD8),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Username - Editable
                        if (_isEditingUsername) ...[
                          Column(
                            children: [
                              SizedBox(
                                width: 250,
                                child: TextField(
                                  controller: _usernameController,
                                  style: const TextStyle(
                                    color: Color(0xFFE6FDD8),
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    border: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _usernameValidationError != null 
                                            ? Colors.red 
                                            : const Color(0xFFE6FDD8).withOpacity(0.5),
                                      ),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _usernameValidationError != null 
                                            ? Colors.red 
                                            : const Color(0xFFE6FDD8).withOpacity(0.5),
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: _usernameValidationError != null 
                                            ? Colors.red 
                                            : const Color(0xFFE6FDD8),
                                      ),
                                    ),
                                    suffixIcon: _isCheckingUsername
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFFE6FDD8),
                                            ),
                                          )
                                        : _usernameValidationError == null && 
                                          _usernameController.text.trim().isNotEmpty
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                                size: 20,
                                              )
                                            : null,
                                  ),
                                ),
                              ),
                              if (_usernameValidationError != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _usernameValidationError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ] else ...[
                          Text(
                            _userData['username'] ?? 'User',
                            style: const TextStyle(
                              color: Color(0xFFE6FDD8),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        // Action buttons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            if (_isEditingUsername) ...[
                              IconButton(
                                onPressed: (_usernameValidationError == null && 
                                          !_isCheckingUsername && 
                                          _usernameController.text.trim().isNotEmpty)
                                    ? _updateUsername
                                    : null,
                                icon: Icon(
                                  Icons.check,
                                  color: (_usernameValidationError == null && 
                                         !_isCheckingUsername && 
                                         _usernameController.text.trim().isNotEmpty)
                                      ? const Color(0xFFE6FDD8)
                                      : const Color(0xFFE6FDD8).withOpacity(0.5),
                                  size: 20,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditingUsername = false;
                                    _usernameController.text = _userData['username'] ?? '';
                                    _usernameValidationError = null;
                                    _isCheckingUsername = false;
                                  });
                                },
                                icon: const Icon(
                                  Icons.close,
                                  color: Color(0xFFE6FDD8),
                                  size: 20,
                                ),
                              ),
                            ] else ...[
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditingUsername = true;
                                  });
                                },
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFFE6FDD8),
                                  size: 20,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Email (optional, smaller text)
                        Text(
                          _userData['email'] ?? '',
                          style: const TextStyle(
                            color: Color(0xFFE6FDD8),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  
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