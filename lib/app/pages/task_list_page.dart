import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/models/task.dart';
import 'package:roomie_tasks/app/pages/task_modal_sheet.dart';
import 'package:roomie_tasks/app/providers/providers.dart';
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
    final setupProvider = Provider.of<GoogleSheetsSetupProvider>(context);

    return FutureBuilder<bool>(
      future: setupProvider.isSetupComplete(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()),);
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

        // Rest of your existing Scaffold for the main app
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
                  builder: (context, taskProvider, roommateProvider, child) {
                    final tasks = taskProvider.assignedTasks;
                    final hasRoommates = roommateProvider.roommates.isNotEmpty;
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
                                onPressed: () => context.go(AppRoutes.addTasks),
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
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Tap the + button to add a new task.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 200),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        return Card(
                          child: ListTile(
                            title: Text(task.name),
                            subtitle: Text(
                              'Assigned to: ${task.assignedTo ?? 'Unassigned'}\n'
                              'Due: ${task.endDate?.toString().split(' ')[0] ?? 'Not set'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                DropdownButton<TaskStatus>(
                                  value: task.status,
                                  onChanged: (TaskStatus? newValue) {
                                    if (newValue != null) {
                                      _updateTaskStatus(task, newValue);
                                    }
                                  },
                                  items: TaskStatus.values
                                      .map<DropdownMenuItem<TaskStatus>>(
                                          (TaskStatus value) {
                                    return DropdownMenuItem<TaskStatus>(
                                      value: value,
                                      child: Text(
                                          value.toString().split('.').last,),
                                    );
                                  }).toList(),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _showTaskModal(task: task),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _deleteTask(task),
                                ),
                              ],
                            ),
                          ),
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
}
