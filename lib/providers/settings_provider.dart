import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  static const _kThemeMode = 'settings.themeMode';
  static const _kAccent = 'settings.accent';
  static const _kPinHash = 'settings.pinHash';
  static const _kPinSalt = 'settings.pinSalt';
  static const _kBiometric = 'settings.biometric';
  static const _kEditorFontSize = 'settings.editorFontSize';
  static const _kViewGrid = 'settings.viewGrid';

  SharedPreferences? _prefs;

  ThemeMode themeMode = ThemeMode.system;
  int accentValue = 0xFF6750A4;
  String? pinHash;
  bool biometricEnabled = false;
  double editorFontSize = 16;
  bool viewGrid = false;
  bool loaded = false;

  Color get accent => Color(accentValue);

  bool get pinEnabled => pinHash != null;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    themeMode = ThemeMode.values[_prefs!.getInt(_kThemeMode) ?? 0];
    accentValue = _prefs!.getInt(_kAccent) ?? 0xFF6750A4;
    pinHash = _prefs!.getString(_kPinHash);
    biometricEnabled = _prefs!.getBool(_kBiometric) ?? false;
    editorFontSize = _prefs!.getDouble(_kEditorFontSize) ?? 16;
    viewGrid = _prefs!.getBool(_kViewGrid) ?? false;
    loaded = true;
    notifyListeners();
  }

  Future<void> setViewGrid(bool value) async {
    viewGrid = value;
    await _prefs?.setBool(_kViewGrid, value);
    notifyListeners();
  }

  Future<void> setEditorFontSize(double value) async {
    editorFontSize = value;
    await _prefs?.setDouble(_kEditorFontSize, value);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _prefs?.setInt(_kThemeMode, mode.index);
    notifyListeners();
  }

  Future<void> setAccent(int value) async {
    accentValue = value;
    await _prefs?.setInt(_kAccent, value);
    notifyListeners();
  }

  String _hash(String salt, String pin) =>
      sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<void> setPin(String pin) async {
    final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    final saltHex = salt.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    pinHash = _hash(saltHex, pin);
    await _prefs?.setString(_kPinSalt, saltHex);
    await _prefs?.setString(_kPinHash, pinHash!);
    notifyListeners();
  }

  Future<void> removePin() async {
    pinHash = null;
    biometricEnabled = false;
    await _prefs?.remove(_kPinHash);
    await _prefs?.remove(_kPinSalt);
    await _prefs?.setBool(_kBiometric, false);
    notifyListeners();
  }

  bool verifyPin(String pin) {
    final stored = pinHash;
    if (stored == null) return false;
    final saltHex = _prefs?.getString(_kPinSalt) ?? '';
    return _hash(saltHex, pin) == stored;
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    biometricEnabled = enabled;
    await _prefs?.setBool(_kBiometric, enabled);
    notifyListeners();
  }
}
