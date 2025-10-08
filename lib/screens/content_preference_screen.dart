import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_utils.dart';

class ContentPreferenceScreen extends StatefulWidget {
  const ContentPreferenceScreen({super.key});

  @override
  State<ContentPreferenceScreen> createState() => _ContentPreferenceScreenState();
}

class _ContentPreferenceScreenState extends State<ContentPreferenceScreen> {
  final List<_PreferenceItem> _items = const <_PreferenceItem>[
    _PreferenceItem(label: 'Gym & Strength', assetPath: 'assets/prefs/gym.png'),
    _PreferenceItem(label: 'Nutrition & Food', assetPath: 'assets/prefs/nutrition.png'),
    _PreferenceItem(label: 'Sleep & Recovery', assetPath: 'assets/prefs/sleep.png'),
    _PreferenceItem(label: 'Mental Wellness', assetPath: 'assets/prefs/mental.png'),
    _PreferenceItem(label: 'Daily Exercise', assetPath: 'assets/prefs/exercise.png'),
    _PreferenceItem(label: 'Energy & Focus', assetPath: 'assets/prefs/energy.png'),
    _PreferenceItem(label: 'Heart & Health', assetPath: 'assets/prefs/heart.png'),
    _PreferenceItem(label: 'Hydration', assetPath: 'assets/prefs/hydration.png'),
    _PreferenceItem(label: 'Supplements', assetPath: 'assets/prefs/supplements.png'),
  ];

  final Set<int> _selectedIndexes = <int>{};
  bool _saving = false;

  Future<void> _savePreferences() async {
    if (_selectedIndexes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one preference')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final selectedLabels = _selectedIndexes.map((i) => _items[i].label).toList();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': selectedLabels,
        'preferencesUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved')),
      );
      // TODO: Navigate to home when ready
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 12),
              Text(
                'Choose your',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'Interests',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ).copyWith(shadows: const [Shadow(color: Colors.black54, blurRadius: 6)]),
              ),
              const SizedBox(height: 8),
              Text(
                "Pick what you'd like to explore in\nHealthLab. We'll personalize your\nexperiments",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    final isSelected = _selectedIndexes.contains(index);
                    return _PreferenceTile(
                      item: item,
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedIndexes.remove(index);
                          } else {
                            _selectedIndexes.add(index);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _savePreferences,
                  icon: const Icon(Icons.arrow_right_alt_rounded, size: 24),
                  label: _saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Next'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.25)),
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreferenceItem {
  final String label;
  final String assetPath;
  const _PreferenceItem({required this.label, required this.assetPath});
}

class _PreferenceTile extends StatelessWidget {
  final _PreferenceItem item;
  final bool selected;
  final VoidCallback onTap;

  const _PreferenceTile({required this.item, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          Container(
            height: 78,
            width: 78,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? AppColors.lightGreen : AppColors.secondaryBackground,
              border: Border.all(
                color: selected ? AppColors.primaryGreen : Colors.white.withOpacity(0.15),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(
                item.assetPath,
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
