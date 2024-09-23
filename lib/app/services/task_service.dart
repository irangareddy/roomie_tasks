import 'dart:math' as math;

import 'package:gsheets/gsheets.dart';
import 'package:roomie_tasks/app/models/task.dart';
import 'package:roomie_tasks/app/services/assignment_order.dart';
import 'package:roomie_tasks/app/services/services.dart';

class TaskService {
  // Constructor
  TaskService(
    this.taskTemplatesSheet,
    this.assignedTasksSheet,
    this.googleSheetsService,
  );

  // Fields
  final Worksheet taskTemplatesSheet;
  final Worksheet assignedTasksSheet;
  final GoogleSheetsService googleSheetsService;
  late RoommateService roommateService;
  late AssignmentOrder _assignmentOrder;

  // Initialization methods
  Future<void> initialize(RoommateService roommateService) async {
    this.roommateService = roommateService;
    await ServiceUtils.ensureHeaders(taskTemplatesSheet, [
      'Id',
      'Name',
      'Frequency',
    ]);
    await ServiceUtils.ensureHeaders(assignedTasksSheet, [
      'Id',
      'TemplateId',
      'Name',
      'Frequency',
      'AssignedTo',
      'StartDate',
      'EndDate',
      'Status',
      'OriginalAssignee',
    ]);
    await _initializeAssignmentOrder();
  }

  Future<void> _initializeAssignmentOrder() async {
    final savedOrder = await getMetadata('assignmentOrder');
    if (savedOrder != null) {
      _assignmentOrder = AssignmentOrder.fromJson(savedOrder);
    } else {
      final roommates = await roommateService.loadRoommates();
      final tasks = await loadTaskTemplates();
      _assignmentOrder = AssignmentOrder.initialize(
        roommates.map((r) => r.name).toList(),
        tasks.map((t) => t.name).toList(),
      );
      await _saveAssignmentOrder();
    }
  }

  // CRUD operations for task templates
  Future<List<Task>> loadTaskTemplates() async {
    final rows = await taskTemplatesSheet.values.allRows(fromRow: 2);
    return rows.map(_rowToTaskTemplate).toList();
  }

  Future<void> addTaskTemplate(Task task) async {
    await taskTemplatesSheet.values.appendRow(_taskTemplateToRow(task));
  }

  Future<void> updateTaskTemplate(Task task) async {
    final rowIndex =
        await ServiceUtils.findRowIndexById(taskTemplatesSheet, task.id);
    if (rowIndex != null) {
      await taskTemplatesSheet.values
          .insertRow(rowIndex, _taskTemplateToRow(task));
    }
  }

  Future<void> deleteTaskTemplate(String taskId) async {
    final rowIndex =
        await ServiceUtils.findRowIndexById(taskTemplatesSheet, taskId);
    if (rowIndex != null) {
      await taskTemplatesSheet.deleteRow(rowIndex);
    }
  }

  // CRUD operations for assigned tasks
  Future<List<Task>> loadAssignedTasks() async {
    print('called load assigned tasks in task service');
    final rows = await assignedTasksSheet.values.allRows(fromRow: 2);
    print(rows);
    return rows
        .map((row) {
          try {
            return _rowToAssignedTask(row);
          } catch (e) {
            Exception('Error: $e');
            return null;
          }
        })
        .where((task) => task != null)
        .cast<Task>()
        .toList();
  }

  Future<void> addAssignedTask(Task task) async {
    final taskWithOriginalAssignee = task.originalAssignee == null
        ? task.copyWith(originalAssignee: task.assignedTo)
        : task;

    // Only update assignment order for tasks with a templateId
    if (taskWithOriginalAssignee.templateId != null) {
      _assignmentOrder.updateAssignment(
        taskWithOriginalAssignee.name,
        taskWithOriginalAssignee.assignedTo!,
      );
    }

    await assignedTasksSheet.values
        .appendRow(_assignedTaskToRow(taskWithOriginalAssignee));
  }

  Future<void> updateAssignedTask(Task task) async {
    final rowIndex =
        await ServiceUtils.findRowIndexById(assignedTasksSheet, task.id);
    if (rowIndex != null) {
      final existingTask =
          _rowToAssignedTask(await assignedTasksSheet.values.row(rowIndex));
      final updatedTask = task.copyWith(
        originalAssignee:
            existingTask.originalAssignee ?? existingTask.assignedTo,
      );
      await assignedTasksSheet.values
          .insertRow(rowIndex, _assignedTaskToRow(updatedTask));
    }
  }

