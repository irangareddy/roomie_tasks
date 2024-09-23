import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/models/task.dart';
import 'package:roomie_tasks/app/providers/providers.dart';
import 'package:roomie_tasks/config/routes/routes.dart';

class TaskListPage extends StatefulWidget {
  const TaskListPage({super.key});

  @override
  State<TaskListPage> createState() => _TaskListPageState();
}

class _TaskListPageState extends State<TaskListPage> {
  bool _isLoading = true;
  bool _isSetupComplete = false;

  @override
  void initState() {
    super.initState();
    _checkSetupAndLoadData();
  }

  Future<void> _checkSetupAndLoadData() async {
    final setupProvider =
        Provider.of<GoogleSheetsSetupProvider>(context, listen: false);
    _isSetupComplete = await setupProvider.isSetupComplete();

    if (_isSetupComplete) {
      await _loadData();
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final roommateProvider =
        Provider.of<RoommateProvider>(context, listen: false);

    await Future.wait([
      taskProvider.loadTaskTemplates(),
      taskProvider.loadAssignedTasks(),
      roommateProvider.loadRoommates(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _generateWeeklyTasks() async {
    setState(() => _isLoading = true);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final roommateProvider =
        Provider.of<RoommateProvider>(context, listen: false);

    final roommates = roommateProvider.roommates.map((r) => r.name).toList();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

    await taskProvider.generateWeeklyTasks(roommates, startOfWeek);
    setState(() => _isLoading = false);
  }

  Future<void> _updateTaskStatus(Task task, TaskStatus newStatus) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final updatedTask = task.copyWith(status: newStatus);
    await taskProvider.updateAssignedTask(updatedTask);
  }

  Future<void> _swapTask(Task task) async {
    final roommateProvider =
        Provider.of<RoommateProvider>(context, listen: false);
    final roommates = roommateProvider.roommates.map((r) => r.name).toList();

    final newAssignee = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Swap task with'),
          children: roommates.map((roommate) {
            return SimpleDialogOption(
              onPressed: () => Navigator.pop(context, roommate),
              child: Text(roommate),
            );
          }).toList(),
        );
      },
    );

    if (newAssignee != null && newAssignee != task.assignedTo) {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.swapTask(task.id, newAssignee);
    }
  }

  Future<void> _wipeOffAssignedTasks() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Wipe Off All Roomie Tasks'),
          content: const Text(
            // ignore: lines_longer_than_80_chars
              'Are you sure you want to delete all assigned tasks? This action cannot be undone.',),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Wipe Off'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed ?? false) {
      setState(() => _isLoading = true);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.wipeOffAssignedTasks();
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSetupComplete) {
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
            icon: const Icon(Icons.delete_forever),
            onPressed: _wipeOffAssignedTasks,
            tooltip: 'Wipe Off All Roomie Tasks',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer2<TaskProvider, RoommateProvider>(
              builder: (context, taskProvider, roommateProvider, child) {
                final tasks = taskProvider.assignedTasks;
                final hasRoommates = roommateProvider.roommates.isNotEmpty;
                final hasTaskTemplates = taskProvider.taskTemplates.isNotEmpty;

                if (!hasRoommates || !hasTaskTemplates) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!hasRoommates)
                          ElevatedButton(
                            onPressed: () => context.go(AppRoutes.addRoommates),
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
                          'Tap the refresh button to generate tasks.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 200,),
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
                          // ignore: lines_longer_than_80_chars
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
                                  child: Text(value.toString().split('.').last),
                                );
                              }).toList(),
                            ),
                            IconButton(
                              icon: const Icon(Icons.swap_horiz),
                              onPressed: () => _swapTask(task),
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
        onPressed: _generateWeeklyTasks,
        tooltip: 'Generate Weekly Tasks',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
