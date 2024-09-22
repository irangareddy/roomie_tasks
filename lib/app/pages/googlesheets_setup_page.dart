import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/providers/googlesheets_setup_provider.dart';
import 'package:roomie_tasks/config/routes/routes.dart';

class GoogleSheetsSetupPage extends StatelessWidget {
  const GoogleSheetsSetupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Google Sheets Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Consumer<GoogleSheetsSetupProvider>(
          builder: (context, provider, child) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildCredentialsUploadButton(context, provider),
                const SizedBox(height: 20),
                _buildSpreadsheetIdField(provider),
                const SizedBox(height: 20),
                _buildConnectButton(context, provider),
                const SizedBox(height: 20),
                _buildConnectionStatus(provider),
                const SizedBox(height: 20),
                _buildNextButton(context, provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCredentialsUploadButton(
    BuildContext context,
    GoogleSheetsSetupProvider provider,
  ) {
    return ElevatedButton(
      onPressed: () => _pickCredentialsFile(context, provider),
      child: const Text('Upload Google Sheets Config'),
    );
  }

  Widget _buildSpreadsheetIdField(GoogleSheetsSetupProvider provider) {
    return TextField(
      onChanged: provider.setSpreadsheetId,
      decoration: const InputDecoration(
        labelText: 'Spreadsheet ID',
        border: OutlineInputBorder(),
      ),
      controller: TextEditingController(text: provider.spreadsheetId),
    );
  }

  Widget _buildConnectButton(
    BuildContext context,
    GoogleSheetsSetupProvider provider,
  ) {
    return ElevatedButton(
      onPressed: () => _connectToGoogleSheets(context, provider),
      child: const Text('Connect to Google Sheets'),
    );
  }

  Widget _buildConnectionStatus(GoogleSheetsSetupProvider provider) {
    return Text(
      provider.isConnected ? 'Connected to Google Sheets' : 'Not connected',
      style: TextStyle(
        color: provider.isConnected ? Colors.green : Colors.red,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNextButton(
    BuildContext context,
    GoogleSheetsSetupProvider provider,
  ) {
    return ElevatedButton(
      onPressed: provider.isConnected && provider.spreadsheet != null
          ? () => context.go(
                AppRoutes.addRoommates,
                extra: provider.spreadsheet,
              )
          : null,
      child: const Text('Next: Add Roommates'),
    );
  }

  Future<void> _pickCredentialsFile(
    BuildContext context,
    GoogleSheetsSetupProvider provider,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      final file = File(result.files.single.path!);
      await provider.setCredentials(file);
    }
  }

  Future<void> _connectToGoogleSheets(
    BuildContext context,
    GoogleSheetsSetupProvider provider,
  ) async {
    debugPrint('Pressed connect');
    try {
      await provider.connect();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully connected to Google Sheets!'),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Error connecting to Google Sheets. '
              'Please check your credentials and spreadsheet ID.',
            ),
          ),
        );
      }
    }
  }
}
