import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:humanec_eye/pages/verify.dart';
import 'package:intl/intl.dart';

import '../providers/providers.dart';
import '../services/camera_service.dart';
import '../services/face_recognition_service.dart';
import '../services/services.dart';
import '../utils/hive_config.dart';
import '../widgets/face_painter.dart';

class RecognizePage extends ConsumerStatefulWidget {
  const RecognizePage({super.key});
  static const routerName = '/recognize';

  @override
  ConsumerState<RecognizePage> createState() => _RecognizePageState();
}

class _RecognizePageState extends ConsumerState<RecognizePage>
    with TickerProviderStateMixin {
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final CameraService _cameraService = CameraService();

  late Future<void> _initializeControllerFuture;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;

  bool _isBusy = false;

  final _customPaint = StateProvider<CustomPaint?>((ref) => null);
  final btnLoader = StateProvider<bool>((ref) => false);
  final empdetail = StateProvider<Map<String, dynamic>>((ref) => {});

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeServices();
    _animController = AnimationController(
        duration: const Duration(milliseconds: 200), vsync: this);
    _offsetAnimation =
        Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: _animController, curve: Curves.easeInOut));
  }

  Future<void> _initializeServices() async {
    try {
      await _faceService.initialize();
      await _cameraService
          .initialize(await availableCameras().then((value) => value[1]));
      _cameraService.startImageStream(_processCameraImage);
    } catch (e) {
      throw Exception('Error initializing services: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy) return;
    _isBusy = true;

    try {
      // Prepare input image
      final orientations = {
        DeviceOrientation.portraitUp: 0,
        DeviceOrientation.landscapeLeft: 90,
        DeviceOrientation.portraitDown: 180,
        DeviceOrientation.landscapeRight: 270,
      };
      InputImageRotation? rotation;
      if (Platform.isIOS) {
        rotation = InputImageRotationValue.fromRawValue(
            _cameraService.controller.value.description.sensorOrientation);
      } else {
        var rotationCompensation =
            orientations[_cameraService.controller.value.deviceOrientation];
        if (rotationCompensation == null) return;
        if (_cameraService.controller.value.description.lensDirection ==
            CameraLensDirection.front) {
          rotationCompensation =
              (_cameraService.controller.value.description.sensorOrientation +
                      rotationCompensation) %
                  360;
        } else {
          rotationCompensation =
              (_cameraService.controller.value.description.sensorOrientation -
                      rotationCompensation +
                      360) %
                  360;
        }
        rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
      }
      if (rotation == null) return;
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return;

      InputImage inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: format,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      // Detect faces
      final faces = await _faceService.detectFaces(inputImage);
      if (faces.isEmpty) {
        if (mounted) {
          ref.read(_customPaint.notifier).state = null;
        }
        _isBusy = false;
        return;
      }

      // Prepare input list
      List input = await compute(FaceRecognitionService.prepareInputFromNV21, {
        'nv21Data': image.planes[0].bytes,
        'width': image.width,
        'height': image.height,
        'isFrontCamera':
            _cameraService.controller.value.description.lensDirection ==
                CameraLensDirection.front,
        'face': faces.first
      });

      // Get embedding
      final embedding = _faceService.getEmbedding(input);
      // Identify the face
      Map<String, dynamic> emp = await _faceService.identifyFace(embedding);
      Color color = Colors.red;
      if (emp.isNotEmpty) {
        ref.read(empdetail.notifier).state = {
          "id": emp["code"],
          "name": emp["name"],
        };
        debugPrint('name is ${emp["code"]}');
        if (ref
            .read(attendanceDataNotifierProvider.notifier)
            .checkRepeat(emp["code"])) {
          debugPrint('attendance already added');
        } else {
          ref
              .read(attendanceDataNotifierProvider.notifier)
              .addEmployee(emp["code"], DateTime.now());
          showAttendancePopup();
        }
        color = Colors.green;
      }
      ref.read(_customPaint.notifier).state = CustomPaint(
        painter: FaceDetectorPainter(
          faces,
          inputImage.metadata!.size,
          inputImage.metadata!.rotation,
          _cameraService.controller.value.description.lensDirection,
          emp["name"] ?? "",
          color,
        ),
      );
    } finally {
      _isBusy = false;
    }
  }

  void showAttendancePopup() {
    _animController.forward();
    Future.delayed(const Duration(milliseconds: 1500), () {
      _animController.reverse();
    });
  }

  @override
  void dispose() {
    _faceService.dispose();
    _cameraService.dispose();
    _animController.dispose();
    debugPrint('dispose called');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btnLoad = ref.watch(btnLoader);
    final width = MediaQuery.of(context).size.width;
    final empDetail = ref.watch(empdetail);
    final customPaint = ref.watch(_customPaint);
    debugPrint('empDetail is $empDetail');
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [
          ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(2))),
              onPressed: btnLoad
                  ? null
                  : () async {
                      ref.read(btnLoader.notifier).state = true;
                      String phone = HiveUser.phoneNumber ?? '';
                      final value = await Services.sendWithOTP(phone);
                      if (value && context.mounted) {
                        Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => VerifyPage(
                                      phoneNumber: phone,
                                    )));
                        ref.read(btnLoader.notifier).state = false;
                        return;
                      } else {
                        ref.read(btnLoader.notifier).state = false;
                      }
                    },
              child: const Text(
                'Admin View',
                style: TextStyle(fontSize: 16),
              )),
          const SizedBox(width: 10),
        ],
      ),
      body: FutureBuilder(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Text('Loading...'));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            return Stack(
              fit: StackFit.expand,
              children: [
                Expanded(
                  child: Transform.scale(
                    scale: 1.1,
                    child: AspectRatio(
                      aspectRatio: MediaQuery.of(context).size.aspectRatio,
                      child: OverflowBox(
                        alignment: Alignment.center,
                        child: FittedBox(
                          fit: BoxFit.fitHeight,
                          child: SizedBox(
                            width: width,
                            height: width *
                                (_cameraService.controller.value.isInitialized
                                    ? _cameraService
                                        .controller.value.aspectRatio
                                    : 1),
                            child: CameraPreview(
                              _cameraService.controller,
                              child: customPaint,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (empDetail.isNotEmpty)
                  AttendanceAddedView(
                      empCode: empDetail["id"] ?? '',
                      offsetAnimation: _offsetAnimation,
                      empName: empDetail["name"] ?? ''),
              ],
            );
          }),
    );
  }
}

class AttendanceAddedView extends StatelessWidget {
  const AttendanceAddedView(
      {super.key,
      required this.empCode,
      required this.offsetAnimation,
      required this.empName});
  final String empCode, empName;
  final Animation<Offset> offsetAnimation;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: SlideTransition(
          position: offsetAnimation,
          child: Container(
            padding: EdgeInsets.all(width * 0.04),
            margin: EdgeInsets.only(top: width * 0.05, left: 14, right: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_outlined,
                  color: Colors.green,
                  size: 40,
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Attendance Marked!',
                        style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    Text(empName,
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 20)),
                    Text(
                        DateFormat('dd MMM, yyyy hh:mm a')
                            .format(DateTime.now()),
                        style: const TextStyle(
                            color: Colors.black87, fontSize: 14)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
