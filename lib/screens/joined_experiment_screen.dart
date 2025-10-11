import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'my_experiments_screen.dart';
import 'share_experiment_screen.dart';

class JoinedExperimentScreen extends StatefulWidget {
  final String title;
  final String description;
  final String experimentId;

  const JoinedExperimentScreen({
    super.key,
    required this.title,
    required this.description,
    required this.experimentId,
  });

  @override
  State<JoinedExperimentScreen> createState() => _JoinedExperimentScreenState();
}

class _JoinedExperimentScreenState extends State<JoinedExperimentScreen> {
  bool _isLeaving = false;
  bool _isLoading = true;
  Map<String, dynamic>? _experimentData; // full experiment doc (for fields/duration)
  List<Map<String, dynamic>> _fields = [];
  int _durationDays = 0;
  int _entriesCount = 0;
  DateTime? _lastEntryDate; // server recorded last date

  @override
  void initState() {
    super.initState();
    _loadExperimentContext();
  }

  Future<void> _loadExperimentContext() async {
    try {
      setState(() => _isLoading = true);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Fetch experiment
      final expDoc = await FirebaseFirestore.instance
          .collection('experiments')
          .doc(widget.experimentId)
          .get();
      if (expDoc.exists) {
        final data = expDoc.data()!;
        _experimentData = {'id': expDoc.id, ...data};
        _fields = (data['fields'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _durationDays = (data['durationDays'] as int?) ?? 0;
      }

      // Fetch user's joined doc to get counters
      final joinedDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('joinedExperiments')
          .doc(widget.experimentId)
          .get();
      if (joinedDoc.exists) {
        final j = joinedDoc.data()!;
        _entriesCount = (j['entriesCount'] as int?) ?? 0;
        final lastIso = j['lastEntryDate'] as String?;
        if (lastIso != null && lastIso.isNotEmpty) {
          _lastEntryDate = DateTime.tryParse(lastIso);
        }
      }
    } catch (e) {
      // ignore for now, UI will be minimal
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmAndLeave() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF00432D),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Leave experiment?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Are you sure you want to leave this experiment?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave', style: TextStyle(color: Color(0xFFFF875F), fontWeight: FontWeight.w700)),
            ),
          ],
        );
      },
    );

    if (shouldLeave != true) return;
    await _leaveExperiment();
  }

  Future<void> _leaveExperiment() async {
    if (_isLeaving) return;
    setState(() => _isLeaving = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final batch = FirebaseFirestore.instance.batch();

      final userExperimentRef = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('joinedExperiments')
          .doc(widget.experimentId);
      batch.delete(userExperimentRef);

      final experimentRef = FirebaseFirestore.instance
          .collection('experiments')
          .doc(widget.experimentId);
      batch.update(experimentRef, {
        'joinedCount': FieldValue.increment(-1),
      });

      await batch.commit();

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MyExperimentsScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to leave experiment. Please try again.')),
      );
    } finally {
      if (mounted) setState(() => _isLeaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canAdd = _canAddToday();
    return Scaffold(
      backgroundColor: const Color(0xFF00432D),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Share icon (send.png)
                  _TopIconButton(
                    assetPath: 'assets/icons/send.png',
                    onTap: () {
                      final experimentData = {
                        'id': widget.experimentId,
                        'title': widget.title,
                        'description': widget.description,
                      };
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ShareExperimentScreen(
                            experimentData: experimentData,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Bell icon (bell.png)
                  _TopIconButton(assetPath: 'assets/icons/bell.png'),
                ],
              ),
            ),

            // Title and emoji image area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.description,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                // Leave Experiment button
                                ElevatedButton(
                                  onPressed: _isLeaving ? null : _confirmAndLeave,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF875F),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: _isLeaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Leave Experiment',
                                          style: TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                // Add daily entry button (unstyled action for now)
                                ElevatedButton(
                                  onPressed: (!_isLoading && canAdd) ? _openDailyEntryDialog : _handleAddDisabled,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFCDEDC6),
                                    foregroundColor: const Color(0xFF00432D),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                  child: Text(
                                    _entriesCount >= _durationDays && _durationDays > 0
                                        ? 'Completed'
                                        : 'Add daily entry',
                                    style: const TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Runner emoji image placeholder to resemble wireframe
                      const Text(
                        '🏃‍♂️',
                        style: TextStyle(fontSize: 84),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Analytics heading (section not implemented per request)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                'Analytics',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.95),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Placeholder space for analytics chart
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  bool _canAddToday() {
    if (_durationDays > 0 && _entriesCount >= _durationDays) return false; // finished
    if (_lastEntryDate == null) return true;
    final now = DateTime.now();
    final last = _lastEntryDate!;
    return !(last.year == now.year && last.month == now.month && last.day == now.day);
  }

  void _handleAddDisabled() {
    if (_durationDays > 0 && _entriesCount >= _durationDays) {
      _showFinishedDialog();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have already added today\'s entry. Try again tomorrow.')),
    );
  }

  Future<void> _openDailyEntryDialog() async {
    if (_fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This experiment has no input fields.')),
      );
      return;
    }

    final Map<String, dynamic> values = {};
    final Map<String, TextEditingController> controllers = {};
    double? firstSliderInitial; // used if any slider exists

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFFCDEDC6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              title: const Text(
                'Daily Entry',
                style: TextStyle(color: Color(0xFF00432D), fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: _fields.map((field) {
                    final type = (field['type'] as String?) ?? 'number';
                    final title = (field['title'] as String?) ?? '';
                    Widget input;
                    switch (type) {
                      case 'slider':
                        final min = (field['min'] as num?)?.toDouble() ?? 0;
                        final max = (field['max'] as num?)?.toDouble() ?? 10;
                        final step = (field['step'] as num?)?.toDouble() ?? 1;
                        values.putIfAbsent(title, () => min);
                        firstSliderInitial ??= min;
                        input = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(color: Color(0xFF00432D), fontWeight: FontWeight.w700)),
                            Slider(
                              value: (values[title] as num).toDouble(),
                              min: min,
                              max: max,
                              divisions: ((max - min) / step).round(),
                              activeColor: const Color(0xFF00432D),
                              onChanged: (v) => setStateDialog(() => values[title] = v),
                            ),
                          ],
                        );
                        break;
                      case 'radio':
                        final options = (field['options'] as List<dynamic>? ?? ['Yes', 'No']).cast<String>();
                        values.putIfAbsent(title, () => options.first);
                        input = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(color: Color(0xFF00432D), fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: options.map((opt) {
                                final selected = values[title] == opt;
                                return ChoiceChip(
                                  selected: selected,
                                  label: Text(opt),
                                  selectedColor: const Color(0xFF00432D),
                                  labelStyle: TextStyle(color: selected ? Colors.white : const Color(0xFF00432D)),
                                  onSelected: (_) => setStateDialog(() => values[title] = opt),
                                );
                              }).toList(),
                            ),
                          ],
                        );
                        break;
                      case 'number':
                      default:
                        final controller = controllers.putIfAbsent(title, () => TextEditingController());
                        input = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(color: Color(0xFF00432D), fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ],
                        );
                    }
                    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: input);
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xFF00432D))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // read number fields
                    for (final entry in controllers.entries) {
                      final parsed = double.tryParse(entry.value.text.trim());
                      if (parsed == null) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please enter a valid number for "${entry.key}".')));
                        return;
                      }
                      values[entry.key] = parsed;
                    }
                    Navigator.of(context).pop();
                    await _saveDailyEntry(values);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00432D), foregroundColor: Colors.white),
                  child: const Text('Add daily entry'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _saveDailyEntry(Map<String, dynamic> values) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final todayKey = _formatYmd(DateTime.now());

      final entryRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('joinedExperiments')
          .doc(widget.experimentId)
          .collection('dailyEntries')
          .doc(todayKey);

      final existing = await entryRef.get();
      if (existing.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have already added daily data today.')),
        );
        return;
      }

      if (_durationDays > 0 && _entriesCount >= _durationDays) {
        _showFinishedDialog();
        return;
      }

      final batch = FirebaseFirestore.instance.batch();
      batch.set(entryRef, {
        'values': values,
        'createdAt': FieldValue.serverTimestamp(),
        'dayIndex': _entriesCount + 1,
      });

      final joinedRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('joinedExperiments')
          .doc(widget.experimentId);

      batch.set(joinedRef, {
        'lastEntryDate': DateTime.now().toIso8601String(),
        'entriesCount': FieldValue.increment(1),
      }, SetOptions(merge: true));

      await batch.commit();

      setState(() {
        _entriesCount += 1;
        _lastEntryDate = DateTime.now();
      });

      if (_durationDays > 0 && _entriesCount >= _durationDays) {
        await _showFinishedDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily entry added.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add entry. Please try again.')),
      );
    }
  }

  Future<void> _showFinishedDialog() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFCDEDC6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Congratulations!', style: TextStyle(color: Color(0xFF00432D), fontWeight: FontWeight.w800)),
        content: const Text('You have completed all daily entries for this experiment.', style: TextStyle(color: Color(0xFF00432D))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Color(0xFF00432D))),
          ),
        ],
      ),
    );
  }

  String _formatYmd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}

class _TopIconButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback? onTap;
  const _TopIconButton({required this.assetPath, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          assetPath,
          width: 22,
          height: 22,
          color: const Color(0xFFCDEDC6),
        ),
      ),
    );
  }
}


