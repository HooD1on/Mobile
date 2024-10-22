import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../models/image_processing_model.dart';
import '../viewmodels/history_viewmodel.dart';
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
    print('Starting pickAndAnalyzeImage method');

    var status = await Permission.photos.request();
    if (status.isGranted) {
      print('Photos permission granted');
      final ImagePicker _picker = ImagePicker();
      try {
        final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

        if (pickedFile != null) {
          print('Image picked: ${pickedFile.path}');
          File file = File(pickedFile.path);
          print('File exists: ${await file.exists()}');
          var result = await _imageProcessingModel.runInference(file);
          print('Inference result: $result');
          showInferenceResult(context, result);

          // Save to history
          final historyViewModel = Provider.of<HistoryViewModel>(context, listen: false);
          List<double> probabilities = result.cast<double>();
          int maxIndex = probabilities.indexOf(probabilities.reduce(math.max));
          await historyViewModel.addHistory(file.path, formatResult(result, maxIndex: maxIndex));
        } else {
          print('No image selected');
        }
      } catch (e) {
        print('Error picking image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    } else {
      print('Photos permission denied');
      showPermissionDialog(context);
    }
  }

  Future<void> analyzeTestImage(BuildContext context) async {
    try {
      setLoading(true);
      _testImage = await _imageProcessingModel.loadImageFromAssets('assets/Test.jpg');
      var result = await _imageProcessingModel.runInference(_testImage!);
      setLoading(false);
      if (result != null && result.isNotEmpty) {
        showInferenceResult(context, result);

        // Save to history
        final historyViewModel = Provider.of<HistoryViewModel>(context, listen: false);
        List<double> probabilities = result.cast<double>();
        int maxIndex = probabilities.indexOf(probabilities.reduce(math.max));
        await historyViewModel.addHistory(_testImage!.path, formatResult(result, maxIndex: maxIndex));
      } else {
        throw Exception('Inference result is null or empty');
      }
    } catch (e) {
      setLoading(false);
      print('Error analyzing test image: $e');
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

  void showInferenceResult(BuildContext context, List<dynamic> result) {
    List<double> probabilities = result.cast<double>();
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
                if (_testImage != null)
                  Image.file(
                    _testImage!,
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

  void showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('Permission Required'),
        content: Text('This app needs access to your photos to analyze skin images.'),
        actions: [
          TextButton(
            child: Text('Open Settings'),
            onPressed: () => openAppSettings(),
          ),
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}