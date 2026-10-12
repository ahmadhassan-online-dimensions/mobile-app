import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'state/app_state.dart';
import 'theme.dart';

void main() {
  // Plugins (secure storage for the saved login) need the binding first.
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState()..start();
  runApp(MyApp(state: state));
}

class MyApp extends StatelessWidget {
  final AppState state;

  const MyApp({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'VUE & OR',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const SplashScreen(),
      ),
    );
  }
}
