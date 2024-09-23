import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/models/task.dart';
import 'package:roomie_tasks/app/providers/providers.dart';
import 'package:roomie_tasks/app/services/service_utils.dart';

class TaskModalSheet extends StatefulWidget {
  const TaskModalSheet({super.key, this.task});
  final Task? task;

  @override
  State<TaskModalSheet> createState() => _TaskModalSheetState();
}

class _TaskModalSheetState extends State<TaskModalSheet> {
  late TextEditingController _nameController;
  late DateTime _startDate;
  late DateTime _endDate;
  String? _assignedTo;
  TaskFrequency _frequency = TaskFrequency.weekly;
  bool _isCustomTask = true;
  Task? _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.task?.name ?? '');
    _startDate = widget.task?.startDate ?? DateTime.now();
    _endDate =
        widget.task?.endDate ?? DateTime.now().add(const Duration(days: 7));
    _assignedTo = widget.task?.assignedTo;
    _frequency = widget.task?.frequency ?? TaskFrequency.weekly;
    _isCustomTask = widget.task == null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.task == null)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isCustomTask = true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCustomTask
                            ? colorScheme.primary
                            : colorScheme.surface,
                        foregroundColor: _isCustomTask
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      child: const Text('Custom Task'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => setState(() => _isCustomTask = false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: !_isCustomTask
                            ? colorScheme.primary
                            : colorScheme.surface,
                        foregroundColor: !_isCustomTask
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                      ),
                      child: const Text('From Template'),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            if (_isCustomTask)
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Task Name'),
              )
            else
              Consumer<TaskProvider>(
                builder: (context, taskProvider, child) {
                  final templates = taskProvider.taskTemplates;
                  return DropdownButtonFormField<Task>(
                    value: _selectedTemplate,
                    onChanged: (Task? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedTemplate = newValue;
                          _nameController.text = newValue.name;
                          _frequency = newValue.frequency;
                        });
                      }
                    },
                    items: templates.map((Task template) {
                      return DropdownMenuItem<Task>(
                        value: template,
                        child: Text(template.name),
                      );
                    }).toList(),
                    decoration:
                        const InputDecoration(labelText: 'Select Template'),
                  );
                },
              ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TaskFrequency>(
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
                  child: Text(frequency.toString().split('.').last),
                );
              }).toList(),
              decoration: const InputDecoration(labelText: 'Frequency'),
            ),
            const SizedBox(height: 16),
            Consumer<RoommateProvider>(
              builder: (context, roommateProvider, child) {
                final roommates = roommateProvider.roommates;
                return DropdownButtonFormField<String>(
                  value: _assignedTo,
                  onChanged: (String? newValue) {
                    setState(() {
                      _assignedTo = newValue;
                    });
                  },
                  items: roommates.map((roommate) {
                    return DropdownMenuItem<String>(
                      value: roommate.name,
                      child: Text(roommate.name),
                    );
                  }).toList(),
                  decoration: const InputDecoration(labelText: 'Assigned To'),
                );
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _startDate = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Start Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _startDate.toString().split(' ')[0],
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate,
                  firstDate: _startDate,
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  setState(() {
                    _endDate = picked;
                  });
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'End Date',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _endDate.toString().split(' ')[0],
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.task != null)
              ElevatedButton(
                onPressed: _showSwapTaskDialog,
                child: const Text('Swap Task'),
              ),
          ],
        ),
      ),
    );
  }

  void _saveTask() {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    // Fix 3: Validate task name
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task name cannot be empty')),
      );
      return;
    }

    final task = Task(
      id: widget.task?.id ?? ServiceUtils.generateUniqueId(),
      name: _nameController.text.trim(),
      frequency: _frequency,
      startDate: _startDate,
      endDate: _endDate,
      assignedTo: _assignedTo,
      status: widget.task?.status ?? TaskStatus.pending,
      templateId: _isCustomTask ? null : _selectedTemplate?.id,
    );

    if (widget.task == null) {
      taskProvider.addAssignedTask(task);
    } else {
      taskProvider.updateAssignedTask(task);
    }

    Navigator.of(context).pop();
  }

  void _showSwapTaskDialog() {
    final roommateProvider =
        Provider.of<RoommateProvider>(context, listen: false);
    final roommates = roommateProvider.roommates.map((r) => r.name).toList();

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Swap task with'),
          children: roommates.map((roommate) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _swapTask(roommate);
              },
              child: Text(roommate),
            );
          }).toList(),
        );
      },
    );
  }

  void _swapTask(String newAssignee) {
    if (newAssignee != _assignedTo && widget.task != null) {
      // Fix 2: Persist the swap using TaskProvider
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      taskProvider.swapTask(widget.task!.id, newAssignee).then((_) {
        setState(() {
          _assignedTo = newAssignee;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Task swapped to $newAssignee')),
        );
      }).catchError((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to swap task: $error')),
        );
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
