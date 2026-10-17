import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lock_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/settings_provider.dart';
import '../services/export_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _managePin(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final lock = context.read<LockProvider>();

    if (settings.pinEnabled) {
      final current = await showPinDialog(
        context,
        title: 'Enter current PIN',
      );
      if (current == null || !settings.verifyPin(current)) {
        if (context.mounted && current != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect PIN')),
          );
        }
        return;
      }
    }

    if (!context.mounted) return;
    final first = await showPinDialog(context, title: 'Choose a 4-digit PIN');
    if (first == null) return;
    if (!context.mounted) return;
    final second = await showPinDialog(context, title: 'Confirm PIN');
    if (second == null) return;

    if (first != second) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PINs did not match, try again')),
        );
      }
      return;
    }
    await settings.setPin(first);
    lock.lock();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN set — app will lock on next start')),
      );
    }
  }

  Future<void> _removePin(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final lock = context.read<LockProvider>();
    final current = await showPinDialog(context, title: 'Enter current PIN');
    if (current == null) return;
    if (!settings.verifyPin(current)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incorrect PIN')),
        );
      }
      return;
    }
    await settings.removePin();
    lock.unlock();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN removed')),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final notes = context.read<NotesProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final pickedList = await FilePicker.pickFiles(type: FileType.any);
    if (pickedList.isEmpty) return;
    final picked = pickedList.first;
    try {
      final bytes = await picked.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);
      final imported = ExportService.parseBackup(content);

      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Restore backup?'),
          content: Text(
            'All ${notes.notes.length} existing note(s) will be replaced by '
            '${imported.length} note(s) from this backup.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      await notes.replaceAll(imported);
      messenger.showSnackBar(
        SnackBar(content: Text('Restored ${imported.length} notes')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Restore failed: invalid backup file')),
      );
    }
  }

  Future<void> _importTextFile(BuildContext context) async {
    final notes = context.read<NotesProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final pickedList = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt', 'md'],
    );
    if (pickedList.isEmpty) return;
    final picked = pickedList.first;
    try {
      final bytes = await picked.readAsBytes();
      final content = utf8.decode(bytes, allowMalformed: true);
      if (content.trim().isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('That file is empty')),
        );
        return;
      }
      final note = ExportService.noteFromText(content);
      await notes.add(note);
      messenger.showSnackBar(
        SnackBar(content: Text('Imported "${note.displayTitle}"')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Import failed: could not read file')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final lock = context.watch<LockProvider>();
    final notes = context.watch<NotesProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SectionLabel('Appearance'),
          Card(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.brightness_auto),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode_outlined),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode_outlined),
                          ),
                        ],
                        selected: {settings.themeMode},
                        onSelectionChanged: (selection) =>
                            settings.setThemeMode(selection.first),
                      ),
                      const SizedBox(height: 20),
                      Text('Accent color', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          for (final value in AppTheme.accentChoices)
                            GestureDetector(
                              onTap: () => settings.setAccent(value),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(value),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: settings.accentValue == value
                                        ? theme.colorScheme.onSurface
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                ),
                                child: settings.accentValue == value
                                    ? const Icon(Icons.check,
                                        size: 18, color: Colors.white)
                                    : null,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text('Editor text size',
                              style: theme.textTheme.titleSmall),
                          const Spacer(),
                          Text(
                            '${settings.editorFontSize.round()}',
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                      Slider(
                        value: settings.editorFontSize,
                        min: 12,
                        max: 24,
                        divisions: 12,
                        label: '${settings.editorFontSize.round()}',
                        onChanged: (value) =>
                            settings.setEditorFontSize(value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Privacy'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.pin_outlined),
                  title: Text(settings.pinEnabled ? 'Change PIN' : 'Set PIN'),
                  subtitle: Text(settings.pinEnabled
                      ? 'A 4-digit PIN protects your notes'
                      : 'Add a 4-digit PIN to lock the app'),
                  onTap: () => _managePin(context),
                ),
                if (settings.pinEnabled)
                  ListTile(
                    leading: const Icon(Icons.pin_outlined),
                    title: const Text('Remove PIN'),
                    onTap: () => _removePin(context),
                  ),
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint),
                  title: const Text('Unlock with biometrics'),
                  subtitle: Text(lock.biometricAvailable
                      ? 'Fingerprint or Face ID'
                      : 'Not available on this device'),
                  value: settings.pinEnabled && settings.biometricEnabled,
                  onChanged: !settings.pinEnabled || !lock.biometricAvailable
                      ? null
                      : (value) async {
                          await settings.setBiometricEnabled(value);
                          if (value) lock.unlock();
                        },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Data'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Notes are stored only on this device. Device-only '
                      'storage is not a backup — if your phone is lost or '
                      'reset, your notes are gone. Export a backup file '
                      'regularly and keep it somewhere safe.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.save_alt_outlined),
                  title: const Text('Backup all notes'),
                  subtitle: Text('${notes.active.length} note(s) — exports a '
                      'restore file'),
                  onTap: () => ExportService.shareBackup(notes.active),
                ),
                ListTile(
                  leading: const Icon(Icons.restore_outlined),
                  title: const Text('Restore from backup'),
                  subtitle: const Text('Replaces current notes'),
                  onTap: () => _restoreBackup(context),
                ),
                ListTile(
                  leading: const Icon(Icons.file_open_outlined),
                  title: const Text('Import text file'),
                  subtitle: const Text('Adds a .txt or .md file as a new note'),
                  onTap: () => _importTextFile(context),
                ),
                ListTile(
                  leading: const Icon(Icons.cloud_outlined),
                  title: const Text('Cloud sync'),
                  subtitle: const Text('Coming soon — sync across devices'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDialog<void>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Coming soon'),
                      content: const Text(
                        'Cloud sync isn\'t available yet — your notes stay '
                        'private on this device for now.\n\n'
                        'To keep them safe, use "Backup all notes" above '
                        'and save the file somewhere secure. You can '
                        'restore it on any device.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Got it'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('About'),
          Card(
            child: Column(
              children: const [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Notepad: Notes, To-Do & Memo'),
                  subtitle: Text('Version 1.0.0 • rpchauhan.com/notepad'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

Future<String?> showPinDialog(BuildContext context, {required String title}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PinEntryDialog(title: title),
  );
}

class _PinEntryDialog extends StatefulWidget {
  const _PinEntryDialog({required this.title});

  final String title;

  @override
  State<_PinEntryDialog> createState() => _PinEntryDialogState();
}

class _PinEntryDialogState extends State<_PinEntryDialog> {
  final _controller = TextEditingController();
  String _pin = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_pin.length == 4) Navigator.of(context).pop(_pin);
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accent;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            obscureText: true,
            maxLength: 4,
            style: const TextStyle(fontSize: 28, letterSpacing: 16),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              counterText: '',
              hintText: '••••',
            ),
            onChanged: (value) {
              setState(() => _pin = value);
              if (value.length == 4) _submit();
            },
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(backgroundColor: accent),
              onPressed: _pin.length == 4 ? _submit : null,
              child: const Text('Confirm'),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
