import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:roomie_tasks/app/pages/add_roommates_page.dart';
import 'package:roomie_tasks/app/pages/add_tasks_page.dart';
import 'package:roomie_tasks/app/pages/googlesheets_setup_page.dart';
import 'package:roomie_tasks/app/pages/task_list_page.dart';
import 'package:roomie_tasks/app/providers/googlesheets_setup_provider.dart';

class AppRoutes {
  static const home = '/';
  static const googleSheetsSetup = '/google-sheet-setup';
  static const addRoommates = '/add-roommates';
  static const addTasks = '/add-tasks';
  static const taskList = '/task-list';
}

final router = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const TaskListPage(),
      redirect: (context, state) async {
        final setupProvider =
            Provider.of<GoogleSheetsSetupProvider>(context, listen: false);
        final isSetupComplete = await setupProvider.isSetupComplete();
        if (!isSetupComplete) {
          return AppRoutes.googleSheetsSetup;
        }
        return AppRoutes.taskList;
      },
    ),
    GoRoute(
      path: AppRoutes.googleSheetsSetup,
      builder: (context, state) => const GoogleSheetsSetupPage(),
    ),
    GoRoute(
      path: AppRoutes.addRoommates,
      builder: (context, state) => const AddRoommatesPage(),
    ),
    GoRoute(
      path: AppRoutes.addTasks,
      builder: (context, state) => const AddTasksPage(),
    ),
    GoRoute(
      path: AppRoutes.taskList,
      builder: (context, state) => const TaskListPage(),
    ),
  ],
);
