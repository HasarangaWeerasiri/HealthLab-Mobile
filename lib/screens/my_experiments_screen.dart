import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/experiment_service.dart';
import '../services/csv_export_service.dart';
import 'joined_experiment_screen.dart';
import 'experiment_details_screen.dart';

class MyExperimentsScreen extends StatefulWidget {
  const MyExperimentsScreen({super.key});

  @override
  State<MyExperimentsScreen> createState() => _MyExperimentsScreenState();
}

class _MyExperimentsScreenState extends State<MyExperimentsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ExperimentService _experimentService = ExperimentService();
  final CsvExportService _csvExportService = CsvExportService();
  
  List<Map<String, dynamic>> _joinedExperiments = [];
  List<Map<String, dynamic>> _createdExperiments = [];
  bool _isLoading = true;
  String _errorMessage = '';
  Set<String> _exportingExperiments = {}; // Track which experiments are being exported

  @override
  void initState() {
    super.initState();
    _loadExperiments();
    // Set system status bar color to match header
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF1A4D3B), // Same green as header
        statusBarIconBrightness: Brightness.light, // Light icons for dark background
      ),
    );
  }

  Future<void> _loadExperiments() async {
    print('DEBUG: Starting to load experiments');
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      print('DEBUG: Fetching joined experiments...');
      final joinedExperiments = await _experimentService.getJoinedExperiments();
      print('DEBUG: Got ${joinedExperiments.length} joined experiments');
      
      print('DEBUG: Fetching created experiments...');
      final createdExperiments = await _experimentService.getCreatedExperiments();
      print('DEBUG: Got ${createdExperiments.length} created experiments');
      
      setState(() {
        _joinedExperiments = joinedExperiments;
        _createdExperiments = createdExperiments;
        _isLoading = false;
      });
      
      print('DEBUG: Successfully loaded experiments');
    } catch (e) {
      print('DEBUG: Error loading experiments: $e');
      setState(() {
        _errorMessage = 'Failed to load experiments. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportExperimentData(String experimentId, String experimentTitle) async {
    setState(() {
      _exportingExperiments.add(experimentId);
    });

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting experiment data...'),
            ],
          ),
        ),
      );

      // Get experiment stats first
      final stats = await _csvExportService.getExperimentStats(experimentId);
      
      // Show confirmation dialog with stats
      Navigator.of(context).pop(); // Close loading dialog
      
      final shouldProceed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Export Data: ${stats['title']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Participants: ${stats['totalParticipants']}'),
              Text('Active Participants: ${stats['activeParticipants']}'),
              Text('Total Entries: ${stats['totalEntries']}'),
              Text('Avg Entries/User: ${stats['averageEntriesPerParticipant']}'),
              const SizedBox(height: 16),
              const Text('This will generate a CSV file with all participant data and entries.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Export'),
            ),
          ],
        ),
      );

      if (shouldProceed == true) {
        // Show loading dialog again
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Generating CSV file...'),
              ],
            ),
          ),
        );

        // Export the data
        final filePath = await _csvExportService.exportExperimentData(experimentId);
        
        Navigator.of(context).pop(); // Close loading dialog
        
            if (filePath != null) {
              // Show success dialog with file location
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 24),
                      SizedBox(width: 8),
                      Text('Export Successful'),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your CSV file has been successfully generated!',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'File saved to:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SelectableText(
                          filePath,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You can find this file in your device\'s ${_csvExportService.getUserFriendlyDirectoryDescription().toLowerCase()}.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else {
          // Show error dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Export Failed'),
              content: const Text('Failed to export experiment data. Please try again.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close any open dialogs
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Export Error'),
          content: Text('An error occurred: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _exportingExperiments.remove(experimentId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF212121),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A4D3B),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Experiments',
                      style: TextStyle(
                        color: Color(0xFFE0E0E0),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFA0C49D),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search experiments',
                          hintStyle: TextStyle(
                            color: Color(0xFF616161),
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF616161),
                          ),
                        ),
                        style: const TextStyle(
                          color: Color(0xFF212121),
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Main content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA0C49D)),
                      ),
                    )
                  : _errorMessage.isNotEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _errorMessage,
                                style: const TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: 16,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _loadExperiments,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFA0C49D),
                                  foregroundColor: const Color(0xFF1A4D3B),
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Joined Experiments Section
                              const Text(
                                'Joined Experiments',
                                style: TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _joinedExperiments.isEmpty
                                  ? Container(
                                      height: 100,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A4D3B),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'No joined experiments yet',
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 360,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _joinedExperiments.length,
                                        itemBuilder: (context, index) {
                                          final experiment = _joinedExperiments[index];
                                          return _buildExperimentCard(
                                            experiment: experiment,
                                            isJoined: true,
                                          );
                                        },
                                      ),
                                    ),
                              const SizedBox(height: 30),
                              
                              // Created by You Section
                              const Text(
                                'Created by You',
                                style: TextStyle(
                                  color: Color(0xFFE0E0E0),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 15),
                              _createdExperiments.isEmpty
                                  ? Container(
                                      height: 100,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A4D3B),
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          'No created experiments yet',
                                          style: TextStyle(
                                            color: Color(0xFFE0E0E0),
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      height: 360,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: _createdExperiments.length,
                                        itemBuilder: (context, index) {
                                          final experiment = _createdExperiments[index];
                                          return _buildExperimentCard(
                                            experiment: experiment,
                                            isJoined: false,
                                          );
                                        },
                                      ),
                                    ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperimentCard({
    required Map<String, dynamic> experiment,
    required bool isJoined,
  }) {
    final emojisRaw = experiment['emojis'] as List<dynamic>? ?? [];
    final emojis = emojisRaw
        .map((e) => e?.toString() ?? '')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final icon = emojis.isNotEmpty ? emojis.first : '🧪';
    final emojiDisplay = emojis.isNotEmpty
        ? (emojis.length == 1 ? emojis.first : emojis.take(4).join(' '))
        : icon;

    void navigate() {
      if (isJoined) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => JoinedExperimentScreen(
              title: experiment['title'] ?? 'Untitled Experiment',
              description: experiment['description'] ?? 'No description available',
              experimentId: (experiment['id'] ?? '').toString(),
            ),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ExperimentDetailsScreen(
              experimentData: experiment,
              isFromCreatedExperiments: true,
            ),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: navigate,
      child: Container(
        width: 360,
        margin: const EdgeInsets.only(right: 15),
        decoration: BoxDecoration(
          color: const Color(0xFF00432D),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  experiment['title'] ?? 'Untitled Experiment',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFFEDFDDE),
                    fontSize: 39,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 4,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final side = constraints.biggest.shortestSide;
                          final baselineSize = side; // large baseline, scaled by FittedBox
                          return Center(
                            child: FittedBox(
                              fit: BoxFit.contain,
                              child: Text(
                                emojiDisplay,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: baselineSize),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    flex: 6,
                    child: Text(
                      experiment['description'] ?? 'No description available',
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFEDFDDE),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (experiment['category'] != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.28)),
                    ),
                    child: Text(
                      experiment['category'],
                      style: const TextStyle(
                        color: Color(0xFFEDFDDE),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Add download CSV button for created experiments
              if (!isJoined)
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      final experimentId = experiment['id']?.toString() ?? '';
                      final experimentTitle = experiment['title'] ?? 'Untitled Experiment';
                      _exportExperimentData(experimentId, experimentTitle);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A4D3B),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF4CAF50)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_exportingExperiments.contains(experiment['id']?.toString()))
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
                              ),
                            )
                          else
                            const Icon(
                              Icons.download,
                              color: Color(0xFF4CAF50),
                              size: 16,
                            ),
                          const SizedBox(width: 8),
                          const Text(
                            'Download CSV',
                            style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
