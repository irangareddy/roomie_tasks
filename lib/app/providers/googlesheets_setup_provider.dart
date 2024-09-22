import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gsheets/gsheets.dart';
import 'package:roomie_tasks/app/services/services.dart';
import 'package:roomie_tasks/dependency_manager.dart';

class GoogleSheetsSetupProvider extends ChangeNotifier {
  GoogleSheetsSetupProvider(this._sheetsService)
      : _storageService = sl<StorageService>() {
    _loadSavedConfig();
  }
  final GoogleSheetsService _sheetsService;
  final StorageService _storageService;

  bool _isConnected = false;
  String _spreadsheetId = '';
  Spreadsheet? _spreadsheet;

  bool get isConnected => _isConnected;
  String get spreadsheetId => _spreadsheetId;
  Spreadsheet? get spreadsheet => _spreadsheet;

  Future<void> _loadSavedConfig() async {
    _spreadsheetId =
        _storageService.get(StorageKey.spreadsheetId) as String? ?? '';
    final credentials = _storageService.get(StorageKey.credentials) as String?;
    if (credentials != null && _spreadsheetId.isNotEmpty) {
      await _initializeGSheets(credentials, _spreadsheetId);
    }
    notifyListeners();
  }

  Future<void> setCredentials(File file) async {
    final contents = await file.readAsString();
    debugPrint(contents);
    debugPrint(_spreadsheetId);
    await _storageService.set(StorageKey.credentials, contents);
    await _initializeGSheets(contents, _spreadsheetId);
  }

  Future<void> setSpreadsheetId(String id) async {
    _spreadsheetId = id;
    await _storageService.set(StorageKey.spreadsheetId, id);
    notifyListeners();
  }

  Future<void> _initializeGSheets(
      String credentials, String spreadsheetId,) async {
    try {
      _spreadsheet =
          await _sheetsService.initialize(credentials, spreadsheetId);
      _isConnected = true;
    } catch (e) {
      debugPrint('Error initializing GSheets: $e');
      _isConnected = false;
      _spreadsheet = null;
    }
    notifyListeners();
  }

  Future<void> connect() async {
    final credentials = _storageService.get(StorageKey.credentials) as String?;
    debugPrint(credentials);
    if (credentials != null) {
      await _initializeGSheets(credentials, _spreadsheetId);
    } else {
      debugPrint('Unable to connect');
      throw Exception('Credentials not found');
    }
  }
}
