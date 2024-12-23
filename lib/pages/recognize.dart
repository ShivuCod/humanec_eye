import 'dart:io';
import 'package:camera/camera.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:humanec_eye/pages/verify.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/providers.dart';
import '../services/camera_service.dart';
import '../services/face_recognition_service.dart';
import '../services/services.dart';
import '../services/sync_service.dart';
import '../utils/hive_config.dart';
import '../widgets/custom_message.dart';
import '../widgets/face_painter.dart';
import 'home.dart';

class RecognizePage extends ConsumerStatefulWidget {
  const RecognizePage({super.key});
  static const routerName = '/recognize';

  @override
  ConsumerState<RecognizePage> createState() => _RecognizePageState();
}

class _RecognizePageState extends ConsumerState<RecognizePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final CameraService _cameraService = CameraService();
  late Future<void> _initializeControllerFuture;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  final audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isBusy = false;
  final _customPaint = StateProvider<CustomPaint?>((ref) => null);
  final btnLoader = StateProvider<bool>((ref) => false);
  final empdetail = StateProvider<Map<String, dynamic>>((ref) => {});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeControllerFuture = _initializeServices();
    _setupAnimation();
  }

  void _setupAnimation() async {
    _animController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeServices() async {
    try {
      await _faceService.initialize();
      final cameras = await availableCameras();
      await _cameraService.initialize(cameras[1]);
      debugPrint('Camera initialized');
      _cameraService.startImageStream(_processCameraImage);
    } catch (e) {
      if (e is CameraException && e.code == "CameraAccessDenied") {
        _showCameraPermissionDialog();
      } else {
        debugPrint('Error sd services: $e');
      }

      throw Exception('Error initializing services: $e');
    }
  }

  void _showCameraPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Camera Permission Required',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'This app needs camera access to capture attendance. Please grant camera permission in settings.',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(
                          context, HomePage.routerName);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await openAppSettings();

                      if (mounted) {
                        final newStatus = await Permission.camera.status;
                        if (newStatus.isGranted) {
                          _initializeServices();
                        } else {
                          Navigator.pushReplacementNamed(
                              context, HomePage.routerName);
                        }
                      }
                    },
                    child: const Text('Open Settings'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processCameraImage(CameraImage image) async {
    debugPrint('Processing image');
    if (_isBusy) return;
    _isBusy = true;

    try {
      final cameraValue = _cameraService.controller.value;
      final cameraDescription = cameraValue.description;

      final rotation = await compute(_getInputImageRotation, {
        'sensorOrientation': cameraDescription.sensorOrientation,
        'deviceOrientation': cameraValue.deviceOrientation,
        'isIOS': Platform.isIOS,
        'lensDirection': cameraDescription.lensDirection,
      });

      if (rotation == null || !mounted) return;

      final inputImage = InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormatValue.fromRawValue(image.format.raw) ??
              InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );

      final faces = await _faceService.detectFaces(inputImage);
      if (faces.isEmpty) {
        if (mounted) {
          ref.read(_customPaint.notifier).update((state) => null);
          ref.read(empdetail.notifier).update((state) => {});
        }
        return;
      }
      List input = await compute(FaceRecognitionService.prepareInputFromNV21, {
        'nv21Data': image.planes[0].bytes,
        'width': image.width,
        'height': image.height,
        'isFrontCamera':
            _cameraService.controller.value.description.lensDirection ==
                CameraLensDirection.front,
        'face': faces.first
      });

      final embedding = _faceService.getEmbedding(input);

      if (!mounted) return;

      final emp = await _faceService.identifyFace(embedding);

      if (mounted) {
        ref.read(empdetail.notifier).update((state) => emp.isEmpty
            ? {}
            : {
                "id": emp["code"],
                "name": emp["name"],
              });

        if (emp.isNotEmpty &&
            !ref
                .read(attendanceDataNotifierProvider.notifier)
                .checkRepeat(emp["code"])) {
          final datetime =
              DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
          try {
            ref
                .read(attendanceDataNotifierProvider.notifier)
                .addEmployee(emp["code"], DateTime.now());

            if ((await Connectivity().checkConnectivity())
                .contains(ConnectivityResult.none)) {
              await HiveAttendance.saveAttendance(emp["code"], datetime);
            } else {
              await SyncService.syncAttendance();
              await Services.addAttendance(
                empCode: emp["code"],
                datetime: datetime,
              );
            }
          } catch (e) {
            debugPrint('Error in saving Attendance: $e');
            await HiveAttendance.saveAttendance(emp["code"], datetime);
          }
          showAttendancePopup();
          _playSound();
        } else {
          debugPrint("Employee already marked");
        }

        ref.read(_customPaint.notifier).update((state) => CustomPaint(
              painter: FaceDetectorPainter(
                faces,
                inputImage.metadata!.size,
                inputImage.metadata!.rotation,
                cameraDescription.lensDirection,
                emp["name"] ?? "",
                emp.isEmpty ? Colors.red : Colors.green,
              ),
            ));
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isBusy = false;
    }
  }

  void _playSound() async {
    if (!_isPlaying) {
      _isPlaying = true;
      audioPlayer.setVolume(0.8);
      await audioPlayer.setAsset('assets/thank-you.mp3');
      await audioPlayer.play();

      Future.delayed(const Duration(milliseconds: 200), () {
        audioPlayer.stop();

        _isPlaying = false;
      });
    }
  }

  void showAttendancePopup() {
    _animController.forward();
    Future.delayed(const Duration(milliseconds: 1500), () {
      _animController.reverse();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.paused:
        _pauseServices();
        break;
      case AppLifecycleState.resumed:
        _resumeServices();
        break;
      case AppLifecycleState.inactive:
        _pauseServices();
        break;
      case AppLifecycleState.detached:
        _cleanupResources();
        break;
      case AppLifecycleState.hidden:
        _pauseServices(); // Handle hidden state similar to paused
        break;
    }
  }

  Future<void> _pauseServices() async {
    try {
      _isBusy = true;
      if (_cameraService.controller.value.isStreamingImages) {
        await _cameraService.controller.stopImageStream();
      }
      if (_animController.isAnimating) {
        _animController.stop();
      }
    } catch (e) {
      debugPrint('Error pausing services: $e');
    }
  }

  Future<void> _resumeServices() async {
    try {
      if (!_cameraService.controller.value.isStreamingImages) {
        await _cameraService.controller.startImageStream(_processCameraImage);
      }
      _isBusy = false;
    } catch (e) {
      debugPrint('Error resuming services: $e');
    }
  }

  @override
  void deactivate() {
    _pauseServices();
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupResources();
    super.dispose();
  }

  Future<void> _cleanupResources() async {
    try {
      _isBusy = true;

      if (_animController.isAnimating) {
        _animController.stop();
      }
      _animController.dispose();

      if (_cameraService.controller.value.isStreamingImages) {
        await _cameraService.controller.stopImageStream();
      }

      await _cameraService.dispose();

      _faceService.dispose();

      if (mounted) {
        ref.read(_customPaint.notifier).state = null;
        ref.read(empdetail.notifier).state = {};
        ref.read(btnLoader.notifier).state = false;
      }
    } catch (e) {
      debugPrint('Error during cleanup: $e');
    }
  }

  void didPush() {
    _resumeServices();
  }

  void didPop() {
    _pauseServices();
  }

  @override
  Widget build(BuildContext context) {
    final btnLoad = ref.watch(btnLoader);
    final width = MediaQuery.of(context).size.width;
    final empDetail = ref.watch(empdetail);
    final customPaint = ref.watch(_customPaint);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(btnLoad),
      body: FutureBuilder(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SpinKitWanderingCubes(
                color: Colors.white,
                size: 50,
              ),
            );
          }
          if (snapshot.hasError) {
            return const Center(
              child: SpinKitWanderingCubes(
                color: Colors.white,
                size: 50,
              ),
            );
          }
          return _buildCameraPreview(width, empDetail, customPaint);
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool btnLoad) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white12,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          onPressed: btnLoad ? null : _handleAdminView,
          child: const Text(
            'Admin View',
            style: TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }

  Future<void> _handleAdminView() async {
    ref.read(btnLoader.notifier).state = true;
    if ((await Connectivity().checkConnectivity())
        .contains(ConnectivityResult.none)) {
      if (mounted) {
        showMessage('Please check your internet connection', context,
            isError: true);
      }
    } else {
      await SyncService.syncAttendance();
      String phone = HiveUser.phoneNumber ?? '';
      // final value = await Services.sendWithOTP(phone);
      if (true && context.mounted) {
        if (mounted) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (_) => VerifyPage(
                        phoneNumber: phone,
                      )));
        }

        return;
      }
    }
    ref.read(btnLoader.notifier).state = false;
  }

  Widget _buildCameraPreview(
      double width, Map<String, dynamic> empDetail, CustomPaint? customPaint) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
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
                          ? _cameraService.controller.value.aspectRatio
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
        if (empDetail.isNotEmpty)
          AttendanceAddedView(
            empCode: empDetail["id"] ?? '',
            offsetAnimation: _offsetAnimation,
            empName: empDetail["name"] ?? '',
          ),
      ],
    );
  }
}

InputImageRotation? _getInputImageRotation(Map<String, dynamic> params) {
  final orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  if (params['isIOS']) {
    return InputImageRotationValue.fromRawValue(params['sensorOrientation']);
  }

  var rotationCompensation =
      orientations[params['deviceOrientation'] as DeviceOrientation];
  if (rotationCompensation == null) return null;

  if (params['lensDirection'] == CameraLensDirection.front) {
    rotationCompensation =
        (params['sensorOrientation'] + rotationCompensation) % 360;
  } else {
    rotationCompensation =
        (params['sensorOrientation'] - rotationCompensation + 360) % 360;
  }

  return InputImageRotationValue.fromRawValue(rotationCompensation ?? 0);
}

class AttendanceAddedView extends StatelessWidget {
  const AttendanceAddedView({
    super.key,
    required this.empCode,
    required this.offsetAnimation,
    required this.empName,
  });

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
                    const Text(
                      'Attendance Marked!',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      empName,
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 20),
                    ),
                    Text(
                      DateFormat('dd MMM, yyyy hh:mm a').format(DateTime.now()),
                      style:
                          const TextStyle(color: Colors.black87, fontSize: 14),
                    ),
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
