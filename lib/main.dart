import 'package:flutter/material.dart';

import 'app.dart';
import 'presentation/providers/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = AppState();

  runApp(PesaTrackApp(appState: appState));
}
