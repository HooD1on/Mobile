import 'package:tflite_flutter/tflite_flutter.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math' as math;

class ImageProcessingModel {
  Interpreter? _interpreter;
  bool isModelLoaded = false;

  Future<void> loadModel() async {
    if (isModelLoaded) return;
    try {
      print('Starting to load model...');
      final ByteData data = await rootBundle.load('assets/mobilenetv2.tflite');
      print('Model file loaded from assets');
      final Uint8List modelData = data.buffer.asUint8List();
      print('Model data converted to Uint8List');

      _interpreter = await Interpreter.fromBuffer(modelData);
      print('Interpreter created successfully');

      isModelLoaded = true;
      print('Model loaded successfully');
    } catch (e) {
      print('Failed to load model: $e');
      rethrow;
    }
  }

  Future<List<dynamic>> runInference(File imageFile) async {
    if (_interpreter == null) {
      await loadModel();
      if (_interpreter == null) {
        throw Exception('Interpreter is not initialized');
      }
    }

    print('Starting image processing...');
    var image = img.decodeImage(await imageFile.readAsBytes())!;
    image = img.copyResize(image, width: 224, height: 224);
    print('Image resized to 224x224');

    var input = imageToByteList(image, 224);

    // 获取模型的输入张量形状
    var inputShape = _interpreter!.getInputTensor(0).shape;
    print('Model input shape: $inputShape');

    // 根据模型的输入形状重塑输入数据
    List<List<List<List<double>>>> reshapedInput = List.generate(
      1,
          (_) => List.generate(
        3,
            (i) => List.generate(
          224,
              (y) => List.generate(
            224,
                (x) => input[y * 224 * 3 + x * 3 + i],
          ),
        ),
      ),
    );

    // 获取模型的输出张量形状
    var outputShape = _interpreter!.getOutputTensor(0).shape;
    print('Model output shape: $outputShape');

    // 创建输出张量，注意这里我们使用二维列表
    var output = List.generate(1, (_) => List<double>.filled(1000, 0));

    print('Running inference...');
    _interpreter!.run(reshapedInput, output);
    print('Inference completed');
    var probabilities = softmax(output[0].cast<double>());
    return probabilities;
    // 返回一维列表
    return output[0];
  }

  List<double> imageToByteList(img.Image image, int inputSize) {
    var convertedBytes = List<double>.filled(inputSize * inputSize * 3, 0);
    int pixelIndex = 0;
    for (var y = 0; y < inputSize; y++) {
      for (var x = 0; x < inputSize; x++) {
        var pixel = image.getPixel(x, y);
        convertedBytes[pixelIndex++] = (img.getRed(pixel) - 127.5) / 127.5;
        convertedBytes[pixelIndex++] = (img.getGreen(pixel) - 127.5) / 127.5;
        convertedBytes[pixelIndex++] = (img.getBlue(pixel) - 127.5) / 127.5;
      }
    }
    return convertedBytes;
  }

  List<double> softmax(List<double> input) {
    double max = input.reduce((a, b) => a > b ? a : b);
    List<double> exp = input.map((x) => math.exp(x - max)).toList();
    double sum = exp.reduce((a, b) => a + b);
    return exp.map((x) => x / sum).toList();
  }
  
  Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return File(pickedFile.path);
    } else {
      print('No image selected.');
      return null;
    }
  }

  Future<File> loadImageFromAssets(String assetPath) async {
    final ByteData data = await rootBundle.load(assetPath);
    final Uint8List bytes = data.buffer.asUint8List();
    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/Test.jpg').create();
    await file.writeAsBytes(bytes);
    return file;
  }
}