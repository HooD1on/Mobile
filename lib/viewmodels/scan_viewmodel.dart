import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/image_processing_model.dart';
import 'dart:math' as math;
import 'history_viewmodel.dart';

class ScanViewModel extends ChangeNotifier {
  XFile? _image;
  XFile? get image => _image;
  List<double>? _result;
  List<double>? get result => _result;

  final ImagePicker _picker = ImagePicker();
  final ImageProcessingModel _imageProcessingModel = ImageProcessingModel();

  final Map<String, String> lesionTypeDict = {
    'akiec': 'Actinic keratoses',
    'bcc': 'Basal cell carcinoma',
    'bkl': 'Benign keratosis-like lesions',
    'df': 'Dermatofibroma',
    'mel': 'Melanoma',
    'nv': 'Melanocytic nevi',
    'vasc': 'Vascular lesions'

  };

  String getClassLabel(int classIndex) {
    List<String> keys = lesionTypeDict.keys.toList();
    int adjustedIndex = classIndex;
    if (adjustedIndex >= 0 && adjustedIndex < keys.length) {
      return lesionTypeDict[keys[adjustedIndex]] ?? 'Unknown';
    }
    return 'Unknown';
  }

  Future<void> pickImage(BuildContext context, HistoryViewModel historyViewModel) async {
    _image = await _picker.pickImage(source: ImageSource.camera);
    notifyListeners();

    if (_image != null) {
      File imageFile = File(_image!.path);
      await _imageProcessingModel.loadModel();
      var inferenceResult = await _imageProcessingModel.runInference(imageFile);
      _result = inferenceResult.cast<double>();
      notifyListeners();
      await saveHistory(historyViewModel);
    }
  }

  Future<void> saveHistory(HistoryViewModel historyViewModel) async {
    if (_image != null && _result != null) {
      await historyViewModel.addHistory(_image!.path, getFormattedResult());
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
}