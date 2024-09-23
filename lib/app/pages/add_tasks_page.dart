import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/models/task.dart';
import 'package:roomie_tasks/app/providers/tasks_provider.dart';

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
    _loadTemplateTasks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTaskTemplates();
    });
  }

  Future<void> _loadTemplateTasks() async {
    final jsonString =
        await rootBundle.loadString('assets/template_tasks.json');
    final jsonData = json.decode(jsonString) as Map<String, dynamic>;
    setState(() {
      _templateTasks =
          (jsonData['templateTasks'] as List).cast<Map<String, dynamic>>();
    });
  }

  Future<void> _addTaskTemplate() async {
    if (_taskNameController.text.isNotEmpty) {
      final task = Task(
        name: _taskNameController.text,
        frequency: _frequency,
      );
      await context.read<TaskProvider>().addTaskTemplate(task);
      _taskNameController.clear();
    }
  }

  Future<void> _editTaskTemplate(Task task) async {
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
      await context.read<TaskProvider>().updateTaskTemplate(result);
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
                    'Add Custom Task',
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
                      _addTaskTemplate();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Templates'),
      ),
      body: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          if (taskProvider.taskTemplates.isEmpty) {
            return Center(
              child: Text(
                'No task templates yet. Add one using the button below!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }
          return ListView.builder(
            itemCount: taskProvider.taskTemplates.length,
            itemBuilder: (context, index) {
              final task = taskProvider.taskTemplates[index];
              return ListTile(
                title: Text(task.name),
                subtitle: Text('Frequency: ${task.frequency.name}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _editTaskTemplate(task),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => taskProvider.deleteTaskTemplate(task.id),
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
  }
}
