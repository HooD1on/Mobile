// lib/models/image_processing_model.dart

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
  File? processedImageFile;

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

  Future<img.Image> preprocessImage(img.Image image, {
    double brightness = 1.0,
    double contrast = 1.0,
    double clarity = 1.0,  // 改为 clarity
    double noiseReduction = 1.0,
  }) async {
    try {
      // 亮度调整
      if (brightness != 1.0) {
        final brightnessValue = ((brightness - 1.0) * 100).round();
        image = img.adjustColor(
          image,
          brightness: brightnessValue,
        );
      }

      // 对比度调整
      if (contrast != 1.0) {
        image = img.adjustColor(
          image,
          contrast: contrast,
        );
      }

      if (clarity > 1.0) {
        // 使用更激进的参数来增强清晰度
        final amount = ((clarity - 1.0) * 5).round();  // 增加系数
        final radius = 1;  // 减小模糊半径
        final threshold = 3;  // 降低阈值使得更多细节被增强

        for (var i = 0; i < amount; i++) {
          var blurred = img.gaussianBlur(image, radius);

          for (var y = 0; y < image.height; y++) {
            for (var x = 0; x < image.width; x++) {
              var p1 = image.getPixel(x, y);
              var p2 = blurred.getPixel(x, y);

              var r1 = img.getRed(p1);
              var g1 = img.getGreen(p1);
              var b1 = img.getBlue(p1);

              var r2 = img.getRed(p2);
              var g2 = img.getGreen(p2);
              var b2 = img.getBlue(p2);

              // 计算边缘差异
              var dr = (r1 - r2);
              var dg = (g1 - g2);
              var db = (b1 - b2);

              // 增强边缘
              if (dr.abs() > threshold || dg.abs() > threshold || db.abs() > threshold) {
                // 增加边缘增强的强度
                var enhanceFactor = 0.8 * (clarity - 1.0);  // 根据清晰度值调整增强因子
                image.setPixel(x, y, img.getColor(
                    (r1 + dr * enhanceFactor).round().clamp(0, 255),
                    (g1 + dg * enhanceFactor).round().clamp(0, 255),
                    (b1 + db * enhanceFactor).round().clamp(0, 255)
                ));
              }
            }
          }
        }
      }

      // 降噪处理
      if (noiseReduction > 1.0) {
        final radius = ((noiseReduction - 1.0) * 2).round() + 1;
        image = img.gaussianBlur(image, radius);
      }

      return image;
    } catch (e) {
      print('Error in image preprocessing: $e');
      rethrow;
    }
  }

  Future<List<double>> runInference(  // 修改返回类型为 Future<List<double>>
      File imageFile, {
        double brightness = 1.0,
        double contrast = 1.0,
        double clarity = 1.0,
        double noiseReduction = 1.0,
      }) async {
    if (_interpreter == null) {
      await loadModel();
      if (_interpreter == null) {
        throw Exception('Interpreter is not initialized');
      }
    }

    try {
      print('Starting image processing...');

      // 读取图像
      var image = img.decodeImage(await imageFile.readAsBytes())!;

      // 应用图像处理
      image = await preprocessImage(
        image,
        brightness: brightness,
        contrast: contrast,
        clarity: 3.0 - clarity,
        noiseReduction: noiseReduction,
      );

      // 保存处理后的图像
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${tempDir.path}/processed_$timestamp.jpg';

      // 创建新文件并写入数据
      try {
        File processedFile = File(path);
        processedFile = await processedFile.create(recursive: true);
        await processedFile.writeAsBytes(img.encodeJpg(image));
        processedImageFile = processedFile;
      } catch (e) {
        print('Error saving processed image: $e');
        throw Exception('Failed to save processed image');
      }

      // 调整大小为模型输入尺寸
      image = img.copyResize(image, width: 224, height: 224);
      print('Image resized to 224x224');

      var input = imageToByteList(image, 224);
      var inputShape = _interpreter!.getInputTensor(0).shape;
      print('Model input shape: $inputShape');

      // 重塑输入数据
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

      var output = List.generate(1, (_) => List<double>.filled(1000, 0));

      print('Running inference...');
      _interpreter!.run(reshapedInput, output);
      print('Inference completed');

      // 直接返回处理后的概率数组
      return softmax(output[0].cast<double>());
    } catch (e) {
      print('Error in runInference: $e');
      rethrow;
    }
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
    double max = input.reduce(math.max);
    List<double> exp = input.map((x) => math.exp(x - max)).toList();
    double sum = exp.reduce((a, b) => a + b);
    return exp.map((x) => x / sum).toList();
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