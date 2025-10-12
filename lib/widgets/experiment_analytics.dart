import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class ExperimentAnalytics extends StatefulWidget {
  final String experimentId;
  final List<Map<String, dynamic>> fields;
  final int durationDays;

  const ExperimentAnalytics({
    super.key,
    required this.experimentId,
    required this.fields,
    required this.durationDays,
  });

  @override
  State<ExperimentAnalytics> createState() => _ExperimentAnalyticsState();
}

class _ExperimentAnalyticsState extends State<ExperimentAnalytics>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  String _selectedTimeFilter = 'week';
  bool _isLoading = true;
  List<Map<String, dynamic>> _entries = [];
  Map<String, List<Map<String, dynamic>>> _filteredEntries = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _loadExperimentData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadExperimentData() async {
    try {
      setState(() => _isLoading = true);
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final entriesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection('joinedExperiments')
          .doc(widget.experimentId)
          .collection('dailyEntries')
          .orderBy('createdAt', descending: false)
          .get();

      _entries = entriesSnapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      _filterEntries();
      _animationController.forward();
    } catch (e) {
      // Handle error silently
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterEntries() {
    final now = DateTime.now();
    DateTime startDate;

    switch (_selectedTimeFilter) {
      case 'today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'week':
        startDate = now.subtract(Duration(days: now.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      default:
        startDate = now.subtract(const Duration(days: 7));
    }

    final filtered = _entries.where((entry) {
      final createdAt = (entry['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
      return createdAt.isAfter(startDate) || createdAt.isAtSameMomentAs(startDate);
    }).toList();

    // Group entries by field name
    _filteredEntries.clear();
    for (final field in widget.fields) {
      final fieldName = field['title'] as String;
      _filteredEntries[fieldName] = filtered
          .where((entry) => entry['values']?[fieldName] != null)
          .toList();
    }
  }

  void _onTimeFilterChanged(String filter) {
    setState(() {
      _selectedTimeFilter = filter;
    });
    _filterEntries();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFCDEDC6)),
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Colors.white.withOpacity(0.5),
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'No data available yet',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time filter buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                _buildTimeFilterButton('today', 'Today'),
                const SizedBox(width: 8),
                _buildTimeFilterButton('week', 'Week'),
                const SizedBox(width: 8),
                _buildTimeFilterButton('month', 'Month'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Dynamic charts based on field types
          ...widget.fields.map((field) => _buildFieldChart(field)),
        ],
      ),
    );
  }

  Widget _buildTimeFilterButton(String filter, String label) {
    final isSelected = _selectedTimeFilter == filter;
    return GestureDetector(
      onTap: () => _onTimeFilterChanged(filter),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFCDEDC6).withOpacity(0.2)
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: isSelected 
              ? Border.all(color: const Color(0xFFCDEDC6), width: 1)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? const Color(0xFFCDEDC6)
                : Colors.white.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFieldChart(Map<String, dynamic> field) {
    final fieldName = field['title'] as String;
    final fieldType = field['type'] as String? ?? 'number';
    final entries = _filteredEntries[fieldName] ?? [];

    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: _buildChartByType(fieldType, fieldName, entries, field),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildChartByType(
    String type,
    String fieldName,
    List<Map<String, dynamic>> entries,
    Map<String, dynamic> fieldConfig,
  ) {
    switch (type) {
      case 'number':
        return _buildLineChart(fieldName, entries);
      case 'slider':
        return _buildBarChart(fieldName, entries, fieldConfig);
      case 'radio':
        return _buildPieChart(fieldName, entries);
      default:
        return _buildLineChart(fieldName, entries);
    }
  }

  Widget _buildLineChart(String fieldName, List<Map<String, dynamic>> entries) {
    if (entries.length < 2) {
      return _buildGaugeChart(fieldName, entries);
    }

    final spots = entries.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final value = (data['values']?[fieldName] as num?)?.toDouble() ?? 0.0;
      return FlSpot(index.toDouble(), value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.white.withOpacity(0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < entries.length) {
                  final date = (entries[value.toInt()]['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();
                  return Text(
                    '${date.day}/${date.month}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 10,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (entries.length - 1).toDouble(),
        minY: 0,
        maxY: spots.isNotEmpty ? spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1 : 10,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFFCDEDC6),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: const Color(0xFFCDEDC6),
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFFCDEDC6).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGaugeChart(String fieldName, List<Map<String, dynamic>> entries) {
    final latestValue = entries.isNotEmpty 
        ? (entries.last['values']?[fieldName] as num?)?.toDouble() ?? 0.0
        : 0.0;
    
    // Simple gauge using a circular progress indicator
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: latestValue / 100, // Assuming max value of 100
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCDEDC6)),
                ),
                Center(
                  child: Text(
                    latestValue.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Current Value',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(String fieldName, List<Map<String, dynamic>> entries, Map<String, dynamic> fieldConfig) {
    final min = (fieldConfig['min'] as num?)?.toDouble() ?? 0.0;
    final max = (fieldConfig['max'] as num?)?.toDouble() ?? 10.0;
    
    // Calculate average for the time period
    final values = entries
        .map((e) => (e['values']?[fieldName] as num?)?.toDouble() ?? 0.0)
        .toList();
    
    final average = values.isNotEmpty 
        ? values.reduce((a, b) => a + b) / values.length 
        : 0.0;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Average: ${average.toStringAsFixed(1)}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: LinearProgressIndicator(
              value: (average - min) / (max - min),
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCDEDC6)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              min.toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            Text(
              max.toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPieChart(String fieldName, List<Map<String, dynamic>> entries) {
    // Count occurrences of each option
    final Map<String, int> counts = {};
    for (final entry in entries) {
      final value = entry['values']?[fieldName] as String? ?? '';
      counts[value] = (counts[value] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    final colors = [
      const Color(0xFFCDEDC6),
      const Color(0xFFFF875F),
      const Color(0xFF4A90E2),
      const Color(0xFF9B59B6),
      const Color(0xFFE67E22),
    ];

    final sections = counts.entries.map((entry) {
      final index = counts.keys.toList().indexOf(entry.key);
      return PieChartSectionData(
        color: colors[index % colors.length],
        value: entry.value.toDouble(),
        title: '${entry.key}\n${entry.value}',
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF00432D),
        ),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
        startDegreeOffset: -90,
      ),
    );
  }
}
