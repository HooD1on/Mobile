// lib/viewmodels/settings_viewmodel.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/image_processing_model.dart';
import 'dart:math' as math;
import 'history_viewmodel.dart';




class SettingsViewModel extends ChangeNotifier {
  double _brightness = 1.0;
  double _contrast = 1.0;
  double _clarity = 1.0;
  double _noiseReduction = 1.0;

  // Getters
  double get brightness => _brightness;
  double get contrast => _contrast;
  double get clarity => _clarity;  // 改为 clarity
  double get noiseReduction => _noiseReduction;

  // 添加回调函数
  Function(BuildContext)? onSettingsChanged;

  SettingsViewModel() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _brightness = prefs.getDouble('brightness') ?? 1.0;
    _contrast = prefs.getDouble('contrast') ?? 1.0;
    _clarity = prefs.getDouble('clarity') ?? 1.0;  // 改为 clarity
    _noiseReduction = prefs.getDouble('noiseReduction') ?? 1.0;
    notifyListeners();
  }

  Future<void> updateBrightness(BuildContext context, double value) async {
    _brightness = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('brightness', value);
    notifyListeners();
    onSettingsChanged?.call(context);
  }

  Future<void> updateContrast(BuildContext context, double value) async {
    _contrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('contrast', value);
    notifyListeners();
    onSettingsChanged?.call(context);
  }

  Future<void> updateSharpness(BuildContext context, double value) async {
    _clarity = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('sharpness', value);
    notifyListeners();
    onSettingsChanged?.call(context);
  }

  Future<void> updateNoiseReduction(BuildContext context, double value) async {
    _noiseReduction = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('noiseReduction', value);
    notifyListeners();
    onSettingsChanged?.call(context);
  }

  Future<void> resetToDefaults(BuildContext context) async {
    _brightness = 1.0;
    _contrast = 1.0;
    _clarity = 1.0;
    _noiseReduction = 1.0;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('brightness', 1.0);
    await prefs.setDouble('contrast', 1.0);
    await prefs.setDouble('sharpness', 1.0);
    await prefs.setDouble('noiseReduction', 1.0);

    notifyListeners();
    onSettingsChanged?.call(context);
  }
}

