import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/models/task.dart';
import 'package:roomie_tasks/app/pages/task_list_page.dart';
import 'package:roomie_tasks/app/pages/task_modal_sheet.dart';
import 'package:roomie_tasks/app/providers/providers.dart';
import 'package:intl/intl.dart';

class TaskDetailPage extends StatelessWidget {

  const TaskDetailPage({required this.task, super.key});
  final Task task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _editTask(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteTask(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: theme.colorScheme.primaryContainer,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    task.assignedTo ?? 'Unassigned',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(context, Icons.event_repeat, 'Frequency', task.frequency.toString().split('.').last),
                  _buildDetailRow(context, Icons.calendar_today, 'Start Date', _formatDate(task.startDate)),
                  _buildDetailRow(context, Icons.event, 'End Date', _formatDate(task.endDate)),
                  const SizedBox(height: 24),
                  Text(
                    'Status',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _getStatusColor(context, task.status),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                       _mapTaskStatus(task.status),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

    String _mapTaskStatus(TaskStatus status) {
    return status.toString().split('.').last.capitalize();
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    return date != null ? DateFormat('MMM d, yyyy').format(date) : 'Not set';
  }

  Color _getStatusColor(BuildContext context, TaskStatus status) {
    final theme = Theme.of(context);
    switch (status) {
      case TaskStatus.skipped:
        return Colors.red;
      case TaskStatus.inProgress:
        return Colors.orange;
      case TaskStatus.done:
        return Colors.green;
      default:
        return theme.colorScheme.primary;
    }
  }

  void _editTask(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) => TaskModalSheet(task: task),
      ),
    );
  }

  void _deleteTask(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Task'),
          content: const Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.deleteAssignedTask(task.id);
      Navigator.of(context).pop(); // Return to the task list
    }
  }
}