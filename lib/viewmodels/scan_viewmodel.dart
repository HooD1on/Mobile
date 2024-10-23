import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/image_processing_model.dart';
import 'dart:math' as math;
import 'history_viewmodel.dart';
import 'settings_viewmodel.dart';
import 'package:provider/provider.dart';

class ScanViewModel extends ChangeNotifier {
  XFile? _image;
  XFile? get image => _image;
  List<double>? _result;
  List<double>? get result => _result;
  File? _originalImageFile;

  late final ImageProcessingModel imageProcessingModel;
  final ImagePicker _picker = ImagePicker();

  ScanViewModel() {
    imageProcessingModel = ImageProcessingModel();
  }

  final Map<String, String> lesionTypeDict = {
    'akiec': 'Actinic keratoses',
    'bcc': 'Basal cell carcinoma',
    'bkl': 'Benign keratosis-like lesions',
    'df': 'Dermatofibroma',
    'mel': 'Melanoma',
    'nv': 'Melanocytic nevi',
    'vasc': 'Vascular lesions'
  };

  Future<void> pickImage(BuildContext context, HistoryViewModel historyViewModel) async {
    _image = await _picker.pickImage(source: ImageSource.camera);
    notifyListeners();

    if (_image != null) {
      _originalImageFile = File(_image!.path);
      await processImage(context, historyViewModel);
    }
  }

  Future<void> processImage(BuildContext context, HistoryViewModel historyViewModel) async {
    if (_originalImageFile == null) return;

    try {
      final settingsViewModel = Provider.of<SettingsViewModel>(context, listen: false);
      await imageProcessingModel.loadModel();

      _result = await imageProcessingModel.runInference(
        _originalImageFile!,
        brightness: settingsViewModel.brightness,
        contrast: settingsViewModel.contrast,
        clarity: settingsViewModel.clarity,
        noiseReduction: settingsViewModel.noiseReduction,
      );

      notifyListeners();
      await saveHistory(historyViewModel);
    } catch (e) {
      print('Error processing image: $e');
    }
  }

  Future<void> saveHistory(HistoryViewModel historyViewModel) async {
    if (_originalImageFile != null && _result != null && imageProcessingModel.processedImageFile != null) {
      await historyViewModel.addHistory(
          imageProcessingModel.processedImageFile!.path,
          getFormattedResult()
      );
    }
  }

  String getFormattedResult() {
    if (_result == null) return 'No result available';

    List<MapEntry<int, double>> sortedEntries = _result!.asMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int maxIndex = sortedEntries[0].key;
    double maxValue = sortedEntries[0].value;

    String formattedResult = 'Predicted Class: ${getClassLabel(maxIndex)}\n';
    formattedResult += 'Confidence: ${(maxValue * 100).toStringAsFixed(2)}%\n\n';
    formattedResult += 'Top 5 Predictions:\n';

    for (int i = 0; i < 5 && i < sortedEntries.length; i++) {
      formattedResult += '${getClassLabel(sortedEntries[i].key)}: ${(sortedEntries[i].value * 100).toStringAsFixed(2)}%\n';
    }

    return formattedResult;
  }

  String getClassLabel(int classIndex) {
    List<String> keys = lesionTypeDict.keys.toList();
    if (classIndex >= 0 && classIndex < keys.length) {
      return lesionTypeDict[keys[classIndex]] ?? 'Unknown';
    }
    return 'Unknown';
  }

  Future<void> onSettingsChanged(BuildContext context) async {
    if (_originalImageFile != null) {
      final historyViewModel = Provider.of<HistoryViewModel>(context, listen: false);
      await processImage(context, historyViewModel);
    }
  }
}