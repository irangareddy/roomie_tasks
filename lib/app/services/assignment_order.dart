import 'dart:convert';
import 'dart:math';

import 'package:roomie_tasks/app/models/task.dart';

class AssignmentOrder {
  AssignmentOrder({
    required this.taskToRoommateIndex,
    required this.lastAssignmentDates,
    required this.lastUpdated,
    required this.fairnessScores,
  });
  factory AssignmentOrder.fromJson(String jsonString) {
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return AssignmentOrder(
      taskToRoommateIndex:
          (jsonMap['taskToRoommateIndex'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, v as int),
          ),
        ),
      ),
      lastAssignmentDates:
          (jsonMap['lastAssignmentDates'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          (value as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, DateTime.parse(v as String)),
          ),
        ),
      ),
      lastUpdated: DateTime.parse(jsonMap['lastUpdated'] as String),
      fairnessScores: (jsonMap['fairnessScores'] as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, v as double),
      ),
    );
  }

  // Factory constructors
  factory AssignmentOrder.initialize(
    List<String> roommates,
    List<String> tasks,
  ) {
    return AssignmentOrder(
      taskToRoommateIndex: {
        for (final task in tasks)
          task: {for (final roommate in roommates) roommate: 0},
      },
      lastAssignmentDates: {for (final task in tasks) task: {}},
      lastUpdated: DateTime.now(),
      fairnessScores: {for (final roommate in roommates) roommate: 0.0},
    );
  }

  final Map<String, Map<String, int>> taskToRoommateIndex;
  final Map<String, Map<String, DateTime>> lastAssignmentDates;
  final Map<String, double> fairnessScores;
  DateTime lastUpdated;

  String getNextRoommate(
    String taskName,
    List<String> currentRoommates,
    DateTime assignmentDate,
  ) {
    final roommateScores = <String, double>{};

    for (final roommate in currentRoommates) {
      final daysSinceLastAssignment =
          _getDaysSinceLastAssignment(taskName, roommate, assignmentDate);
      final fairnessScore = fairnessScores[roommate] ?? 0.0;

      // Lower score is better (less tasks assigned recently)
      roommateScores[roommate] = fairnessScore - (daysSinceLastAssignment / 7);
    }

    // Find the roommate with the lowest score
    final nextRoommate =
        roommateScores.entries.reduce((a, b) => a.value < b.value ? a : b).key;

    // Update the assignment order
    updateAssignment(taskName, nextRoommate);

    return nextRoommate;
  }

  void updateAssignment(String taskName, String roommate) {
    taskToRoommateIndex.putIfAbsent(taskName, () => {})[roommate] =
        (taskToRoommateIndex[taskName]?[roommate] ?? 0) + 1;
    _updateLastAssignmentDate(taskName, roommate, DateTime.now());
    _updateFairnessScore(roommate, TaskFrequency.daily);
    lastUpdated = DateTime.now();
  }

  void _updateFairnessScore(String roommate, TaskFrequency frequency) {
    final frequencyScore = _getFrequencyScore(frequency);
    fairnessScores[roommate] =
        (fairnessScores[roommate] ?? 0.0) + frequencyScore;
  }

  double _getFrequencyScore(TaskFrequency frequency) {
    switch (frequency) {
      case TaskFrequency.daily:
        return 1;
      case TaskFrequency.weekly:
        return 0.5;
      case TaskFrequency.twiceWeekly:
        return 0.75;
      case TaskFrequency.thriceWeekly:
        return 0.9;
      case TaskFrequency.monthly:
        return 0.25;
      default:
        return 0.5;
    }
  }

  void normalizeAssignmentCounts() {
    for (final taskMap in taskToRoommateIndex.values) {
      final minCount = taskMap.values.reduce(min);
      for (final roommate in taskMap.keys) {
        taskMap[roommate] = taskMap[roommate]! - minCount;
      }
    }

    // Normalize fairness scores
    final minScore = fairnessScores.values.reduce(min);
    for (final roommate in fairnessScores.keys) {
      fairnessScores[roommate] = fairnessScores[roommate]! - minScore;
    }

    lastUpdated = DateTime.now();
  }

  // Task management
  void addTask(String taskName, List<String> roommates) {
    if (!taskToRoommateIndex.containsKey(taskName)) {
      taskToRoommateIndex[taskName] = {
        for (final roommate in roommates) roommate: 0,
      };
    }
  }

  void removeTask(String taskName) {
    taskToRoommateIndex.remove(taskName);
  }

  // Roommate management
  void addRoommate(String newRoommateName) {
    for (final taskMap in taskToRoommateIndex.values) {
      final averageCount = taskMap.values.isEmpty
          ? 0
          : taskMap.values.reduce((a, b) => a + b) ~/ taskMap.length;
      taskMap[newRoommateName] = averageCount;
    }
    lastUpdated = DateTime.now();
  }

  void removeRoommate(String roommateName) {
    for (final taskMap in taskToRoommateIndex.values) {
      if (taskMap.containsKey(roommateName)) {
        final removedCount = taskMap.remove(roommateName)!;
        final distributedCount = removedCount ~/ taskMap.length;
        for (final otherRoommate in taskMap.keys) {
          taskMap[otherRoommate] = taskMap[otherRoommate]! + distributedCount;
        }
      }
    }
    lastUpdated = DateTime.now();
  }

  void updateRoommates(List<String> currentRoommates) {
    for (final task in taskToRoommateIndex.keys) {
      final roommateIndexMap = taskToRoommateIndex[task]!;

      for (final roommate in currentRoommates) {
        if (!roommateIndexMap.containsKey(roommate)) {
          roommateIndexMap[roommate] = 0;
        }
      }

      roommateIndexMap
          .removeWhere((key, value) => !currentRoommates.contains(key));
    }

    lastUpdated = DateTime.now();
  }

  void changeRoommateName(String oldName, String newName) {
    for (final taskMap in taskToRoommateIndex.values) {
      if (taskMap.containsKey(oldName)) {
        taskMap[newName] = taskMap.remove(oldName)!;
      }
    }
    lastUpdated = DateTime.now();
  }

  // Helper methods
  int _getDaysSinceLastAssignment(
    String taskName,
    String roommate,
    DateTime now,
  ) {
    final lastDate = lastAssignmentDates[taskName]?[roommate];
    return lastDate != null
        ? now.difference(lastDate).inDays
        : 365; // Default to a year if never assigned
  }

  void _updateLastAssignmentDate(
    String taskName,
    String roommate,
    DateTime date,
  ) {
    lastAssignmentDates.putIfAbsent(taskName, () => {})[roommate] = date;
  }

  // Serialization
  String toJson() {
    return json.encode({
      'taskToRoommateIndex': taskToRoommateIndex,
      'lastAssignmentDates': lastAssignmentDates.map(
        (key, value) => MapEntry(
          key,
          value.map((k, v) => MapEntry(k, v.toIso8601String())),
        ),
      ),
      'lastUpdated': lastUpdated.toIso8601String(),
      'fairnessScores': fairnessScores,
    });
  }
}
