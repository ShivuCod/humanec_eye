// import 'dart:io';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:humanec_eye/utils/hive_config.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'camera_service.dart';
// import 'package:path_provider/path_provider.dart';

class FaceRecognitionService {
  static final FaceRecognitionService _instance =
      FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  late Interpreter _interpreter;
  final _faceDetector = FaceDetector(options: FaceDetectorOptions());

  bool _isInitialized = false;
  List<Map<String, dynamic>>? _cachedFaces;

  Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError('Platform not supported');
    }
    if (_isInitialized) return;
    final interpreterOptions = InterpreterOptions();

    _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite',
        options: interpreterOptions);
    _cachedFaces = HiveUser.getFaces();
    _isInitialized = true;
  }

  static List prepareInputFromNV21(Map<String, dynamic> params) {
    final nv21Data = params['nv21Data'] as Uint8List;
    final width = params['width'] as int;
    final height = params['height'] as int;
    final isFrontCamera = params['isFrontCamera'] as bool;
    final face = params['face'] as Face;

    img.Image image = CameraService.convertNV21ToImage(nv21Data, width, height);
    image = img.copyRotate(image, angle: isFrontCamera ? -90 : 90);

    return prepareInput(image, face);
  }

  static List prepareInputFromImagePath(Map<String, dynamic> params) {
    final imgPath = params['imgPath'] as String;
    final face = params['face'] as Face;

    img.Image image = img.decodeImage(File(imgPath).readAsBytesSync())!;
    return prepareInput(image, face);
  }

  static List prepareInput(img.Image image, Face face) {
    int x, y, w, h;
    x = face.boundingBox.left.round();
    y = face.boundingBox.top.round();
    w = face.boundingBox.width.round();
    h = face.boundingBox.height.round();

    img.Image faceImage = img.copyCrop(image, x: x, y: y, width: w, height: h);
    img.Image resizedImage = img.copyResizeCropSquare(faceImage, size: 112);

    // Save cropped face image
    // final docDir = await getApplicationDocumentsDirectory();
    // final file = File('${docDir.path}/${face.hashCode}.jpg');
    // await file.writeAsBytes(img.encodeJpg(resizedImage));

    List input = _imageToByteListFloat32(resizedImage, 112, 127.5, 127.5);
    input = input.reshape([1, 112, 112, 3]);

    return input;
  }

  List<double> getEmbedding(List input) {
    List output = List.generate(1, (_) => List.filled(192, 0));
    _interpreter.run(input, output);
    return output[0].cast<double>();
  }

  static List _imageToByteListFloat32(
      img.Image image, int size, double mean, double std) {
    var convertedBytes = Float32List(1 * size * size * 3);
    var buffer = Float32List.view(convertedBytes.buffer);
    int pixelIndex = 0;

    for (var i = 0; i < size; i++) {
      for (var j = 0; j < size; j++) {
        var pixel = image.getPixel(j, i);
        buffer[pixelIndex++] = (pixel.r - mean) / std;
        buffer[pixelIndex++] = (pixel.g - mean) / std;
        buffer[pixelIndex++] = (pixel.b - mean) / std;
      }
    }
    return convertedBytes.toList();
  }

  Future<bool> registerFace(String name, String code, List embedding) async {
    HiveUser.addFace({'name': name, 'code': code, 'embedding': embedding});
    _cachedFaces = HiveUser.getFaces();
    debugPrint("saved face $name $code");
    return true;
  }

  Future<Map<String, dynamic>> identifyFace(List<double> embedding,
      {double threshold = 0.8}) async {
    _cachedFaces ??= HiveUser.getFaces();

    double minDistance = double.maxFinite;
    Map<String, dynamic> emp = {};
    debugPrint("cached faces ${_cachedFaces?.length}");
    for (var face in _cachedFaces ?? []) {
      final distance =
          _euclideanDistance(embedding, face['embedding'].cast<double>());
      if (distance <= threshold && distance < minDistance) {
        minDistance = distance;
        emp = face;
      }
    }
    debugPrint('emp is $emp');

    return emp;
  }

  double _euclideanDistance(List e1, List e2) {
    if (e1.length != e2.length) {
      throw Exception('Vectors have different lengths');
    }
    var sum = 0.0;
    for (var i = 0; i < e1.length; i++) {
      sum += pow(e1[i] - e2[i], 2);
    }
    return sqrt(sum);
  }

  Future<void> deleteFace(String empCode) async {
    HiveUser.deleteFace(empCode);
    _cachedFaces = HiveUser.getFaces();
  }

  Future<List<Map<String, dynamic>>> getRegisteredFaces() async {
    _cachedFaces ??= HiveUser.getFaces();
    debugPrint("cached faces length ${_cachedFaces?.length}");
    return _cachedFaces!;
  }

  Future<List<Face>> detectFaces(InputImage inputImage) async {
    final faces = await _faceDetector.processImage(inputImage);
    return faces;
  }

  void dispose() {
    if (!_isInitialized) return;
    _faceDetector.close();
    _interpreter.close();
    _isInitialized = false;
  }

  Future<void> clearCache() async {
    await HiveUser.clearCache();
    _cachedFaces = HiveUser.getFaces();
  }
}
