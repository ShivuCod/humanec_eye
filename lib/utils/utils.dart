import 'dart:convert';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;


class Utils {
  static Future<String> convertToBase64(XFile image) async {
    Uint8List imageBytes = await image.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    final jpegPath = '${dir.path}/converted_image.jpeg';
    File newImage = await File(jpegPath).writeAsBytes(imageBytes);
    Uint8List bytes = await newImage.readAsBytes();
    String base64Image = base64Encode(bytes);
    return base64Image;
  }

  static Future<String> convertAssetToBase64(String assetPath) async {
    ByteData bytes = await rootBundle.load(assetPath);
    List<int> imageBytes = bytes.buffer.asUint8List();
    String base64String = base64Encode(imageBytes);
    return base64String;
  }

  static Future<File> getOrientedImage(XFile image) async {
    Uint8List imageBytes = await image.readAsBytes();
    img.Image capturedImage = img.decodeImage(imageBytes)!;
    img.Image orientedImage = img.bakeOrientation(capturedImage);
    final dir = await getApplicationDocumentsDirectory();
    final jpegPath = '${dir.path}/converted_image.jpeg';
    File newImage = await File(jpegPath).writeAsBytes(img.encodeJpg(orientedImage));
    return newImage;
  }

}