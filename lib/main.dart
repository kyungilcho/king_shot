import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/defense_shooter_app.dart';

export 'app/defense_shooter_app.dart' show DefenseShooterApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const DefenseShooterApp());
}
