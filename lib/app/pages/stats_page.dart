import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/providers/providers.dart';
import 'package:roomie_tasks/config/theme/app_theme.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Statistics'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadFairnessReport(context),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('No data available'));
          }

          final report = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverallBalance(report, theme),
                  const SizedBox(height: 24),
                  _buildTaskDistribution(report, theme),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadFairnessReport(BuildContext context) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    return taskProvider.generateFairnessReport();
  }

  Widget _buildOverallBalance(Map<String, dynamic> report, ThemeData theme) {
    final overallBalance = report['overall_balance'] as double;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Task Balance',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: overallBalance / 100,
            minHeight: 10,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.uberBlue),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${overallBalance.toStringAsFixed(1)}% balanced',
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildTaskDistribution(Map<String, dynamic> report, ThemeData theme) {
    final taskStats = Map<String, dynamic>.from(report)
      ..remove('overall_balance');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Task Distribution',
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...taskStats.entries.map((entry) {
          if (entry.value is Map<String, dynamic>) {
            return _buildTaskCard(
                entry.key,
                Map<String, int>.from(entry.value as Map<String, dynamic>),
                theme,);
          } else {
            return const SizedBox.shrink();
          }
        }).whereType<Card>(),
      ],
    );
  }

  Widget _buildTaskCard(
      String taskName, Map<String, int> roommateStats, ThemeData theme,) {
    final total = roommateStats.values.reduce((a, b) => a + b);
    final blueShades = _generateBlueShades(roommateStats.length);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(taskName,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),),
            const SizedBox(height: 8),
            ...roommateStats.entries.map((entry) {
              final percentage = total > 0 ? (entry.value / total * 100) : 0;
              final index = roommateStats.keys.toList().indexOf(entry.key);
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(entry.key,
                              style: theme.textTheme.bodyMedium,),),
                      Text('${entry.value} (${percentage.toStringAsFixed(1)}%)',
                          style: theme.textTheme.bodyMedium,),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          AlwaysStoppedAnimation<Color>(blueShades[index]),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  List<Color> _generateBlueShades(int count) {
    const baseColor = AppTheme.uberBlue;
    final shades = <Color>[];

    for (var i = 0; i < count; i++) {
      final shade = HSLColor.fromColor(baseColor)
          .withLightness(
            0.3 + (0.4 * i / (count - 1)),
          )
          .toColor();
      shades.add(shade);
    }

    return shades;
  }
}
