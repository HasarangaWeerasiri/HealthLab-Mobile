import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/auth_service.dart';
import 'sign_in_screen.dart';
import 'homepage_screen.dart';
import 'create_experiments_screen.dart';
import 'my_experiments_screen.dart';
import 'pin_setup_screen.dart';
import 'pin_verification_screen.dart';
import 'pin_screen.dart';
import 'achievements_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic> _userData = {};
  bool _loading = true;
  bool _isEditingUsername = false;
  final TextEditingController _usernameController = TextEditingController();
  String? _usernameValidationError;
  bool _isCheckingUsername = false;
  bool _fingerprintEnabled = false;
  bool _fingerprintAvailable = false;
  bool _isTogglingFingerprint = false;
  bool _pinSet = false;
  String _selectedProfilePicture = 'person1'; // Default to person1
  List<String> _usernameSuggestions = [];
  bool _showSuggestions = false;

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
      _showSuggestions = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (_usernameController.text.trim() == username && mounted) {
        try {
          final isTaken = await authService.isUsernameTaken(username);
          if (mounted) {
            setState(() {
              _isCheckingUsername = false;
              if (isTaken) {
                _usernameValidationError = 'Username is already taken';
                _generateUsernameSuggestions(username);
                _showSuggestions = true;
              } else {
                _usernameValidationError = null;
                _showSuggestions = false;
              }
            });
          }
        } catch (e) {
          if (mounted) {
            setState(() {
              _isCheckingUsername = false;
              _usernameValidationError = 'Error checking username availability';
              _showSuggestions = false;
            });
          }
        }
      }
    });
  }

  void _generateUsernameSuggestions(String baseUsername) {
    final suggestions = <String>[];
    final base = baseUsername.toLowerCase();
    
    // Add numbers
    for (int i = 1; i <= 5; i++) {
      suggestions.add('${base}_$i');
      suggestions.add('${base}$i');
    }
    
    // Add common suffixes
    final suffixes = ['_user', '_official', '_pro', '_2024', '_new'];
    for (final suffix in suffixes) {
      suggestions.add('$base$suffix');
    }
    
    // Add random characters
    final randomChars = ['x', 'z', 'q', 'w'];
    for (final char in randomChars) {
      suggestions.add('${base}_$char');
    }
    
    setState(() {
      _usernameSuggestions = suggestions.take(6).toList();
    });
  }

  void _selectSuggestion(String suggestion) {
    setState(() {
      _usernameController.text = suggestion;
      _showSuggestions = false;
      _usernameValidationError = null;
    });
    // Trigger validation for the new username
    _onUsernameChanged();
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
      
      // Check fingerprint availability and status
      final fingerprintAvailable = await authService.isFingerprintAvailable();
      final fingerprintEnabled = await authService.isFingerprintEnabled();
      final pinSet = await authService.isPinSet();
      
      setState(() {
        _userData = userData;
        _usernameController.text = userData['username'] ?? '';
        _fingerprintAvailable = fingerprintAvailable;
        _fingerprintEnabled = fingerprintEnabled;
        _pinSet = pinSet;
        _selectedProfilePicture = userData['profilePicture'] ?? 'person1';
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
        _showSuggestions = false;
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
        _showSuggestions = false;
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
              'Choose Profile Picture',
              style: TextStyle(
                color: Color(0xFFE6FDD8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Lottie Animation Options
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildProfilePictureOption('person1', 'assets/lottie/person1.json'),
                _buildProfilePictureOption('person2', 'assets/lottie/Person2.json'),
              ],
            ),
            const SizedBox(height: 20),
            // Divider
            Container(
              height: 1,
              color: const Color(0xFFE6FDD8).withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            // Other options (coming soon)
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFE6FDD8)),
              title: const Text(
                'Take Photo',
                style: TextStyle(color: Color(0xFFE6FDD8)),
              ),
              subtitle: const Text(
                'Coming Soon',
                style: TextStyle(color: Colors.grey, fontSize: 12),
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
              subtitle: const Text(
                'Coming Soon',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                _showComingSoonDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePictureOption(String id, String assetPath) {
    final isSelected = _selectedProfilePicture == id;
    return GestureDetector(
      onTap: () => _selectProfilePicture(id),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFFE6FDD8).withOpacity(0.3),
            width: isSelected ? 3 : 2,
          ),
          color: isSelected ? const Color(0xFF4CAF50).withOpacity(0.1) : Colors.transparent,
        ),
        child: ClipOval(
          child: Lottie.asset(
            assetPath,
            fit: BoxFit.contain,
            repeat: true,
            animate: true,
          ),
        ),
      ),
    );
  }

  void _selectProfilePicture(String pictureId) {
    setState(() {
      _selectedProfilePicture = pictureId;
    });
    Navigator.pop(context);
    _updateProfilePicture(pictureId);
  }

  Future<void> _updateProfilePicture(String pictureId) async {
    try {
      final authService = AuthService();
      await authService.updateProfilePicture(pictureId);
      
      // Reload user data to reflect changes
      await _loadUserData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile picture: ${e.toString()}')),
        );
      }
    }
  }

  Widget _getProfilePictureWidget() {
    final profilePicture = _userData['profilePicture'];
    
    // If user has a custom profile picture (URL), show it
    if (profilePicture != null && profilePicture.isNotEmpty && !profilePicture.startsWith('person')) {
      return Image.network(
        profilePicture,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _getDefaultProfilePicture();
        },
      );
    }
    
    // Otherwise show the selected Lottie animation
    return _getDefaultProfilePicture();
  }

  Widget _getDefaultProfilePicture() {
    final selectedPicture = _userData['profilePicture'] ?? _selectedProfilePicture;
    String assetPath;
    
    if (selectedPicture == 'person2') {
      assetPath = 'assets/lottie/Person2.json';
    } else {
      assetPath = 'assets/lottie/person1.json'; // Default to person1
    }
    
    return Lottie.asset(
      assetPath,
      fit: BoxFit.contain,
      repeat: true,
      animate: true,
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

  Future<void> _toggleFingerprint() async {
    if (_isTogglingFingerprint) return;
    
    setState(() {
      _isTogglingFingerprint = true;
    });

    try {
      final authService = AuthService();
      
      if (_fingerprintEnabled) {
        // Disable fingerprint
        await authService.disableFingerprint();
        setState(() {
          _fingerprintEnabled = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Fingerprint authentication disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        // Check if PIN is set up first
        final isPinSet = await authService.isPinSet();
        if (!isPinSet) {
          // PIN not set up, navigate to PIN setup screen
          if (mounted) {
            final result = await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PinSetupScreen(isForFingerprintSetup: true),
              ),
            );
            
            // If PIN setup was successful, try to enable fingerprint
            if (result == true) {
              // Reload PIN status
              final pinSet = await authService.isPinSet();
              setState(() {
                _pinSet = pinSet;
              });
              
              final success = await authService.enableFingerprint();
              if (success) {
                setState(() {
                  _fingerprintEnabled = true;
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fingerprint authentication enabled successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Fingerprint authentication was cancelled'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            }
          }
        } else {
          // PIN is set up, verify PIN first before enabling fingerprint
          if (mounted) {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PinVerificationScreen(
                  reason: 'Enter your PIN to enable fingerprint authentication',
                  onSuccess: () async {
                    // PIN verified, proceed with fingerprint enable
                    final success = await authService.enableFingerprint();
                    if (success) {
                      setState(() {
                        _fingerprintEnabled = true;
                      });
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fingerprint authentication enabled successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Fingerprint authentication was cancelled'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                    // Go back to profile screen
                    Navigator.of(context).pop();
                  },
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      String errorMessage = 'Error updating fingerprint settings';
      
      if (e.toString().contains('not available')) {
        errorMessage = 'Fingerprint authentication is not available on this device';
      } else if (e.toString().contains('not enrolled')) {
        errorMessage = 'Please set up fingerprint authentication in your device settings first';
      } else if (e.toString().contains('locked')) {
        errorMessage = 'Fingerprint authentication is locked. Please use your device passcode';
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
    } finally {
      if (mounted) {
        setState(() {
          _isTogglingFingerprint = false;
        });
      }
    }
  }

  Future<void> _managePin() async {
    try {
      // Navigate to PIN setup screen
      if (mounted) {
        final result = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PinSetupScreen(
              isForFingerprintSetup: false,
            ),
          ),
        );
        
        // Reload PIN status after returning
        if (result == true) {
          final authService = AuthService();
          final pinSet = await authService.isPinSet();
          setState(() {
            _pinSet = pinSet;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error managing PIN: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _removePin() async {
    // Navigate to PIN removal screen
    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PinScreen(
            mode: PinMode.remove,
            title: 'Remove PIN',
            subtitle: 'Enter your current PIN to remove it',
            onSuccess: () async {
              // PIN verified, remove it
              try {
                final authService = AuthService();
                await authService.removePin();
                
                // Also disable fingerprint if it was enabled
                if (_fingerprintEnabled) {
                  await authService.disableFingerprint();
                  setState(() {
                    _fingerprintEnabled = false;
                  });
                }
                
                setState(() {
                  _pinSet = false;
                });
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN removed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error removing PIN: ${e.toString()}')),
                  );
                }
              }
              // Go back to profile screen
              Navigator.of(context).pop();
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      );
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
                              child: _getProfilePictureWidget(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Username - Modern Editable Interface
                        if (_isEditingUsername) ...[
                          Container(
                            width: 280,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00432D),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _usernameValidationError != null 
                                    ? Colors.red.withOpacity(0.5)
                                    : const Color(0xFF4CAF50).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                TextField(
                                  controller: _usernameController,
                                  style: const TextStyle(
                                    color: Color(0xFFE6FDD8),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                  decoration: InputDecoration(
                                    hintText: 'Enter username',
                                    hintStyle: TextStyle(
                                      color: const Color(0xFFE6FDD8).withOpacity(0.5),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    suffixIcon: _isCheckingUsername
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF4CAF50),
                                            ),
                                          )
                                        : _usernameValidationError == null && 
                                          _usernameController.text.trim().isNotEmpty
                                            ? const Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF4CAF50),
                                                size: 20,
                                              )
                                            : _usernameValidationError != null
                                                ? const Icon(
                                                    Icons.error,
                                                    color: Colors.red,
                                                    size: 20,
                                                  )
                                                : null,
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
                                if (_showSuggestions && _usernameSuggestions.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Suggestions:',
                                    style: TextStyle(
                                      color: Color(0xFFE6FDD8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: _usernameSuggestions.map((suggestion) => 
                                      GestureDetector(
                                        onTap: () => _selectSuggestion(suggestion),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4CAF50).withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: const Color(0xFF4CAF50).withOpacity(0.5),
                                            ),
                                          ),
                                          child: Text(
                                            suggestion,
                                            style: const TextStyle(
                                              color: Color(0xFF4CAF50),
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ).toList(),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: (_usernameValidationError == null && 
                                                !_isCheckingUsername && 
                                                _usernameController.text.trim().isNotEmpty)
                                          ? _updateUsername
                                          : null,
                                      icon: const Icon(Icons.check, size: 16),
                                      label: const Text('Save'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF4CAF50),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _isEditingUsername = false;
                                          _usernameController.text = _userData['username'] ?? '';
                                          _usernameValidationError = null;
                                          _isCheckingUsername = false;
                                          _showSuggestions = false;
                                        });
                                      },
                                      icon: const Icon(Icons.close, size: 16),
                                      label: const Text('Cancel'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFFE6FDD8),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isEditingUsername = true;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00432D),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE6FDD8).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _userData['username'] ?? 'User',
                                    style: const TextStyle(
                                      color: Color(0xFFE6FDD8),
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4CAF50).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF4CAF50),
                                      size: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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
                  
                  // Achievements Card
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
                          'Achievements',
                          style: TextStyle(
                            color: Color(0xFFE6FDD8),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.emoji_events,
                            color: Color(0xFFE6FDD8),
                            size: 24,
                          ),
                          title: const Text(
                            'View Achievements',
                            style: TextStyle(
                              color: Color(0xFFE6FDD8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: const Text(
                            'Track your progress and unlock achievements',
                            style: TextStyle(
                              color: Color(0xFFE6FDD8),
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFFE6FDD8),
                            size: 16,
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const AchievementsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Security Settings Card
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
                          'Security Settings',
                          style: TextStyle(
                            color: Color(0xFFE6FDD8),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Fingerprint Toggle
                        if (_fingerprintAvailable) ...[
                          Row(
                            children: [
                              const Icon(
                                Icons.fingerprint,
                                color: Color(0xFFE6FDD8),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Fingerprint Authentication',
                                      style: TextStyle(
                                        color: Color(0xFFE6FDD8),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _fingerprintEnabled 
                                          ? 'Use your fingerprint to sign in quickly'
                                          : 'Enable fingerprint authentication for faster sign-in',
                                      style: TextStyle(
                                        color: const Color(0xFFE6FDD8).withOpacity(0.7),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (_isTogglingFingerprint)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFFE6FDD8),
                                  ),
                                )
                              else
                                Switch(
                                  value: _fingerprintEnabled,
                                  onChanged: _fingerprintAvailable ? (_) => _toggleFingerprint() : null,
                                  activeColor: const Color(0xFFE6FDD8),
                                  activeTrackColor: const Color(0xFFE6FDD8).withOpacity(0.3),
                                  inactiveThumbColor: const Color(0xFFE6FDD8).withOpacity(0.5),
                                  inactiveTrackColor: const Color(0xFFE6FDD8).withOpacity(0.1),
                                ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Icon(
                                Icons.fingerprint,
                                color: const Color(0xFFE6FDD8).withOpacity(0.5),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Fingerprint Authentication',
                                      style: TextStyle(
                                        color: const Color(0xFFE6FDD8).withOpacity(0.5),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Fingerprint authentication is not available on this device',
                                      style: TextStyle(
                                        color: const Color(0xFFE6FDD8).withOpacity(0.5),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Switch(
                                value: false,
                                onChanged: null,
                                activeColor: const Color(0xFFE6FDD8),
                                activeTrackColor: const Color(0xFFE6FDD8).withOpacity(0.3),
                                inactiveThumbColor: const Color(0xFFE6FDD8).withOpacity(0.3),
                                inactiveTrackColor: const Color(0xFFE6FDD8).withOpacity(0.1),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // PIN Management Card
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
                          'PIN Management',
                          style: TextStyle(
                            color: Color(0xFFE6FDD8),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.pin,
                            color: Color(0xFFE6FDD8),
                            size: 24,
                          ),
                          title: Text(
                            _pinSet ? 'Change PIN' : 'Set Up PIN',
                            style: const TextStyle(
                              color: Color(0xFFE6FDD8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _pinSet 
                                ? 'Update your PIN for app authentication'
                                : 'Create a PIN for secure app access',
                            style: const TextStyle(
                              color: Color(0xFFE6FDD8),
                              fontSize: 12,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFFE6FDD8),
                            size: 16,
                          ),
                          onTap: _managePin,
                        ),
                        if (_pinSet) ...[
                          const SizedBox(height: 8),
                          ListTile(
                            leading: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 24,
                            ),
                            title: const Text(
                              'Remove PIN',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: const Text(
                              'Remove PIN authentication from your account',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.red,
                              size: 16,
                            ),
                            onTap: _removePin,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
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