import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/image_processing_model.dart';
import '../viewmodels/history_viewmodel.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'dart:math' as math;

class HomeViewModel extends ChangeNotifier {
  bool _isRequestingPermission = false;
  int _currentIndex = 0;
  late final ImageProcessingModel _imageProcessingModel;
  bool _isModelLoaded = false;
  bool _isLoading = true;
  File? _testImage;

  bool get isRequestingPermission => _isRequestingPermission;
  int get currentIndex => _currentIndex;
  bool get isModelLoaded => _isModelLoaded;
  bool get isLoading => _isLoading;
  File? get testImage => _testImage;

  final Map<String, String> lesionTypeDict = {
    'akiec': 'Actinic keratoses',
    'bcc': 'Basal cell carcinoma',
    'bkl': 'Benign keratosis-like lesions',
    'df': 'Dermatofibroma',
    'mel': 'Melanoma',
    'nv': 'Melanocytic nevi',
    'vasc': 'Vascular lesions'
  };

  HomeViewModel() {
    _imageProcessingModel = ImageProcessingModel();
    _loadModel();
    Future.delayed(Duration(milliseconds: 500), _requestPermissions);
  }

  Future<void> _requestPermissions() async {
    if (_isRequestingPermission) return;
    _isRequestingPermission = true;
    try {
      await Permission.storage.request();
    } finally {
      _isRequestingPermission = false;
      notifyListeners();
    }
  }

  Future<void> reloadModel() async {
    await _loadModel();
  }

  Future<void> _loadModel() async {
    setLoading(true);

    int retryCount = 0;
    while (retryCount < 3) {
      try {
        await _imageProcessingModel.loadModel().timeout(Duration(seconds: 30));
        _isModelLoaded = _imageProcessingModel.isModelLoaded;
        setLoading(false);
        print('Model loaded successfully: $_isModelLoaded');
        return;
      } catch (e) {
        retryCount++;
        print('Error loading model (attempt $retryCount): $e');
        await Future.delayed(Duration(seconds: 2));
      }
    }

    _isModelLoaded = false;
    setLoading(false);
  }

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> pickAndAnalyzeImage(BuildContext context) async {
    final settingsViewModel = Provider.of<SettingsViewModel>(context, listen: false);

    var status = await Permission.photos.request();
    if (status.isGranted) {
      final ImagePicker _picker = ImagePicker();
      try {
        final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          File file = File(pickedFile.path);
          if (!await file.exists()) {
            throw Exception('Selected file does not exist');
          }

          var result = await _imageProcessingModel.runInference(
            file,
            brightness: settingsViewModel.brightness,
            contrast: settingsViewModel.contrast,
            clarity: settingsViewModel.clarity,
            noiseReduction: settingsViewModel.noiseReduction,
          );

          if (!context.mounted) return;

          if (_imageProcessingModel.processedImageFile != null) {
            showInferenceResult(context, result);

            final historyViewModel = Provider.of<HistoryViewModel>(context, listen: false);
            List<double> probabilities = result.cast<double>();
            int maxIndex = probabilities.indexOf(probabilities.reduce(math.max));
            await historyViewModel.addHistory(
                _imageProcessingModel.processedImageFile!.path,
                formatResult(result, maxIndex: maxIndex)
            );
          }
        }
      } catch (e) {
        print('Error picking image: $e');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } else {
      showPermissionDialog(context);
    }
  }

  Future<void> onSettingsChanged(BuildContext context) async {
    // 如果有测试图片并且已经加载了模型，重新分析图片
    if (_originalTestImage != null && _isModelLoaded && !_isLoading) {
      try {
        final settingsViewModel = Provider.of<SettingsViewModel>(context, listen: false);

        var result = await _imageProcessingModel.runInference(
          _originalTestImage!,
          brightness: settingsViewModel.brightness,
          contrast: settingsViewModel.contrast,
          clarity: settingsViewModel.clarity,
          noiseReduction: settingsViewModel.noiseReduction,
        );

        if (result != null && result.isNotEmpty) {
          if (!context.mounted) return;
          showInferenceResult(context, result);
        }
      } catch (e) {
        print('Error updating image with new settings: $e');
      }
    }
  }

  File? _originalTestImage;

  Future<void> analyzeTestImage(BuildContext context) async {
    try {
      setLoading(true);
      final settingsViewModel = Provider.of<SettingsViewModel>(context, listen: false);

      if (_originalTestImage == null) {
        _originalTestImage = await _imageProcessingModel.loadImageFromAssets('assets/Test.jpg');
      }

      if (_originalTestImage != null && await _originalTestImage!.exists()) {
        var result = await _imageProcessingModel.runInference(
          _originalTestImage!,
          brightness: settingsViewModel.brightness,
          contrast: settingsViewModel.contrast,
          clarity: settingsViewModel.clarity,
          noiseReduction: settingsViewModel.noiseReduction,
        );

        setLoading(false);
        if (result.isNotEmpty && _imageProcessingModel.processedImageFile != null) {
          if (!context.mounted) return;
          showInferenceResult(context, result);

          final historyViewModel = Provider.of<HistoryViewModel>(context, listen: false);
          List<double> probabilities = result.cast<double>();
          int maxIndex = probabilities.indexOf(probabilities.reduce(math.max));
          await historyViewModel.addHistory(
              _imageProcessingModel.processedImageFile!.path,
              formatResult(result, maxIndex: maxIndex)
          );
        }
      } else {
        throw Exception('Test image file not found or invalid');
      }
    } catch (e) {
      setLoading(false);
      print('Error analyzing test image: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error analyzing test image: $e')),
      );
    }
  }

  String getClassLabel(int classIndex) {
    List<String> keys = lesionTypeDict.keys.toList();
    if (classIndex >= 0 && classIndex < keys.length) {
      return lesionTypeDict[keys[classIndex]] ?? 'Unknown';
    }
    return 'Unknown';
  }

  String formatResult(List<dynamic> result, {required int maxIndex}) {
    List<double> probabilities = result.cast<double>();
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

  @override
  void dispose() {
    _originalTestImage = null;
    super.dispose();
  }

  void showInferenceResult(BuildContext context, List<dynamic> result) {
    List<double> probabilities = result.cast<double>();
    int maxIndex = probabilities.indexOf(probabilities.reduce(math.max));
    double maxValue = probabilities[maxIndex];

    List<MapEntry<int, double>> sortedEntries = probabilities.asMap().entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Test Image Analysis Result"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_imageProcessingModel.processedImageFile != null)
                  Image.file(
                    _imageProcessingModel.processedImageFile!,
                    height: 200,
                    fit: BoxFit.contain,
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
              child: const Text("Close"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Permission Required'),
        content: const Text('This app needs access to your photos to analyze skin images.'),
        actions: [
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () => openAppSettings(),
          ),
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}