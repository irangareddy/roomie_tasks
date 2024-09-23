import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/models/task.dart';
import 'package:roomie_tasks/app/pages/task_detail_page.dart';
import 'package:roomie_tasks/app/pages/task_modal_sheet.dart';
import 'package:roomie_tasks/app/providers/providers.dart';
import 'package:roomie_tasks/app/providers/theme_provider.dart';
import 'package:roomie_tasks/config/routes/routes.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final roommateProvider =
        Provider.of<RoommateProvider>(context, listen: false);

    try {
      await roommateProvider.loadRoommates();
      await taskProvider.loadTaskTemplates();
      await taskProvider.loadAssignedTasks();
    } catch (e) {
      Exception('Error in _loadData: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        return FutureBuilder<bool>(
          future: Provider.of<GoogleSheetsSetupProvider>(context, listen: false)
              .isSetupComplete(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.data == false) {
              return Scaffold(
                appBar: AppBar(title: const Text('Setup Required')),
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRoutes.googleSheetsSetup),
                    child: const Text('Complete Google Sheets Setup'),
                  ),
                ),
              );
            }

            return Scaffold(
              appBar: AppBar(
                title: const Text('Roomie Tasks'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.people),
                    onPressed: () => context.push(AppRoutes.addRoommates),
                    tooltip: 'Manage Roommates',
                  ),
                  IconButton(
                    icon: const Icon(Icons.list_alt),
                    onPressed: () => context.push(AppRoutes.addTasks),
                    tooltip: 'Manage Template Tasks',
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => context.push(AppRoutes.settings),
                    tooltip: 'Settings',
                  ),
                ],
              ),
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Consumer2<TaskProvider, RoommateProvider>(
                      builder:
                          (context, taskProvider, roommateProvider, child) {
                        final tasks = taskProvider.assignedTasks;
                        final hasRoommates =
                            roommateProvider.roommates.isNotEmpty;
                        final hasTaskTemplates =
                            taskProvider.taskTemplates.isNotEmpty;

                        if (!hasRoommates || !hasTaskTemplates) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!hasRoommates)
                                  ElevatedButton(
                                    onPressed: () =>
                                        context.go(AppRoutes.addRoommates),
                                    child: const Text('Add Roommates'),
                                  ),
                                if (!hasTaskTemplates)
                                  ElevatedButton(
                                    onPressed: () =>
                                        context.go(AppRoutes.addTasks),
                                    child: const Text('Add Task Templates'),
                                  ),
                              ],
                            ),
                          );
                        }

                        if (tasks.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  'assets/images/create_tasks.svg',
                                  height: 300,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'No Roomie Tasks available.',
                                  style: theme.textTheme.headlineSmall,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Tap the + button to add a new task.',
                                  style: theme.textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 200),
                              ],
                            ),
                          );
                        }

                        final groupedTasks = _groupTasksByDate(tasks);
                        final sortedDates = groupedTasks.keys.toList()..sort();

                        return ListView.builder(
                          itemCount: sortedDates.length,
                          itemBuilder: (context, index) {
                            final date = sortedDates[index];
                            final tasksForDate = groupedTasks[date]!;
                            final isOverdue = date.isBefore(DateTime.now());
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    _formatDate(date),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: isOverdue ? Colors.red : null,
                                    ),
                                  ),
                                ),
                                ...tasksForDate.map((task) => _buildTaskCard(task, theme)),
                              ],
                            );
                          },
                        );
                      },
                    ),
              floatingActionButton: FloatingActionButton(
                onPressed: _showTaskModal,
                tooltip: 'Add Task',
                child: const Icon(Icons.add),
              ),
            );
          },
        );
      },
    );
  }

Widget _buildTaskCard(Task task, ThemeData theme) {
  return Card(
    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    color: theme.colorScheme.surface,
    child: InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TaskDetailPage(task: task),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.name,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              task.assignedTo ?? 'Unassigned',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                DropdownButton<TaskStatus>(
                  value: task.status,
                  onChanged: (TaskStatus? newValue) {
                    if (newValue != null) {
                      _updateTaskStatus(task, newValue);
                    }
                  },
                  items: TaskStatus.values.map<DropdownMenuItem<TaskStatus>>(
                    (TaskStatus value) {
                      return DropdownMenuItem<TaskStatus>(
                        value: value,
                        child: Text(
                          _mapTaskStatus(value),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      );
                    },
                  ).toList(),
                  dropdownColor: theme.colorScheme.surface,
                  icon: Icon(Icons.arrow_drop_down, color: theme.colorScheme.onSurface, size: 20),
                  underline: Container(
                    height: 1,
                    color: theme.colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _updateTaskStatus(Task task, TaskStatus newStatus) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final updatedTask = task.copyWith(status: newStatus);
    await taskProvider.updateAssignedTask(updatedTask);
  }

  void _showTaskModal({Task? task}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (BuildContext context) {
          return TaskModalSheet(task: task);
        },
      ),
    );
  }

  Future<void> _deleteTask(Task task) async {
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
    }
  }

  String _mapTaskStatus(TaskStatus status) {
    return status.toString().split('.').last.capitalize();
  }

  Map<DateTime, List<Task>> _groupTasksByDate(List<Task> tasks) {
    return groupBy(tasks, (Task task) {
      final date = task.endDate ?? DateTime.now();
      return DateTime(date.year, date.month, date.day);
    });
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    if (date == today) {
      return 'Today, ${DateFormat('EEEE, MMM d, yyyy').format(date)}';
    } else if (date == tomorrow) {
      return 'Tomorrow, ${DateFormat('EEEE, MMM d, yyyy').format(date)}';
    } else {
      return DateFormat('EEEE, MMM d, yyyy').format(date);
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}
