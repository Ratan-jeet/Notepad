import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/lock_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'theme/app_theme.dart';

class NotepadApp extends StatefulWidget {
  const NotepadApp({super.key});

  @override
  State<NotepadApp> createState() => _NotepadAppState();
}

class _NotepadAppState extends State<NotepadApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<LockProvider>().lock();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lock = context.watch<LockProvider>();

    final Widget home;
    if (!settings.loaded || lock.initializing) {
      home = const _SplashView();
    } else if (lock.locked) {
      home = const LockScreen();
    } else {
      home = const HomeScreen();
    }

    return MaterialApp(
      title: 'Notepad',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(settings.accent),
      darkTheme: AppTheme.dark(settings.accent),
      themeMode: settings.themeMode,
      home: home,
    );
  }
}

class _SplashView extends StatelessWidget {
  const _SplashView();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: settings.accent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.edit_note, size: 52, color: Colors.white),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
