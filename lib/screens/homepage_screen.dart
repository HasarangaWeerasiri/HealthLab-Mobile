import 'package:flutter/material.dart';
import 'userprofile_screen.dart';
import 'create_experiments_screen.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF201E1A),
      body: Column(
        children: [
          // Header Section
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFF00432D),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Scanner Icon Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Explore the Lab',
                          style: TextStyle(
                            color: Color(0xFFE6FDD8),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Image.asset(
                            'assets/icons/qr-code.png',
                            width: 24,
                            height: 24,
                            color: const Color(0xFFE6FDD8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEBFBD9).withOpacity(0.55),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: 'Search experiments',
                          hintStyle: TextStyle(
                            color: Color(0xFF1E4029),
                            fontSize: 16,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF1E4029),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
          // Main Content Area
          const Expanded(
            child: Center(
              child: Text(
                'Main Content Area',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ],
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
          
          // Navigate actions
          if (index == 2) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const CreateExperimentsScreen(),
              ),
            );
          } else if (index == 3) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const UserProfileScreen(),
              ),
            );
          }
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
}
