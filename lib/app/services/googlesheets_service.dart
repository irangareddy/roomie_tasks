import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:roomie_tasks/app/services/services.dart';

class GoogleSheetsService {
  late GSheets _gsheets;
  late Spreadsheet _spreadsheet;
  late RoommateService roommateService;
  late TaskService taskService;
  late Worksheet _metadataSheet;

  Future<Spreadsheet> initialize(
    String credentials,
    String spreadsheetId,
  ) async {
    _gsheets = GSheets(credentials);
    try {
      _spreadsheet = await _gsheets.spreadsheet(spreadsheetId);
      await _initializeWorksheets();
      return _spreadsheet;
    } catch (e) {
      debugPrint('Error initializing GSheets: $e');
      throw Exception('Failed to initialize Google Sheets');
    }
  }

  Future<void> _initializeWorksheets() async {
    final taskTemplatesSheet =
        await ServiceUtils.getOrCreateWorksheet(_spreadsheet, 'HouseholdTasks');
    final assignedTasksSheet =
        await ServiceUtils.getOrCreateWorksheet(_spreadsheet, 'AssignedTasks');
    final roommatesSheet =
        await ServiceUtils.getOrCreateWorksheet(_spreadsheet, 'Roommates');
    _metadataSheet =
        await ServiceUtils.getOrCreateWorksheet(_spreadsheet, 'Metadata');

    roommateService = RoommateService(roommatesSheet);
    taskService = TaskService(taskTemplatesSheet, assignedTasksSheet, this);

    await roommateService.initialize(taskService);
    await taskService.initialize(roommateService);
    await ServiceUtils.ensureHeaders(_metadataSheet, ['Key', 'Value']);
  }

  // Metadata operations

  Future<String?> getMetadata(String key) async {
    final rows = await _metadataSheet.values.allRows();
    final rowIndex = rows.indexWhere((row) => row[0] == key);
    if (rowIndex != -1) {
      return rows[rowIndex][1];
    }
    return null;
  }

  Future<void> setMetadata(String key, String value) async {
    final rows = await _metadataSheet.values.allRows();
    final rowIndex = rows.indexWhere((row) => row[0] == key);
    if (rowIndex != -1) {
      await _metadataSheet.values.insertRow(rowIndex + 1, [key, value]);
    } else {
      await _metadataSheet.values.appendRow([key, value]);
    }
  }
}
