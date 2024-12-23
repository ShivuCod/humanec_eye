import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'camera_service.dart';

class FaceRecognitionService {
  static final FaceRecognitionService _instance =
      FaceRecognitionService._internal();
  factory FaceRecognitionService() => _instance;
  FaceRecognitionService._internal();

  late Interpreter _interpreter;
  final _faceDetector = FaceDetector(options: FaceDetectorOptions());

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnsupportedError('Platform not supported');
    }
    if (_isInitialized) return;
    final interpreterOptions = InterpreterOptions();

    _interpreter = await Interpreter.fromAsset('assets/mobilefacenet.tflite',
        options: interpreterOptions);
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
    final imgPath = params['imgPath'] as String?;
    final face = params['face'] as Face?;

    if (imgPath == null || face == null) {
      throw ArgumentError('imgPath and face must not be null');
    }

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
}
