// lib/viewmodels/upload_photo_viewmodel.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../models/image_processing_model.dart';
import 'history_viewmodel.dart';
import 'dart:math' as math;

class UploadPhotoViewModel extends ChangeNotifier {
  File? _image;
  File? get image => _image;
  final ImagePicker _picker = ImagePicker();
  final ImageProcessingModel _imageProcessingModel = ImageProcessingModel();
  List<double>? _result;
  List<double>? get result => _result;

  Future<void> init() async {
    await _imageProcessingModel.loadModel();
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

  Future<void> pickImage(BuildContext context) async {
    print('Starting pickImage method');
    var status = await Permission.storage.request();
    print('Storage permission status: $status');
    if (status.isGranted) {
      final permitted = await PhotoManager.requestPermissionExtend();
      print('Photo permission status: $permitted');
      if (permitted.isAuth) {
        final assets = await PhotoManager.getAssetPathList(onlyAll: true);
        if (assets.isNotEmpty) {
          final recentAlbum = assets.first;
          final recentAssets = await recentAlbum.getAssetListRange(start: 0, end: 1000);
          if (recentAssets.isNotEmpty) {
            final asset = recentAssets.first;
            final file = await asset.file;
            if (file != null) {
              _image = file;
              notifyListeners();
              await analyzeImage(context, file);
            }
          }
        }
      }
    }
  }

  Future<void> analyzeImage(BuildContext context, File image) async {
    try {
      var result = await _imageProcessingModel.runInference(image);
      _result = result.cast<double>();
      notifyListeners();

      // 显示结果
      showInferenceResult(context, _result!);

      // 保存到历史记录
      final historyViewModel = Provider.of<HistoryViewModel>(context, listen: false);
      await historyViewModel.addHistory(image.path, formatResult(_result!));
    } catch (e) {
      print('Error analyzing image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing image: $e')),
      );
    }
  }

  String formatResult(List<double> probabilities) {
    int maxIndex = probabilities.indexOf(probabilities.reduce(math.max));
    double maxValue = probabilities[maxIndex];

    List<MapEntry<int, double>> sortedEntries = probabilities.asMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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

  void showInferenceResult(BuildContext context, List<double> probabilities) {
    int maxIndex = probabilities.indexOf(probabilities.reduce(math.max));
    double maxValue = probabilities[maxIndex];

    List<MapEntry<int, double>> sortedEntries = probabilities.asMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Test Image Analysis Result"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_image != null)
                  Image.file(
                    _image!,
                    height: 200,
                  ),
                const SizedBox(height: 20),
                Text("Predicted Class: ${getClassLabel(maxIndex)}"),
                Text("Confidence: ${(maxValue * 100).toStringAsFixed(2)}%"),
                const Divider(),
                const Text("Top 5 Predictions:"),
                for (int i = 0; i < 5 && i < sortedEntries.length; i++)
                  Text("${getClassLabel(sortedEntries[i].key)}: ${(sortedEntries[i].value * 100).toStringAsFixed(2)}%"),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}