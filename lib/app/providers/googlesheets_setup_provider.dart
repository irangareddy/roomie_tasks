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

  Future<bool> isSetupComplete() async {
    final credentials = _storageService.get(StorageKey.credentials) as String?;
    _spreadsheetId =
        _storageService.get(StorageKey.spreadsheetId) as String? ?? '';
    
    if (credentials != null && _spreadsheetId.isNotEmpty) {
      try {
        await _initializeGSheets(credentials, _spreadsheetId);
        return _isConnected;
      } catch (e) {
        debugPrint('Error during setup check: $e');
        return false;
      }
    }
    return false;
  }

  Future<void> _loadSavedConfig() async {
    await isSetupComplete();
    notifyListeners();
  }

  Future<void> setCredentials(File file) async {
    try {
      final contents = await file.readAsString();
      await _storageService.set(StorageKey.credentials, contents);
      await _initializeGSheets(contents, _spreadsheetId);
    } catch (e) {
      debugPrint('Error reading credentials file: $e');
      throw Exception('Error reading credentials file: $e');
    }
  }

  Future<void> setSpreadsheetId(String id) async {
    _spreadsheetId = id;
    await _storageService.set(StorageKey.spreadsheetId, id);
    notifyListeners();
  }

  Future<void> _initializeGSheets(
    String credentials,
    String spreadsheetId,
  ) async {
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
    debugPrint('Stored credentials: $credentials');
    if (credentials != null) {
      await _initializeGSheets(credentials, _spreadsheetId);
    } else {
      debugPrint('Unable to connect: Credentials not found');
      throw Exception('Credentials not found');
    }
  }
}
