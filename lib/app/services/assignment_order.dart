import 'dart:convert';
import 'dart:math';

class AssignmentOrder {
  AssignmentOrder({
    required this.taskToRoommateIndex,
    required this.lastAssignmentDates,
    required this.lastUpdated,
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
    );
  }

  final Map<String, Map<String, int>> taskToRoommateIndex;
  final Map<String, Map<String, DateTime>> lastAssignmentDates;
  DateTime lastUpdated;

  // Core functionality
  String getNextRoommate(
    String taskName,
    List<String> currentRoommates,
    DateTime assignmentDate,
  ) {
    final roommateIndexMap = taskToRoommateIndex[taskName]!;

    final daysSinceLastAssignment = <String, int>{};
    for (final roommate in currentRoommates) {
      daysSinceLastAssignment[roommate] =
          _getDaysSinceLastAssignment(taskName, roommate, assignmentDate);
    }

    final nextRoommate = roommateIndexMap.entries
        .where((entry) => currentRoommates.contains(entry.key))
        .reduce((a, b) {
      final aDays = daysSinceLastAssignment[a.key]!;
      final bDays = daysSinceLastAssignment[b.key]!;
      if (a.value == b.value) {
        return aDays > bDays ? a : b;
      }
      return a.value < b.value ? a : b;
    }).key;

    roommateIndexMap[nextRoommate] = roommateIndexMap[nextRoommate]! + 1;
    _updateLastAssignmentDate(taskName, nextRoommate, assignmentDate);

    return nextRoommate;
  }

  void normalizeAssignmentCounts() {
    for (final taskMap in taskToRoommateIndex.values) {
      final minCount = taskMap.values.reduce(min);
      final maxCount = taskMap.values.reduce(max);

      if (maxCount - minCount > 10) {
        for (final roommate in taskMap.keys) {
          taskMap[roommate] = ((taskMap[roommate]! - minCount) / 2).round();
        }
      }
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
          value.map(
            (k, v) => MapEntry(k, v.toIso8601String()),
          ),
        ),
      ),
      'lastUpdated': lastUpdated.toIso8601String(),
    });
  }
}
