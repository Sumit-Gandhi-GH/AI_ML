import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/attendee_provider.dart';
import '../../providers/event_provider.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    final eventId = context.read<EventProvider>().selectedEvent?.id;
    if (eventId != null) {
      final attendeeProvider = context.read<AttendeeProvider>();
      context
          .read<AnalyticsProvider>()
          .loadAnalytics(eventId, attendeeProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AnalyticsProvider>();
    final data = provider.data;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Event Analytics'),
            Text(
              'Metrics generated from sample data',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Simulating PDF Export... done!')),
              );
            },
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : data == null
              ? const Center(child: Text('No data available'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _SummaryCard(
                              title: 'Attendees',
                              value: data.totalAttendees.toString(),
                              icon: Icons.people,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Check-in Rate',
                              value:
                                  '${(data.checkInRate * 100).toStringAsFixed(1)}%',
                              icon: Icons.qr_code_scanner,
                              color: Colors.green,
                              subtitle: '${data.checkedInCount} checked in',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _SummaryCard(
                              title: 'Revenue',
                              value: NumberFormat.simpleCurrency()
                                  .format(data.totalRevenue),
                              icon: Icons.attach_money,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Ticket Distribution Chart
                      Text('Ticket Distribution',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 200,
                        child: Row(
                          children: [
                            Expanded(
                              child: PieChart(
                                PieChartData(
                                  sectionsSpace: 2,
                                  centerSpaceRadius: 40,
                                  sections:
                                      _getPieSections(data.ticketDistribution),
                                ),
                              ),
                            ),
                            const SizedBox(width: 32),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:
                                  data.ticketDistribution.entries.map((e) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: _getColorForType(e.key),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text('${e.key} (${e.value})'),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Registration Trend
                      Text('Registration Trend (Last 7 Days)',
                          style: theme.textTheme.titleLarge),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: BarChart(
                          BarChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(
                                      showTitles: true, reservedSize: 30)),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() >= 0 &&
                                        value.toInt() <
                                            data.dailyRegistrations.length) {
                                      return Text(
                                        DateFormat('Md').format(data
                                            .dailyRegistrations[value.toInt()]
                                            .date),
                                        style: const TextStyle(fontSize: 10),
                                      );
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: data.dailyRegistrations
                                .asMap()
                                .entries
                                .map((entry) {
                              return BarChartGroupData(
                                x: entry.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value.count.toDouble(),
                                    color: theme.colorScheme.primary,
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  List<PieChartSectionData> _getPieSections(Map<String, int> distribution) {
    if (distribution.isEmpty) return [];

    final total = distribution.values.fold(0, (sum, val) => sum + val);

    return distribution.entries.map((entry) {
      final percentage = entry.value / total;
      final color = _getColorForType(entry.key);

      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '${(percentage * 100).toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'vip':
        return Colors.purple;
      case 'speaker':
        return Colors.teal;
      case 'general admission':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String? subtitle;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(title,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 12),
            Text(value,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ],
        ),
      ),
    );
  }
}
