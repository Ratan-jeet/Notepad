import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'providers/lock_provider.dart';
import 'providers/notes_provider.dart';
import 'providers/settings_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsProvider();
  await settings.load();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<LockProvider>(
          create: (_) => LockProvider(settings)..init(),
        ),
        ChangeNotifierProvider<NotesProvider>(
          create: (_) => NotesProvider()..load(),
        ),
      ],
      child: const NotepadApp(),
    ),
  );
}
