import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/models/task.dart';
import 'package:roomie_tasks/app/providers/tasks_provider.dart';
import 'package:roomie_tasks/config/routes/routes.dart';

class AddTasksPage extends StatefulWidget {
  const AddTasksPage({super.key});

  @override
  State<AddTasksPage> createState() => _AddTasksPageState();
}

class _AddTasksPageState extends State<AddTasksPage> {
  final TextEditingController _taskNameController = TextEditingController();
  TaskFrequency _frequency = TaskFrequency.weekly;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTaskTemplates();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task Templates'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _taskNameController,
              decoration: const InputDecoration(
                labelText: 'Task Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addTaskTemplate,
              child: const Text('Add Task Template'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
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
                              onPressed: () =>
                                  taskProvider.deleteTaskTemplate(task.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.taskList),
              child: const Text('Next: View Task List'),
            ),
          ],
        ),
      ),
    );
  }
}
