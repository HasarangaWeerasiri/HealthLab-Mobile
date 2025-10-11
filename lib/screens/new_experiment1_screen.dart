import 'package:flutter/material.dart';
import '../utils/app_utils.dart';
import '../services/experiment_service.dart';
import '../services/draft_experiment_service.dart';
import 'homepage_screen.dart';
import 'userprofile_screen.dart';
import 'my_experiments_screen.dart';
import 'create_experiments_screen.dart';

class NewExperiment1Screen extends StatefulWidget {
  const NewExperiment1Screen({super.key});

  @override
  State<NewExperiment1Screen> createState() => _NewExperiment1ScreenState();
}

class _NewExperiment1ScreenState extends State<NewExperiment1Screen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  final TextEditingController _durationCtrl = TextEditingController();
  final List<String> _emojis = <String>[]; // up to 3
  late final List<String> _categories;
  String? _selectedCategory;

  final List<Map<String, dynamic>> _fields = <Map<String, dynamic>>[]; // up to 3
  bool _saving = false;
  String? _draftId; // when continuing a draft

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
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> _toDraft() {
    return {
      'id': _draftId,
      'title': _titleCtrl.text,
      'category': _selectedCategory,
      'emojis': _emojis,
      'description': _descCtrl.text,
      'durationDays': int.tryParse(_durationCtrl.text) ?? 0,
      'fields': _fields,
    };
  }

  void _fromDraft(Map<String, dynamic> d) {
    _draftId = d['id'] as String?;
    _titleCtrl.text = (d['title'] as String?) ?? '';
    _selectedCategory = d['category'] as String?;
    _emojis
      ..clear()
      ..addAll((d['emojis'] as List<dynamic>? ?? []).cast<String>());
    _descCtrl.text = (d['description'] as String?) ?? '';
    final dur = d['durationDays'];
    _durationCtrl.text = dur == null ? '' : '$dur';
    _fields
      ..clear()
      ..addAll((d['fields'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>());
    setState(() {});
  }

  Future<void> loadDraftIfProvided(BuildContext context) async {
    // If a draft map is passed via arguments, load it
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['draft'] != null) {
      _fromDraft(args['draft'] as Map<String, dynamic>);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF00432D),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Fresh\nExperiment',
                  style: TextStyle(color: Color(0xFFEDFDDE), fontSize: 32, fontWeight: FontWeight.w800, height: 1.05),
                ),
                const SizedBox(height: 18),
                _label('Title'),
                _filledField(
                  child: TextFormField(
                    controller: _titleCtrl,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _inputDecoration(),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Title is required' : null,
                    onChanged: (_) async {
                      final draft = _toDraft();
                      await DraftExperimentService().upsertDraft(draft);
                      _draftId = draft['id'] as String?;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _label('Category'),
                _filledField(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: _categories
                        .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) async {
                      setState(() => _selectedCategory = v);
                      final draft = _toDraft();
                      await DraftExperimentService().upsertDraft(draft);
                      _draftId = draft['id'] as String?;
                    },
                    decoration: _inputDecoration(),
                    validator: (v) => v == null ? 'Pick a category' : null,
                  ),
                ),
                const SizedBox(height: 12),
                _label('Emoji (up to 3)'),
                _emojiRow(),
                const SizedBox(height: 12),
                _label('Description'),
                _filledField(
                  child: TextFormField(
                    controller: _descCtrl,
                    minLines: 3,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.black87),
                    decoration: _inputDecoration(),
                    onChanged: (_) async {
                      final draft = _toDraft();
                      await DraftExperimentService().upsertDraft(draft);
                      _draftId = draft['id'] as String?;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _label('Duration (days)'),
                _filledField(
                  child: TextFormField(
                    controller: _durationCtrl,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(),
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n <= 0) return 'Enter number of days > 0';
                      return null;
                    },
                    onChanged: (_) async {
                      final draft = _toDraft();
                      await DraftExperimentService().upsertDraft(draft);
                      _draftId = draft['id'] as String?;
                    },
                  ),
                ),
                const SizedBox(height: 16),
                if (_fields.isNotEmpty) _label('Fields'),
                ..._fields.map((f) => _fieldChip(f)).toList(),
                const SizedBox(height: 8),
                _primaryWide(
                  label: 'Add new field',
                  onPressed: _fields.length >= 3
                      ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You can add up to 3 fields')))
                      : _openAddFieldDialog,
                ),
                const SizedBox(height: 12),
                _primaryWide(
                  label: _saving ? 'Publishing...' : 'Publish',
                  onPressed: _saving ? null : _publish,
                  filled: true,
                ),
                const SizedBox(height: 24),
                Text(
                  'Tip: add a single emoji for better visibility. You can add up to 3.',
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Load a provided draft once
    if (_draftId == null && (_titleCtrl.text.isEmpty && _fields.isEmpty)) {
      loadDraftIfProvided(context);
    }
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(text, style: const TextStyle(color: Color(0xFFEDFDDE), fontSize: 16)),
    );
  }

  InputDecoration _inputDecoration() {
    return const InputDecoration(
      filled: true,
      fillColor: Color(0xFFEDFDDE),
      border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(16)), borderSide: BorderSide.none),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _filledField({required Widget child}) {
    return child;
  }

  Widget _emojiRow() {
    return Row(
      children: [
        Expanded(
          child: Wrap(
            spacing: 8,
            children: _emojis
                .map((e) => Chip(
                      label: Text(e),
                      backgroundColor: const Color(0xFFEDFDDE),
                      deleteIcon: const Icon(Icons.close, size: 16),
                      onDeleted: () => setState(() => _emojis.remove(e)),
                    ))
                .toList(),
          ),
        ),
        IconButton(
          onPressed: _emojis.length >= 3 ? null : _pickEmoji,
          icon: const Icon(Icons.add_reaction, color: Colors.white),
        ),
      ],
    );
  }

  Future<void> _pickEmoji() async {
    // simple input dialog for emoji text
    final controller = TextEditingController();
    final emoji = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFEDFDDE),
        title: const Text('Add emoji'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'e.g. 🥗 or 😀')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('Add')),
        ],
      ),
    );
    if (emoji != null && emoji.isNotEmpty) {
      setState(() => _emojis.add(emoji));
      final draft = _toDraft();
      await DraftExperimentService().upsertDraft(draft);
      _draftId = draft['id'] as String?;
    }
  }

  Widget _primaryWide({required String label, required VoidCallback? onPressed, bool filled = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: filled ? const Color(0xFF366A49) : const Color(0xFFEBFBD9).withOpacity(0.9),
          foregroundColor: filled ? Colors.white : const Color(0xFF1E4029),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _fieldChip(Map<String, dynamic> f) {
    final type = f['type'] as String;
    final title = f['title'] as String? ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFEDFDDE), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Text('$type · $title', style: const TextStyle(color: Colors.black87)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => setState(() => _fields.remove(f)),
          )
        ],
      ),
    );
  }

  Future<void> _openAddFieldDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _AddFieldDialog(),
    );
    if (result != null) {
      setState(() => _fields.add(result));
      final draft = _toDraft();
      await DraftExperimentService().upsertDraft(draft);
      _draftId = draft['id'] as String?;
    }
  }

  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fields.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one field')));
      return;
    }
    setState(() => _saving = true);
    try {
      final id = await ExperimentService().createExperiment(
        title: _titleCtrl.text,
        category: _selectedCategory!,
        emojis: _emojis,
        description: _descCtrl.text,
        durationDays: int.parse(_durationCtrl.text),
        fields: _fields,
      );
      // remove draft if exists
      if (_draftId != null) {
        await DraftExperimentService().removeDraft(_draftId!);
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFEDFDDE),
          title: const Text('Your experiment is published!'),
          content: const Text('Others can now join and start logging.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: ${e.toString()}')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}


