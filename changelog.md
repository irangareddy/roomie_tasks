# Changelog

## [Unreleased]

### Added

- Implemented Google Sheets integration:
  - Created `GoogleSheetsService` for handling Google Sheets operations
  - Added `GoogleSheetsSetupPage` for user configuration of Google Sheets
  - Implemented credential upload and spreadsheet ID input
- Created `Task` model with JSON serialization and status enum
- Implemented `Roommate` model with JSON serialization
- Added `StorageService` abstract class and `HiveStorageService` implementation for local storage
- Created `TaskProvider` and `RoommateProvider` for state management
- Implemented `GoogleSheetsSetupProvider` for managing Google Sheets connection state
- Added `AddTasksPage` with functionality to add, edit, and remove tasks
- Implemented `AddRoommatesPage` with functionality to add, edit, and remove roommates
- Created `AppRoutes` for centralized routing management
- Added `bootstrap` function for app initialization and error handling
- Implemented `DependencyManager` for dependency injection using `get_it`
- Created `RoommateService` and `TaskService` for handling roommate and task operations
- Added `ServiceUtils` for common utility functions used across services
- Implemented automatic loading of saved Google Sheets configuration

### Changed

- Updated project structure to follow a feature-based architecture
- Configured the app to use Material 3 design
- Updated `pubspec.yaml` with new dependencies:
  - Added `bloc` and `flutter_bloc` for state management
  - Added `go_router` for navigation
  - Added `gsheets` for Google Sheets integration
  - Added `hive` and `hive_flutter` for local storage
  - Added `uuid` for generating unique identifiers
- Refactored `GoogleSheetsSetupProvider` to determine initial setup status based on stored credentials and spreadsheet ID
- Updated `AddRoommatesPage` to use a modal bottom sheet for adding new roommates
- Modified `RoommateProvider` to work with the new `RoommateService`

### Fixed

- Addressed potential null safety issues in `GoogleSheetsService`
- Improved error handling in Google Sheets connection process
- Fixed issue with duplicate roommate creation

### Removed

- N/A (No specific removals noted in this version)