  Future<void> deleteAssignedTask(String taskId) async {
    final rowIndex =
        await ServiceUtils.findRowIndexById(assignedTasksSheet, taskId);
    if (rowIndex != null) {
      await assignedTasksSheet.deleteRow(rowIndex);
    }
  }

  // Task generation and scheduling methods
  Future<List<Task>> generateWeeklyTasks(
    List<String> roommates,
    DateTime startDate,
  ) async {
    try {
      await clearFutureTasks();
      final endDate = startDate.add(const Duration(days: 7));
      final taskTemplates = await loadTaskTemplates();
      final assignedTasks = <Task>[];

      for (final template in taskTemplates) {
        if (_shouldAssignTaskThisWeek(template.frequency, startDate)) {
          final assignedRoommate = _assignmentOrder.getNextRoommate(
            template.name,
            roommates,
            startDate,
          );
          final assignedTask = Task(
            id: ServiceUtils.generateUniqueId(),
            templateId: template.id,
            name: template.name,
            frequency: template.frequency,
            startDate: startDate,
            endDate: endDate,
            assignedTo: assignedRoommate,
            originalAssignee: assignedRoommate,
          );
          assignedTasks.add(assignedTask);
          await addAssignedTask(assignedTask);
        }
      }

      await _saveAssignmentOrder();

      return assignedTasks;
    } catch (e) {
      print('Error generating weekly tasks: $e');
      return [];
    }
  }

  Future<void> generateTasksIfNeeded() async {
    final lastGenerationDate = DateTime.parse(
      await getMetadata('lastTaskGenerationDate') ?? '2000-01-01',
    );
    final today = DateTime.now();

    if (today.difference(lastGenerationDate).inDays >= 7) {
      final roommates = await roommateService.loadRoommates();
      final roommateNames = roommates.map((r) => r.name).toList();

      final startDate = lastGenerationDate.add(const Duration(days: 7));
      await generateWeeklyTasks(roommateNames, startDate);

      await setMetadata('lastTaskGenerationDate', today.toIso8601String());
    }
  }

  Future<void> clearFutureTasks() async {
    final now = DateTime.now();
    final assignedTasks = await loadAssignedTasks();
    for (final task in assignedTasks) {
      if (task.startDate != null && task.startDate!.isAfter(now)) {
        await deleteAssignedTask(task.id);
      }
    }
  }

  Future<void> wipeOffAssignedTasks() async {
    final rowCount = assignedTasksSheet.rowCount;
    if (rowCount > 1) {
      await assignedTasksSheet.deleteRow(2, count: rowCount - 1);
    }
  }

  Future<void> reviseSchedule() async {
    final roommates = await roommateService.loadRoommates();
    final roommateNames = roommates.map((r) => r.name).toList();

    _assignmentOrder.updateRoommates(roommateNames);
    await clearFutureTasks();

    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    for (var i = 0; i < 4; i++) {
      await generateWeeklyTasks(
        roommateNames,
        startOfWeek.add(Duration(days: 7 * i)),
      );
    }

    await _saveAssignmentOrder();
  }

  // Roommate-related methods
  Future<void> swapTask(String taskId, String newAssignee) async {
    final task = (await loadAssignedTasks()).firstWhere((t) => t.id == taskId);
    final originalAssignee = task.assignedTo;

    final updatedTask = task.copyWith(
      assignedTo: newAssignee,
      originalAssignee: task.originalAssignee ?? originalAssignee,
    );

    await updateAssignedTask(updatedTask);

    // Update assignment order only for template-based tasks
    if (updatedTask.templateId != null) {
      _assignmentOrder.updateAssignment(updatedTask.name, newAssignee);
      await _saveAssignmentOrder();
    }

    final tasksToSwap = await loadAssignedTasks();
    Task? taskToSwapBack;
    try {
      taskToSwapBack = tasksToSwap.firstWhere(
        (t) =>
            t.assignedTo == newAssignee &&
            t.id != taskId &&
            t.templateId != null,
      );
    } catch (e) {
      // No task found to swap back
    }

    if (taskToSwapBack != null) {
      final swappedBackTask = taskToSwapBack.copyWith(
        assignedTo: originalAssignee,
        originalAssignee:
            taskToSwapBack.originalAssignee ?? taskToSwapBack.assignedTo,
      );
      await updateAssignedTask(swappedBackTask);
      _assignmentOrder.updateAssignment(
          swappedBackTask.name, originalAssignee!,);
      await _saveAssignmentOrder();
    }
  }

