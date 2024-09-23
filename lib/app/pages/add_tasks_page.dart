import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/models/task.dart';
import 'package:roomie_tasks/app/providers/tasks_provider.dart';
import 'package:roomie_tasks/app/providers/theme_provider.dart';

class AddTasksPage extends StatefulWidget {
  const AddTasksPage({super.key});

  @override
  State<AddTasksPage> createState() => _AddTasksPageState();
}

class _AddTasksPageState extends State<AddTasksPage> {
  final TextEditingController _taskNameController = TextEditingController();
  TaskFrequency _frequency = TaskFrequency.weekly;
  List<Map<String, dynamic>> _templateTasks = [];

  @override
  void initState() {
    super.initState();
    _loadHouseholdTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadHouseholdTasks();
    });
  }

  Future<void> _loadHouseholdTasks() async {
    final jsonString =
        await rootBundle.loadString('assets/template_tasks.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    setState(() {
      _templateTasks =
          (jsonData['templateTasks'] as List).cast<Map<String, dynamic>>();
    });
  }

  Future<void> _addHouseholdTask() async {
    if (_taskNameController.text.isNotEmpty) {
      final task = Task(
        name: _taskNameController.text,
        frequency: _frequency,
      );
      await context.read<TaskProvider>().addHouseholdTask(task);
      _taskNameController.clear();
    }
  }

  Future<void> _editHouseholdTask(Task task) async {
    _taskNameController.text = task.name;
    _frequency = task.frequency;

    final result = await showDialog<Task>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Task Template'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskNameController,
              decoration: const InputDecoration(labelText: 'Task Name'),
            ),
            DropdownButton<TaskFrequency>(
              value: _frequency,
              onChanged: (TaskFrequency? newValue) {
                if (newValue != null) {
                  setState(() {
                    _frequency = newValue;
                  });
                }
              },
              items: TaskFrequency.values.map((TaskFrequency frequency) {
                return DropdownMenuItem<TaskFrequency>(
                  value: frequency,
                  child: Text(frequency.name),
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () => Navigator.pop(
              context,
              Task(
                id: task.id,
                name: _taskNameController.text,
                frequency: _frequency,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      await context.read<TaskProvider>().updateHouseholdTask(result);
    }
  }

  void _showAddTaskBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Household Task',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _taskNameController,
                    decoration: const InputDecoration(
                      labelText: 'Task Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButton<TaskFrequency>(
                    value: _frequency,
                    isExpanded: true,
                    onChanged: (TaskFrequency? newValue) {
                      if (newValue != null) {
                        setState(() => _frequency = newValue);
                      }
                    },
                    items: TaskFrequency.values.map((TaskFrequency frequency) {
                      return DropdownMenuItem<TaskFrequency>(
                        value: frequency,
                        child: Text(frequency.name),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _addHouseholdTask();
                      Navigator.pop(context);
                    },
                    child: const Text('Add Task'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Suggested Tasks',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 2,
                    children: _templateTasks.map((task) {
                      return ActionChip(
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 2,
                        ),
                        padding: const EdgeInsets.all(
                          2,
                        ),
                        avatar: Text(
                          task['emoji'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        label: Text(
                          task['name'] as String,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        onPressed: () {
                          _taskNameController.text = task['name'] as String;
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(
                    height: 80,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final theme = Theme.of(context);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Household Tasks'),
          ),
          body: Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              if (taskProvider.taskTemplates.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SvgPicture.asset(
                          'assets/images/no_household_tasks.svg',
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No Household Tasks!',
                          style: theme.textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          // ignore: lines_longer_than_80_chars
                          'Got some chores in mind? Hit the + and let’s keep it clean!',
                          style: theme.textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 200),
                      ],
                    ),
                  ),
                );
              }
              return ListView.builder(
                itemCount: taskProvider.taskTemplates.length,
                itemBuilder: (context, index) {
                  final task = taskProvider.taskTemplates[index];
                  return ListTile(
                    title: Text(
                      task.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Frequency: ${task.frequency.name}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () => _editHouseholdTask(task),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: theme.colorScheme.error,
                          ),
                          onPressed: () =>
                              taskProvider.deleteHouseholdTask(task.id),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _showAddTaskBottomSheet,
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}
