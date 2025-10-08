import 'package:flutter/material.dart';
import '../screens/map_page.dart';

/// Example file showing different ways to navigate to the MapPage
/// This file is for reference only - integrate these patterns into your existing screens

class MapNavigationExamples extends StatelessWidget {
  const MapNavigationExamples({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map Navigation Examples'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Example 1: Simple Button Navigation
          _buildExampleCard(
            title: 'Example 1: Simple Button',
            description: 'Basic navigation using a button',
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/map'),
              icon: const Icon(Icons.map),
              label: const Text('Open Safety Map'),
            ),
          ),

          const SizedBox(height: 16),

          // Example 2: Card with Navigation
          _buildExampleCard(
            title: 'Example 2: Interactive Card',
            description: 'Navigate using a tappable card',
            child: Card(
              elevation: 4,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapPage()),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.map_outlined,
                          color: Colors.blue.shade700,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Health Safety Map',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'View and manage danger zones',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Example 3: List Tile Navigation
          _buildExampleCard(
            title: 'Example 3: List Tile',
            description: 'Navigate using a list tile (good for settings/menu)',
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.location_on, color: Colors.white),
              ),
              title: const Text('Danger Zone Map'),
              subtitle: const Text('Tap to view health risk areas'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, '/map'),
            ),
          ),

          const SizedBox(height: 16),

          // Example 4: Floating Action Button
          _buildExampleCard(
            title: 'Example 4: Floating Action Button',
            description: 'Quick access FAB (add to your main screens)',
            child: const Center(
              child: Column(
                children: [
                  Text('Add this to your Scaffold:'),
                  SizedBox(height: 8),
                  Text(
                    'floatingActionButton: FloatingActionButton(\n'
                    '  onPressed: () => Navigator.pushNamed(context, \'/map\'),\n'
                    '  child: Icon(Icons.map),\n'
                    ')',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Example 5: Dashboard Grid Item
          _buildExampleCard(
            title: 'Example 5: Dashboard Grid',
            description: 'Add as a grid item in your dashboard',
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildDashboardItem(
                  context,
                  icon: Icons.map,
                  label: 'Safety Map',
                  color: Colors.blue,
                  onTap: () => Navigator.pushNamed(context, '/map'),
                ),
                _buildDashboardItem(
                  context,
                  icon: Icons.person,
                  label: 'Profile',
                  color: Colors.purple,
                  onTap: () {
                    // Navigate to profile
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Code snippet section
          const Divider(),
          const SizedBox(height: 16),
          const Text(
            'Integration Code Snippets',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          _buildCodeSnippet(
            title: 'Method 1: Named Route',
            code: "Navigator.pushNamed(context, '/map');",
          ),

          const SizedBox(height: 12),

          _buildCodeSnippet(
            title: 'Method 2: Direct Route',
            code: "Navigator.push(\n"
                "  context,\n"
                "  MaterialPageRoute(\n"
                "    builder: (context) => const MapPage(),\n"
                "  ),\n"
                ");",
          ),

          const SizedBox(height: 12),

          _buildCodeSnippet(
            title: 'Method 3: Replace Current Screen',
            code: "Navigator.pushReplacementNamed(context, '/map');",
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCard({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeSnippet({
    required String title,
    required String code,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Example: How to add map navigation to your existing dashboard
class DashboardWithMapExample extends StatelessWidget {
  const DashboardWithMapExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Add this card to your dashboard
            Card(
              elevation: 4,
              child: InkWell(
                onTap: () => Navigator.pushNamed(context, '/map'),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.map,
                          color: Colors.blue.shade700,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Health Safety Map',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'View and report danger zones in your area',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
