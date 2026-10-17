import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/lock_provider.dart';
import '../providers/settings_provider.dart';

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  String _entered = '';
  bool _checkingBiometric = false;

  void _tap(String digit) {
    if (_entered.length >= 6) return;
    setState(() {
      _entered += digit;
      context.read<LockProvider>().clearError();
    });
    if (_entered.length == 4) _verify();
  }

  void _verify() {
    final lock = context.read<LockProvider>();
    final ok = lock.verifyPin(_entered);
    if (ok) {
      lock.unlock();
    } else {
      setState(() => _entered = '');
    }
  }

  void _backspace() {
    if (_entered.isEmpty) return;
    setState(() {
      _entered = _entered.substring(0, _entered.length - 1);
      context.read<LockProvider>().clearError();
    });
  }

  Future<void> _biometric() async {
    final lock = context.read<LockProvider>();
    setState(() => _checkingBiometric = true);
    await lock.authenticateBiometrics();
    if (mounted) setState(() => _checkingBiometric = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lock = context.watch<LockProvider>();
    final settings = context.watch<SettingsProvider>();
    final accent = settings.accent;
    final error = lock.error;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 48),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(Icons.lock_outline, size: 32, color: accent),
            ),
            const SizedBox(height: 16),
            Text('Notepad is locked', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Enter your PIN to continue',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final filled = index < _entered.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? accent : Colors.transparent,
                    border: Border.all(
                      color: filled ? accent : theme.colorScheme.outline,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),
            SizedBox(
              height: 40,
              child: Center(
                child: error == null
                    ? null
                    : Text(
                        error,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
              ),
            ),
            const Spacer(),
            _Keypad(
              onDigit: _tap,
              onBackspace: _backspace,
              showBiometric: lock.showBiometric,
              biometricBusy: _checkingBiometric,
              onBiometric: _biometric,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.showBiometric,
    required this.biometricBusy,
    required this.onBiometric,
  });

  final void Function(String) onDigit;
  final VoidCallback onBackspace;
  final bool showBiometric;
  final bool biometricBusy;
  final VoidCallback onBiometric;

  @override
  Widget build(BuildContext context) {
    final accent = context.watch<SettingsProvider>().accent;

    Widget key(Widget child, {VoidCallback? onTap, bool filled = false}) {
      return SizedBox(
        width: 72,
        height: 72,
        child: Material(
          color: filled ? accent : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(36),
            side: BorderSide(
              color: filled ? Colors.transparent : Colors.transparent,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(36),
            onTap: onTap,
            child: Center(child: child),
          ),
        ),
      );
    }

    Widget digit(String d) => key(
          Text(
            d,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          onTap: () => onDigit(d),
          filled: true,
        );

    return Column(
      children: [
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [for (final d in row) digit(d)],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              key(
                showBiometric
                    ? (biometricBusy
                        ? const SizedBox(
                            width: 26,
                            height: 26,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.fingerprint, size: 30, color: accent))
                    : const SizedBox.shrink(),
                onTap: showBiometric && !biometricBusy ? onBiometric : null,
              ),
              digit('0'),
              key(
                Icon(
                  Icons.backspace_outlined,
                  size: 24,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                onTap: onBackspace,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
