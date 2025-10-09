import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'userprofile_screen.dart';
import 'create_experiments_screen.dart';

class HomepageScreen extends StatefulWidget {
  const HomepageScreen({super.key});

  @override
  State<HomepageScreen> createState() => _HomepageScreenState();
}

class _HomepageScreenState extends State<HomepageScreen> {
  int _selectedIndex = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedCategory;
  late final List<String> _categories;

  @override
  void initState() {
    super.initState();
    _categories = const <String>[
      'Gym & Strength',
      'Nutrition & Food',
      'Sleep & Recovery',
      'Mental Wellness',
      'Daily Exercise',
      'Energy & Focus',
      'Heart & Health',
      'Hydration',
      'Supplements',
    ];
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: const InputDecoration(
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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          // Main Content Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final selected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = selected ? null : cat),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? const Color(0xFFCDEDC6) : Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Text(
                        cat,
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _experimentsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load experiments: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text('No experiments', style: TextStyle(color: Colors.white)));
                }
                final docs = snapshot.data!.docs;
                final query = _searchCtrl.text.trim().toLowerCase();
                final filtered = docs.where((d) {
                  final data = d.data();
                  final title = (data['title'] as String? ?? '').toLowerCase();
                  final desc = (data['description'] as String? ?? '').toLowerCase();
                  if (_selectedCategory != null && data['category'] != _selectedCategory) return false;
                  if (query.isNotEmpty && !(title.contains(query) || desc.contains(query))) return false;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return const Center(child: Text('No matching experiments', style: TextStyle(color: Colors.white)));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = filtered[index].data();
                    return _ExperimentCard(data: data);
                  },
                );
              },
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _experimentsStream() {
    return FirebaseFirestore.instance
        .collection('experiments')
        .where('published', isEqualTo: true)
        .snapshots();
  }
}

class _ExperimentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _ExperimentCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] as String?) ?? 'Untitled';
    final desc = (data['description'] as String?) ?? '';
    final emojis = (data['emojis'] as List<dynamic>? ?? []).cast<String>();
    final emoji = emojis.isNotEmpty ? emojis.first : '🧪';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF2A2723),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 52)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  desc,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.85)),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => _showDetails(context, data),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCDEDC6)),
                      foregroundColor: const Color(0xFFCDEDC6),
                    ),
                    child: const Text('View Details'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context, Map<String, dynamic> data) {
    final title = (data['title'] as String?) ?? 'Untitled';
    final desc = (data['description'] as String?) ?? '';
    final emojis = (data['emojis'] as List<dynamic>? ?? []).cast<String>();
    final durationDays = (data['durationDays'] as int?) ?? 0;
    final fields = (data['fields'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    showDialog<void>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: const Color(0xFFEDFDDE),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (emojis.isNotEmpty)
                        Text(emojis.join(' '), style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E4029))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (durationDays > 0)
                            Text('Duration: $durationDays days', style: const TextStyle(color: Color(0xFF1E4029))),
                          const SizedBox(height: 8),
                          Text(desc, style: const TextStyle(color: Color(0xFF1E4029))),
                          const SizedBox(height: 14),
                          const Text('Fields', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E4029))),
                          const SizedBox(height: 6),
                          ...fields.map((f) {
                            final type = (f['type'] as String?) ?? 'field';
                            final name = (f['title'] as String?) ?? '';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text('• $name ($type)', style: const TextStyle(color: Color(0xFF1E4029))),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
