// lib/services/google_sheets_service.dart

import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:roomie_tasks/app/models/task.dart';

class GoogleSheetsService {
  late GSheets? _gsheets;
  late Spreadsheet? _spreadsheet;
  late Worksheet? _tasksSheet;
  late Worksheet? _roommatesSheet;
  late Worksheet? _metadataSheet;

  Future<Spreadsheet> initialize(
    String? credentials,
    String? spreadsheetId,
  ) async {
    if (credentials == null || spreadsheetId == null) {
      throw Exception('Credentials or spreadsheet ID not found');
    }

    debugPrint(credentials);
    debugPrint(spreadsheetId);

    _gsheets = GSheets(credentials);
    try {
      _spreadsheet = await _gsheets!.spreadsheet(spreadsheetId);
      await _initializeWorksheets();
      return _spreadsheet!;
    } catch (e) {
      debugPrint('Error initializing GSheets: $e');
      throw Exception('Failed to initialize Google Sheets');
    }
  }

  Future<void> _initializeWorksheets() async {
    _tasksSheet = await _getOrCreateWorksheet('Tasks');
    _roommatesSheet = await _getOrCreateWorksheet('Roommates');
    _metadataSheet = await _getOrCreateWorksheet('Metadata');

    await _ensureHeaders(_tasksSheet!, [
      'Id',
      'Name',
      'AssignedTo',
      'StartDate',
      'EndDate',
      'Status',
      'OriginalAssignee',
    ]);
    await _ensureHeaders(_roommatesSheet!, ['Name']);
    await _ensureHeaders(_metadataSheet!, ['Key', 'Value']);
  }

  Future<Worksheet> _getOrCreateWorksheet(String title) async {
    final worksheet = _spreadsheet!.worksheetByTitle(title);
    return worksheet ?? await _spreadsheet!.addWorksheet(title);
  }

  Future<void> _ensureHeaders(Worksheet sheet, List<String> headers) async {
    final existingHeaders = await sheet.values.row(1);
    if (existingHeaders.isEmpty) {
      await sheet.values.insertRow(1, headers);
    }
  }

  // Task operations

  Future<List<Task>> loadTasks() async {
    final rows = await _tasksSheet!.values.allRows(fromRow: 2);
    return rows
        .map(
          (row) => Task.fromJson({
            'id': row[0],
            'name': row[1],
            'assignedTo': row[2],
            'startDate': row[3],
            'endDate': row[4],
            'status': row[5],
            'originalAssignee': row[6],
          }),
        )
        .toList();
  }

  Future<void> addTask(Task task) async {
    await _tasksSheet!.values.appendRow(_taskToRow(task));
  }

  Future<void> updateTask(Task task) async {
    final rowIndex = await _findRowIndexById(_tasksSheet!, task.id);
    if (rowIndex != null) {
      await _tasksSheet!.values.insertRow(rowIndex, _taskToRow(task));
    }
  }

  Future<void> deleteTask(String taskId) async {
    final rowIndex = await _findRowIndexById(_tasksSheet!, taskId);
    if (rowIndex != null) {
      await _tasksSheet!.deleteRow(rowIndex);
    }
  }

  List<String> _taskToRow(Task task) {
    return [
      task.id,
      task.name,
      task.assignedTo,
      task.startDate.toIso8601String(),
      task.endDate.toIso8601String(),
      task.status.toString().split('.').last,
      task.originalAssignee,
    ];
  }

  // Roommates operations

  Future<List<String>> loadRoommates() async {
    final rows = await _roommatesSheet!.values.allRows(fromRow: 2);
    return rows.map((row) => row[0]).toList();
  }

  Future<void> addRoommate(String name) async {
    await _roommatesSheet!.values.appendRow([name]);
  }

  Future<void> updateRoommate(String oldName, String newName) async {
    final rowIndex = await _findRowIndexByName(_roommatesSheet!, oldName);
    if (rowIndex != null) {
      await _roommatesSheet!.values.insertRow(rowIndex, [newName]);
    }
  }

  Future<void> deleteRoommate(String name) async {
    final rowIndex = await _findRowIndexByName(_roommatesSheet!, name);
    if (rowIndex != null) {
      await _roommatesSheet!.deleteRow(rowIndex);
    }
  }

  // Metadata operations

  Future<String?> getMetadata(String key) async {
    final rows = await _metadataSheet!.values.allRows();
    final rowIndex = rows.indexWhere((row) => row[0] == key);
    if (rowIndex != -1) {
      return rows[rowIndex][1];
    }
    return null;
  }

  Future<void> setMetadata(String key, String value) async {
    final rows = await _metadataSheet!.values.allRows();
    final rowIndex = rows.indexWhere((row) => row[0] == key);
    if (rowIndex != -1) {
      await _metadataSheet!.values.insertRow(rowIndex + 1, [key, value]);
    } else {
      await _metadataSheet!.values.appendRow([key, value]);
    }
  }

  // Helper methods

  Future<int?> _findRowIndexById(Worksheet sheet, String id) async {
    final column = await sheet.values.column(1, fromRow: 2);
    final rowIndex = column.indexOf(id);
    return rowIndex != -1 ? rowIndex + 2 : null;
  }

  Future<int?> _findRowIndexByName(Worksheet sheet, String name) async {
    final column = await sheet.values.column(1, fromRow: 2);
    final rowIndex = column.indexOf(name);
    return rowIndex != -1 ? rowIndex + 2 : null;
  }
}
