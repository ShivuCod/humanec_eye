import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:humanec_eye/utils/hive_config.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import '../services/face_recognition_service.dart';
import '../services/services.dart';

class AutomationPage extends ConsumerStatefulWidget {
  static const routerName = '/automation';
  const AutomationPage({super.key});

  @override
  ConsumerState<AutomationPage> createState() => _AutomationPageState();
}

class _AutomationPageState extends ConsumerState<AutomationPage> {
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final total = StateProvider<int>((ref) => 0);
  final current = StateProvider<int>((ref) => 0);
  final status = StateProvider<String>((ref) => 'Fetching data...');
  final faild = StateProvider<List<String>>((ref) => []);
  final faildCount = StateProvider<int>((ref) => 0);

  @override
  void initState() {
    _faceService.initialize();
    fetchAutomation();

    super.initState();
  }

  Future<void> fetchAutomation() async {
    final data = await Services.getRegisteredEmployees('', 1, pageSize: 1000);
    List embeding = [];
    HiveUser.clearFaces();
    Future.microtask(() {
      ref.read(total.notifier).state = data.length;
    });
    for (var item in data) {
      log("imgAttn: ${item.imgAttn}");
      if (item.imgAttn != null &&
          item.imgAttn?.isNotEmpty == true &&
          item.img?.isEmpty == true) {
        final image = await downloadImage(item.imgAttn ?? '', item.code ?? '');
        ref.read(status.notifier).state = 'Processing ${item.empName}..';
        InputImage inputImage = InputImage.fromFile(File(image!.path));
        final faces = await _faceService.detectFaces(inputImage);
        if (faces.isEmpty) {
          log('No face detected for ${item.empName} ${item.code}');
          ref.read(faild.notifier).state = [
            ...ref.read(faild.notifier).state,
            item.empName ?? ''
          ];
          ref.read(faildCount.notifier).state =
              ref.read(faildCount.notifier).state + 1;
          continue;
        }

        final input = FaceRecognitionService.prepareInputFromImagePath({
          'imgPath': image.path,
          'face': faces.first,
        });
        final embedding = _faceService.getEmbedding(input);
        embeding.add(embedding);
        final exits = await _faceService.identifyFace(embedding);
        if (exits.isEmpty) {
          Future.microtask(() {
            ref.read(current.notifier).state =
                ref.read(current.notifier).state + 1;
            ref.read(status.notifier).state = 'Saving ${item.empName}..';
          });
          log('Saving ${item.empName} ${item.code}');
          _faceService.registerFace(
              item.empName ?? "", item.code ?? "", embedding);
          // await Services.registerEmployees(
          //     empCode: item.code ?? '',
          //     embeding: json.encode(embedding),
          //     img: image.path);
        } else {
          Future.microtask(() {
            ref.read(current.notifier).state =
                ref.read(current.notifier).state + 1;
            debugPrint('Already registered ${item.empName}..');
            ref.read(status.notifier).state =
                'Already registered ${item.empName}..';
          });
        }
      } else {
        Future.microtask(() {
          ref.read(status.notifier).state =
              'Already registered ${item.empName}..';
        });
      }
    }
    Future.microtask(() {
      ref.read(status.notifier).state = 'Done';
    });
  }

  Future<File?> downloadImage(String imageUrl, String empCode) async {
    try {
      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        log('Failed to download image: ${response.statusCode}');
        return null;
      }

      // Get application documents directory for permanent storage
      final appDir = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${appDir.path}/employee_images');

      // Create the images directory if it doesn't exist
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }

      // Create file path with timestamp to avoid conflicts
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = path.join(imagesDir.path, '${empCode}_$timestamp.jpg');

      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      log('Image saved to: ${file.path}');
      return file;
    } catch (e) {
      log('Error downloading/saving image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText = ref.watch(status);
    final faildTotal = ref.watch(faildCount);
    final faildList = ref.watch(faild);
    bool isFailed = faildTotal > 0;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text('Automation'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (statusText != "Done") ...[
                const SpinKitWanderingCubes(
                  color: Colors.black,
                  size: 70.0,
                ),
                const SizedBox(height: 10),
                Text(
                    '${ref.read(current.notifier).state}/${ref.read(total.notifier).state}'),
                const SizedBox(height: 5),
                Text(statusText,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const Text("Please wait until the process is complete...",
                    style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
              if (statusText == "Done") ...[
                const Icon(
                  Icons.check_circle,
                  color: Colors.black,
                  size: 80,
                ),
                if (!isFailed) const SizedBox(height: 10),
                const Text("Done",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    )),
                if (isFailed) const SizedBox(height: 10),
                if (!isFailed)
                  const Text(
                      "All employees have been\n registered successfully",
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
              if (isFailed)
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                          text: "Completed: ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey)),
                      TextSpan(
                          text: "${ref.read(current.notifier).state}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                      const TextSpan(
                          text: "\tFailed: ",
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.bold)),
                      TextSpan(
                          text: "$faildTotal",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              Text(
                faildList.join(', '),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
