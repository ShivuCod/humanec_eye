import 'dart:convert';
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
import 'package:web_socket_channel/web_socket_channel.dart';
import '../core/microservice_endpoint.dart';
import '../providers/providers.dart';
import '../services/camera_service.dart';
import '../services/face_recognition_service.dart';
import '../services/services.dart';
import '../utils/hive_config.dart';
import '../utils/utils.dart';
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
  late final FaceRecognitionService _faceService;
  late final CameraService _cameraService;
  late Future<void> _initializeControllerFuture;
  late AnimationController _animController;
  late Animation<Offset> _offsetAnimation;
  final audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isBusy = false;
  late WebSocketChannel _channel;
  final empdetail =
      StateProvider.autoDispose<Map<String, dynamic>>((ref) => {});
  final faceProvider = StateProvider.autoDispose<Face?>((ref) => null);
  final _customPaint = StateProvider<CustomPaint?>((ref) => null);
  final btnLoader = StateProvider<bool>((ref) => false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _faceService = FaceRecognitionService();
    _cameraService = CameraService();
    _initializeControllerFuture = _initializeServices();
    _setupAnimation();
  }

  void _initializeWebSocket() {
    _channel =
        WebSocketChannel.connect(Uri.parse(MicroServiceEndpoint.scanFace));
  }

  void _setupAnimation() {
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
      _initializeWebSocket();
      await _faceService.initialize();
      final cameras = await availableCameras();
      await _cameraService.initialize(cameras[1]);
      debugPrint('Camera initialized');
      _cameraService.startImageStream(_processCameraImage);
    } catch (e) {
      if (e is CameraException && e.code == "CameraAccessDenied") {
        _showCameraPermissionDialog();
      } else {
        debugPrint('Error initializing services: $e');
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
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(
                          context, HomePage.routerName);
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
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
    if (_isBusy) return;
    _isBusy = true;

    try {
      final cameraValue = _cameraService.controller.value;
      final rotation = await _getImageRotation(cameraValue);

      if (rotation == null || !mounted) return;

      final inputImage = _createInputImage(image, rotation);
      final faces = await _faceService.detectFaces(inputImage);

      if (faces.isEmpty) {
        _handleNoFacesDetected();
      } else {
        _handleFacesDetected(inputImage, faces, inputImage.metadata!.size,
            cameraValue.description.lensDirection);
      }
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isBusy = false;
    }
  }

  Future<InputImageRotation?> _getImageRotation(CameraValue cameraValue) async {
    final cameraDescription = cameraValue.description;
    return await compute(_getInputImageRotation, {
      'sensorOrientation': cameraDescription.sensorOrientation,
      'deviceOrientation': cameraValue.deviceOrientation,
      'isIOS': Platform.isIOS,
      'lensDirection': cameraDescription.lensDirection,
    });
  }

  InputImage _createInputImage(CameraImage image, InputImageRotation rotation) {
    return InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormatValue.fromRawValue(image.format.raw) ??
            InputImageFormat.bgra8888,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  void _handleNoFacesDetected() {
    if (mounted) {
      ref.read(empdetail.notifier).update((state) => {});
    }
  }

  void _handleFacesDetected(InputImage inputImage, List<Face> faces,
      Size imageSize, CameraLensDirection lensDirection) {
    final face = findNearestFace(faces, imageSize);
    if (face != null) {
      ref.read(faceProvider.notifier).state = face;
      _captureImage();
    } else {
      ref.read(faceProvider.notifier).state = null;
    }
    ref.read(_customPaint.notifier).update((state) => CustomPaint(
          painter: FaceDetectorPainter(
            faces,
            inputImage.metadata!.size,
            inputImage.metadata!.rotation,
            _cameraService.controller.description.lensDirection,
            "",
            Colors.green,
          ),
        ));
  }

  Size? getImageSize() {
    if (!_cameraService.controller.value.isInitialized ||
        _cameraService.controller.value.previewSize == null) {
      return null;
    }
    return Size(_cameraService.controller.value.previewSize!.height,
        _cameraService.controller.value.previewSize!.width);
  }

  Face? findNearestFace(List<Face> faces, Size imageSize) {
    if (faces.isEmpty) return null;
    final centerX = imageSize.width / 2;
    final centerY = imageSize.height / 2;
    Face? nearestFace;
    double nearestDistance = double.infinity;

    for (var face in faces) {
      final dx = (face.boundingBox.center.dx - centerX).abs();
      final dy = (face.boundingBox.center.dy - centerY).abs();
      final distance = dx + dy;
      if ((distance < 250) && (distance < nearestDistance)) {
        nearestDistance = distance;
        nearestFace = face;
      }
    }
    return nearestFace;
  }

  Future<void> _captureImage() async {
    try {
      final image = await _cameraService.controller.takePicture();
      String base64Image = await Utils.convertToBase64(image);
      String jsonRequest =
          json.encode({'frame': base64Image, 'org_id': HiveUser.getOrgId()});
      _channel.sink.add(jsonRequest);
    } catch (e) {
      debugPrint('Error capturing image: $e');
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
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        _pauseServices();
        break;
      case AppLifecycleState.resumed:
        _resumeServices();
        break;
      case AppLifecycleState.detached:
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
    _animController.dispose();
    _cameraService.dispose();
    _faceService.dispose();
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final btnLoad = ref.watch(btnLoader);
    final width = MediaQuery.of(context).size.width;
    final empDetail = ref.watch(empdetail);
    final customPaint = ref.watch(_customPaint);
    final face = ref.watch(faceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(btnLoad),
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: FutureBuilder(
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
          ),
          StreamBuilder(
            stream: _channel.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _handleSocketData(snapshot.data, face);
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }

  void _handleSocketData(dynamic data, Face? face) {
    debugPrint('jsonData socket data $data');
    if (face != null) {
      var socketData = json.decode(data);
      if (socketData['emp'] == 0) {
        debugPrint('Emp not found or recognized');
      } else {
        var id = socketData['emp']['emp_id'];
        Future.delayed(const Duration(milliseconds: 150), () {
          ref.read(empdetail.notifier).state = {
            "id": id,
            "name": socketData['emp']['name']
          };
          if (!ref
              .read(attendanceDataNotifierProvider.notifier)
              .checkRepeat(id)) {
            ref
                .read(attendanceDataNotifierProvider.notifier)
                .addEmployee(id, DateTime.now());
            _playSound();
            _addAttendance(id);
          } else {
            debugPrint('Attendance marked already');
          }
        });
      }
    } else {
      debugPrint("Socket data does not have a face");
    }
  }

  _addAttendance(String empCode) async {
    String currentDateTime =
        DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    await Services.addAttendance(empCode: empCode, datetime: currentDateTime)
        .then((value) {
      if (value == true) {
        showAttendancePopup();
      } else {
        showMessage('Failed to add attendance.', context);
      }
    });
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
      String phone = HiveUser.phoneNumber ?? '';
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => VerifyPage(phoneNumber: phone),
          ),
        );
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
