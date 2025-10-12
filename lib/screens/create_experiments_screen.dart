import 'package:flutter/material.dart';
import 'homepage_screen.dart';
import 'userprofile_screen.dart';
import 'new_experiment1_screen.dart';
import 'my_experiments_screen.dart';
import '../services/draft_experiment_service.dart';

class CreateExperimentsScreen extends StatefulWidget {
  const CreateExperimentsScreen({super.key});

  @override
  State<CreateExperimentsScreen> createState() => _CreateExperimentsScreenState();
}

class _CreateExperimentsScreenState extends State<CreateExperimentsScreen> {
  List<Map<String, dynamic>> _drafts = const [];
  late final List<_Template> _templates;

  @override
  void initState() {
    super.initState();
    _loadDrafts();
    _templates = _buildTemplates();
  }

  Future<void> _loadDrafts() async {
    final list = await DraftExperimentService().getDrafts();
    if (!mounted) return;
    setState(() => _drafts = list);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00432D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              const Text(
                "Let's Try\nSomething New",
                style: TextStyle(
                  color: Color(0xFFEDFDDE),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NewExperiment1Screen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEBFBD9).withOpacity(0.88),
                    foregroundColor: const Color(0xFF1E4029),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Create new Experiment'),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Template\nLibrary',
                style: TextStyle(
                  color: Color(0xFFEDFDDE),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Find already defined sample templates for your experiments',
                style: TextStyle(
                  color: Color(0xFFEDFDDE),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _templates.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final t = _templates[index];
                    return _TemplateCard(
                      template: t,
                      onUse: () async {
                        final draft = t.asDraft();
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NewExperiment1Screen(),
                            settings: RouteSettings(arguments: {'draft': draft}),
                          ),
                        );
                        _loadDrafts();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              if (_drafts.isNotEmpty) ...[
                const Text(
                  'Drafts',
                  style: TextStyle(
                    color: Color(0xFFEDFDDE),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _drafts.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final d = _drafts[i];
                    return _DraftTile(
                      title: (d['title'] as String?)?.isNotEmpty == true ? d['title'] : 'Untitled experiment',
                      subtitle: (d['category'] as String?) ?? 'No category',
                      onOpen: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const NewExperiment1Screen(),
                            settings: RouteSettings(arguments: {'draft': d}),
                          ),
                        );
                        _loadDrafts();
                      },
                      onDelete: () async {
                        await DraftExperimentService().removeDraft(d['id'] as String);
                        _loadDrafts();
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final _Template template;
  final VoidCallback onUse;
  const _TemplateCard({required this.template, required this.onUse});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: const Color(0xFFEBFBD9),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            template.title,
            style: TextStyle(
              color: Color(0xFF00432D),
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 24),
          ...template.previewLines.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l,
                  style: const TextStyle(
                    color: Color(0xFF00432D),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: OutlinedButton(
              onPressed: onUse,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00432D)),
                foregroundColor: const Color(0xFF00432D),
              ),
              child: const Text('Use template'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DummySlider extends StatelessWidget {
  const _DummySlider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            color: Color(0xFF00432D),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: const Color(0xFF00432D).withOpacity(0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ],
    );
  }
}

class _DraftTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _DraftTile({required this.title, required this.subtitle, required this.onOpen, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEBFBD9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Color(0xFF00432D), fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(color: Color(0xFF00432D))),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.edit), onPressed: onOpen),
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: onDelete),
          ],
        ),
        onTap: onOpen,
      ),
    );
  }
}

class _Template {
  final String title;
  final String category;
  final List<String> emojis;
  final String description;
  final int durationDays;
  final List<Map<String, dynamic>> fields;
  final List<String> previewLines;

  _Template({
    required this.title,
    required this.category,
    required this.emojis,
    required this.description,
    required this.durationDays,
    required this.fields,
    required this.previewLines,
  });

  Map<String, dynamic> asDraft() {
    return {
      'title': title,
      'category': category,
      'emojis': emojis,
      'description': description,
      'durationDays': durationDays,
      'fields': fields,
    };
  }
}

List<_Template> _buildTemplates() {
  return [
    _Template(
      title: 'Daily Steps & Sleep',
      category: 'Daily Exercise',
      emojis: ['🚶', '😴'],
      description: 'Track your activity and sleep quality for better recovery.',
      durationDays: 14,
      fields: [
        {'type': 'number', 'title': 'Step count', 'unit': 'steps'},
        {'type': 'slider', 'title': 'Sleep quality', 'min': 1, 'max': 10, 'step': 1},
      ],
      previewLines: const ['Step count: Number', 'Sleep quality: Slider 1-10'],
    ),
    _Template(
      title: 'Hydration & Energy',
      category: 'Hydration',
      emojis: ['💧', '⚡'],
      description: 'Measure water intake and daily energy levels.',
      durationDays: 10,
      fields: [
        {'type': 'number', 'title': 'Water intake', 'unit': 'ml'},
        {'type': 'slider', 'title': 'Energy level', 'min': 1, 'max': 10, 'step': 1},
      ],
      previewLines: const ['Water intake: Number (ml)', 'Energy level: Slider 1-10'],
    ),
    _Template(
      title: 'Focus & Caffeine',
      category: 'Energy & Focus',
      emojis: ['☕', '🎯'],
      description: 'See how caffeine affects your focus.',
      durationDays: 7,
      fields: [
        {'type': 'number', 'title': 'Caffeine amount', 'unit': 'mg'},
        {'type': 'radio', 'title': 'Pomodoro done?', 'options': ['Yes', 'No']},
      ],
      previewLines: const ['Caffeine amount: Number (mg)', 'Pomodoro done?: Yes/No'],
    ),
  ];
}


