# Changelog

## [Unreleased]

### Added

- Implemented Google Sheets integration:
  - Created `GoogleSheetsService` for handling Google Sheets operations
  - Added `GoogleSheetsSetupPage` for user configuration of Google Sheets
  - Implemented credential upload and spreadsheet ID input
- Created `Task` model with JSON serialization, status enum, and `originalAssignee` field
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
- Implemented task management features in `TaskService`:
  - Added `generateWeeklyTasks` method
  - Implemented `clearFutureTasks` method
  - Created `reviseSchedule` method for updating task assignments
  - Added `swapTask` functionality
  - Implemented `wipeOffAssignedTasks` method
- Created `AssignmentOrder` class for managing task assignment order
- Added `periodicNormalization` method for balancing task assignments
- Implemented `generateFairnessReport` method for analyzing task distribution
- Added `_calculateOverallBalance` method for quantifying fairness
- Enhanced `AddTasksPage` functionality:
  - Implemented a modal bottom sheet for adding new task templates
  - Added suggested tasks feature with emoji support
  - Implemented task frequency selection in the add task form
- Implemented onboarding experience:
  - Created `SplashScreen` widget for displaying onboarding pages
  - Added `OnboardingService` to manage onboarding state
  - Integrated SVG images for onboarding illustrations
  - Implemented page indicators and navigation buttons for onboarding flow
- Updated routing to include onboarding flow:
  - Added splash route to `AppRoutes`
  - Implemented redirection logic in `GoRouter` to handle onboarding state
- Added `flutter_svg` package for rendering SVG images

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
- Moved `reviseSchedule` method from `RoommateService` to `TaskService`
- Updated `TaskProvider` to use new `TaskService` methods
- Modified `Task` model to include `isSwapped` getter
- Refactored `GoogleSheetsService` to properly initialize `TaskService` and `RoommateService`
- Updated `AppRoutes` to include redirection logic for setup completion
- Updated `AddTasksPage` UI:
  - Improved layout of task template list
  - Added empty state message when no task templates exist
  - Refactored task addition process to use a modal bottom sheet
- Modified `GoRouter` configuration to start with the splash screen
- Updated `DependencyManager` to include `OnboardingService`
- Refactored `StorageService` to use an enum `StorageKey` for consistent key management  

### Fixed

- Addressed potential null safety issues in `GoogleSheetsService` and `GoogleSheetsSetupProvider`
- Improved error handling in Google Sheets connection process and `TaskService` methods
- Fixed issue with duplicate roommate creation
- Resolved issues with task template management in `AddTasksPage`:
  - Fixed task template addition and deletion
  - Improved error handling in task template operations
- Improved navigation flow to ensure users complete onboarding before accessing main app features

### Removed

- Removed redundant task assignment logic from `RoommateService`