class _AddFieldDialog extends StatefulWidget {
  @override
  State<_AddFieldDialog> createState() => _AddFieldDialogState();
}

class _AddFieldDialogState extends State<_AddFieldDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameCtrl = TextEditingController();
  String _type = 'radio';

  // slider configs
  final TextEditingController _minCtrl = TextEditingController(text: '0');
  final TextEditingController _maxCtrl = TextEditingController(text: '10');
  final TextEditingController _stepCtrl = TextEditingController(text: '1');
  final List<String> _sequence = [];

  // radio configs
  final List<String> _options = ['Yes', 'No'];
  final TextEditingController _optionCtrl = TextEditingController();

  // number configs
  final TextEditingController _unitCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _stepCtrl.dispose();
    _optionCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFFEDFDDE),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Add a new\nField', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1E4029), height: 1.1)),
                const SizedBox(height: 16),
                const Text('Give a name to the field'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                const Text('Select a field type'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _type,
                  items: const [
                    DropdownMenuItem(value: 'radio', child: Text('Radio Button (y/n)')),
                    DropdownMenuItem(value: 'slider', child: Text('Slider')),
                    DropdownMenuItem(value: 'number', child: Text('Number')),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'radio'),
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                if (_type == 'slider') _buildSliderConfig(),
                if (_type == 'radio') _buildRadioConfig(),
                if (_type == 'number') _buildNumberConfig(),
                const SizedBox(height: 14),
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: 160,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4029),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Add'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: _numField('Min', _minCtrl)),
          const SizedBox(width: 8),
          Expanded(child: _numField('Max', _maxCtrl)),
          const SizedBox(width: 8),
          Expanded(child: _numField('Step', _stepCtrl)),
        ]),
        const SizedBox(height: 8),
        const Text('Sequence (optional)'),
        Wrap(
          spacing: 6,
          children: [
            ..._sequence.map((s) => Chip(label: Text(s), onDeleted: () => setState(() => _sequence.remove(s)))),
            ActionChip(
              label: const Text('Add item'),
              onPressed: () async {
                final text = await _prompt('Sequence item');
                if (text != null && text.isNotEmpty) setState(() => _sequence.add(text));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRadioConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Options'),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          children: [
            ..._options.map((o) => Chip(label: Text(o), onDeleted: () => setState(() => _options.remove(o)))).toList(),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _optionCtrl,
                decoration: InputDecoration(
                  hintText: 'Add option',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () {
                      final t = _optionCtrl.text.trim();
                      if (t.isNotEmpty) {
                        setState(() => _options.add(t));
                        _optionCtrl.clear();
                      }
                    },
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberConfig() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Unit (optional)'),
        const SizedBox(height: 6),
        TextField(
          controller: _unitCtrl,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _numField(String label, TextEditingController c) {
    return TextField(
      controller: c,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.all(Radius.circular(12))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }

  Future<String?> _prompt(String title) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Add')),
        ],
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Map<String, dynamic> out;
    switch (_type) {
      case 'slider':
        out = {
          'type': 'slider',
          'title': _nameCtrl.text.trim(),
          'min': int.tryParse(_minCtrl.text) ?? 0,
          'max': int.tryParse(_maxCtrl.text) ?? 10,
          'step': int.tryParse(_stepCtrl.text) ?? 1,
          'sequence': _sequence,
        };
        break;
      case 'number':
        out = {
          'type': 'number',
          'title': _nameCtrl.text.trim(),
          'unit': _unitCtrl.text.trim(),
        };
        break;
      case 'radio':
      default:
        out = {
          'type': 'radio',
          'title': _nameCtrl.text.trim(),
          'options': _options.isEmpty ? ['Yes', 'No'] : _options,
        };
    }
    Navigator.of(context).pop(out);
  }
}

