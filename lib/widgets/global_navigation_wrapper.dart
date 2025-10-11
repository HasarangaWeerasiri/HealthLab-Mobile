import 'package:flutter/material.dart';
import '../widgets/custom_navigation_bar.dart';
import '../screens/homepage_screen.dart';
import '../screens/my_experiments_screen.dart';
import '../screens/create_experiments_screen.dart';
import '../screens/userprofile_screen.dart';

class GlobalNavigationWrapper extends StatefulWidget {
  final int initialIndex;
  
  const GlobalNavigationWrapper({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<GlobalNavigationWrapper> createState() => _GlobalNavigationWrapperState();
}

class _GlobalNavigationWrapperState extends State<GlobalNavigationWrapper> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    if (index == _selectedIndex) return; // Already on this page
    
    setState(() {
      _selectedIndex = index;
    });
    
    // Animate to the selected page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF201E1A),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: const [
          HomepageScreen(),
          MyExperimentsScreen(),
          CreateExperimentsScreen(),
          UserProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomNavigationBar(
        selectedIndex: _selectedIndex,
        onTap: _handleNavigation,
      ),
    );
  }
}