  Future<void> changeRoommateName(String oldName, String newName) async {
    _assignmentOrder.changeRoommateName(oldName, newName);
    await _saveAssignmentOrder();
    await _updateRoommateNameInAssignedTasks(oldName, newName);
  }

  Future<void> removeRoommate(String roommateName) async {
    _assignmentOrder.removeRoommate(roommateName);
    await _saveAssignmentOrder();
    await _reassignTasksFromRemovedRoommate(roommateName);
  }

  Future<void> addRoommate(String newRoommateName) async {
    _assignmentOrder.addRoommate(newRoommateName);
    await _saveAssignmentOrder();
    await _assignTasksToNewRoommate(newRoommateName);
  }

  Future<void> _updateRoommateNameInAssignedTasks(
    String oldName,
    String newName,
  ) async {
    final tasks = await loadAssignedTasks();
    for (final task in tasks) {
      if (task.assignedTo == oldName) {
        task.assignedTo = newName;
        if (task.originalAssignee == oldName) {
          task.originalAssignee = newName;
        }
        await updateAssignedTask(task);
      }
    }
  }

  Future<void> _reassignTasksFromRemovedRoommate(String removedRoommate) async {
    try {
      final tasks = await loadAssignedTasks();
      final remainingRoommates = await roommateService.loadRoommates();
      final remainingNames = remainingRoommates.map((r) => r.name).toList();
      final now = DateTime.now();

      for (final task in tasks) {
        if (task.assignedTo == removedRoommate) {
          final assignmentDate =
              task.startDate!.isAfter(now) ? task.startDate : now;
          final newAssignee = _assignmentOrder.getNextRoommate(
            task.name,
            remainingNames,
            assignmentDate!,
          );
          final updatedTask = Task(
            id: task.id,
            templateId: task.templateId,
            name: task.name,
            frequency: task.frequency,
            startDate: assignmentDate,
            endDate: assignmentDate.add(const Duration(days: 7)),
            assignedTo: newAssignee,
            originalAssignee: newAssignee,
          );
          await deleteAssignedTask(task.id);
          await addAssignedTask(updatedTask);
        }
      }
      await _saveAssignmentOrder();
    } catch (e) {
      Exception('Error reassigning tasks from removed roommate: $e');
    }
  }

  Future<void> _assignTasksToNewRoommate(String newRoommate) async {
    final tasks = await loadTaskTemplates();
    final today = DateTime.now();
    final endOfWeek = today.add(Duration(days: 7 - today.weekday));

    for (final task in tasks) {
      if (_shouldAssignTaskThisWeek(task.frequency, today)) {
        final assignedTask = Task(
          id: ServiceUtils.generateUniqueId(),
          templateId: task.id,
          name: task.name,
          frequency: task.frequency,
          startDate: today,
          endDate: endOfWeek,
          assignedTo: newRoommate,
          originalAssignee: newRoommate,
        );
        await addAssignedTask(assignedTask);
      }
    }
  }

  // Utility methods
  Task _rowToTaskTemplate(List<String> row) {
    return Task(
      id: row[0],
      name: row[1],
      frequency: _parseFrequency(row[2]),
    );
  }

  Task _rowToAssignedTask(List<String> row) {
    return Task(
      id: row[0],
      templateId: row[1],
      name: row[2],
      frequency: _parseFrequency(row[3]),
      assignedTo: row[4],
      startDate: _parseExcelDate(row[5]),
      endDate: _parseExcelDate(row[6]),
      status: _parseStatus(row[7]),
      originalAssignee: row[8].isNotEmpty ? row[8] : row[4],
    );
  }

  List<String> _taskTemplateToRow(Task task) {
    return [
      task.id,
      task.name,
      task.frequency.name,
    ];
  }

