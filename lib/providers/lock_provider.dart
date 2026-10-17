import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

import 'settings_provider.dart';

class LockProvider extends ChangeNotifier {
  LockProvider(this.settings);

  final SettingsProvider settings;

  final LocalAuthentication _auth = LocalAuthentication();

  bool locked = false;
  bool initializing = true;
  bool biometricAvailable = false;
  String? error;

  Future<void> init() async {
    locked = settings.pinEnabled;
    try {
      biometricAvailable =
          await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) {
      biometricAvailable = false;
    }
    initializing = false;
    notifyListeners();
  }

  bool get showBiometric =>
      settings.pinEnabled && settings.biometricEnabled && biometricAvailable;

  void lock() {
    if (settings.pinEnabled && !locked) {
      locked = true;
      error = null;
      notifyListeners();
    }
  }

  void unlock() {
    locked = false;
    error = null;
    notifyListeners();
  }

  bool verifyPin(String pin) {
    final ok = settings.verifyPin(pin);
    error = ok ? null : 'Wrong PIN, try again';
    notifyListeners();
    return ok;
  }

  Future<bool> authenticateBiometrics() async {
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'Unlock your private notes',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (ok) unlock();
      return ok;
    } catch (_) {
      return false;
    }
  }

  void clearError() {
    if (error != null) {
      error = null;
      notifyListeners();
    }
  }
}
