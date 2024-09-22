import 'package:go_router/go_router.dart';
import 'package:gsheets/gsheets.dart';
import 'package:roomie_tasks/app/pages/add_roommates_page.dart';
import 'package:roomie_tasks/app/pages/add_tasks_page.dart';
import 'package:roomie_tasks/app/pages/googlesheets_setup_page.dart';
import 'package:roomie_tasks/app/pages/task_list_page.dart';

class AppRoutes {
  static const home = '/';
  static const addRoommates = '/add-roommates';
  static const addTasks = '/add-tasks';
  static const taskList = '/task-list';
}

final router = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const GoogleSheetsSetupPage(),
    ),
    GoRoute(
      path: AppRoutes.addRoommates,
      builder: (context, state) =>
          AddRoommatesPage(spreadsheet: state.extra! as Spreadsheet),
    ),
    GoRoute(
      path: AppRoutes.addTasks,
      builder: (context, state) =>
          AddTasksPage(spreadsheet: state.extra! as Spreadsheet),
    ),
    GoRoute(
      path: AppRoutes.taskList,
      builder: (context, state) =>
          TaskListPage(spreadsheet: state.extra! as Spreadsheet),
    ),
  ],
);