  List<String> _assignedTaskToRow(Task task) {
    return [
      task.id,
      task.templateId ?? '',
      task.name,
      task.frequency.name,
      task.assignedTo ?? '',
      task.startDate?.toIso8601String() ?? '',
      task.endDate?.toIso8601String() ?? '',
      task.status.toString().split('.').last,
      task.originalAssignee ?? task.assignedTo ?? '',
    ];
  }

  DateTime? _parseExcelDate(String dateString) {
    if (dateString.isEmpty) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      try {
        final days = double.parse(dateString);
        return DateTime(1899, 12, 30).add(Duration(days: days.round()));
      } catch (e) {
        Exception('Error parsing date: $dateString');
        return null;
      }
    }
  }

  bool _shouldAssignTaskThisWeek(TaskFrequency frequency, DateTime weekStart) {
    switch (frequency) {
      case TaskFrequency.daily:
      case TaskFrequency.weekly:
      case TaskFrequency.twiceWeekly:
      case TaskFrequency.thriceWeekly:
        return true;
      case TaskFrequency.monthly:
        return weekStart.day <= 7;
      default:
        return false;
    }
  }

  TaskFrequency _parseFrequency(String frequencyString) {
    return TaskFrequency.values.firstWhere(
      (f) => f.name == frequencyString,
      orElse: () => TaskFrequency.weekly,
    );
  }

  TaskStatus _parseStatus(String statusString) {
    return TaskStatus.values.firstWhere(
      (s) => s.toString().split('.').last == statusString,
      orElse: () => TaskStatus.pending,
    );
  }

  // Metadata handling methods
  Future<void> _saveAssignmentOrder() async {
    await setMetadata('assignmentOrder', _assignmentOrder.toJson());
  }

  Future<String?> getMetadata(String key) async {
    return googleSheetsService.getMetadata(key);
  }

  Future<void> setMetadata(String key, String value) async {
    await googleSheetsService.setMetadata(key, value);
  }

  // Reporting and analytics methods
  Future<void> normalizeAssignmentCounts() async {
    _assignmentOrder.normalizeAssignmentCounts();
    await _saveAssignmentOrder();
  }

  Future<void> periodicNormalization() async {
    final lastNormalizationDate = DateTime.parse(
      await getMetadata('lastNormalizationDate') ?? '2000-01-01',
    );
    final today = DateTime.now();

    if (today.difference(lastNormalizationDate).inDays >= 30) {
      // Normalize monthly
      _assignmentOrder.normalizeAssignmentCounts();
      await _saveAssignmentOrder();
      await setMetadata('lastNormalizationDate', today.toIso8601String());
    }
  }

  Future<Map<String, dynamic>> generateFairnessReport() async {
    final report = <String, dynamic>{};
    final tasks = await loadTaskTemplates();
    final roommates = await roommateService.loadRoommates();

    for (final task in tasks) {
      final taskStats = <String, int>{};
      for (final roommate in roommates) {
        taskStats[roommate.name] =
            _assignmentOrder.taskToRoommateIndex[task.name]?[roommate.name] ??
                0;
      }
      report[task.name] = taskStats;
    }

    report['overall_balance'] = _calculateOverallBalance(report);
    return report;
  }

  double _calculateOverallBalance(Map<String, dynamic> report) {
    final totalCounts = <String, int>{};
    for (final taskStats in report.entries) {
      if (taskStats.key != 'overall_balance' &&
          taskStats.value is Map<String, int>) {
        for (final entry in (taskStats.value as Map<String, int>).entries) {
          totalCounts[entry.key] = (totalCounts[entry.key] ?? 0) + entry.value;
        }
      }
    }

    final counts = totalCounts.values.toList();
    if (counts.isEmpty) {
      return 100; // Perfect balance if no tasks
    }

    final average = counts.reduce((a, b) => a + b) / counts.length;
    if (average == 0) {
      return 100; // Perfect balance if no tasks assigned
    }

    final variance =
        counts.map((c) => math.pow(c - average, 2)).reduce((a, b) => a + b) /
            counts.length;
    final standardDeviation = math.sqrt(variance);

    // Calculate coefficient of variation (CV) and convert to a percentage
    final cv = standardDeviation / average;
    final balancePercentage = (1 - cv) * 100;

    // Ensure the result is between 0 and 100
    return math.max(0, math.min(100, balancePercentage));
  }
}
