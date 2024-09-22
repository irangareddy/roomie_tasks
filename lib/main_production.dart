import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:roomie_tasks/app/app.dart';
import 'package:roomie_tasks/bootstrap.dart';
import 'package:roomie_tasks/dependency_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DependencyManager.init();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((value) async => bootstrap(() => const App()));
}
