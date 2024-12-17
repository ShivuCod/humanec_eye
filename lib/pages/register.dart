import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:humanec_eye/pages/home.dart';
import 'package:humanec_eye/providers/providers.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/camera_service.dart';
import '../services/face_recognition_service.dart';
import '../services/services.dart';
import '../utils/apptheme.dart';
import '../utils/custom_buttom.dart';
import '../widgets/custom_message.dart';

class RegisterPage extends ConsumerStatefulWidget {
  static const routerName = '/registeration';
  const RegisterPage({super.key, this.name, this.empCode});
  final String? name;
  final String? empCode;

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final CameraService cameraService = CameraService();
  final FaceRecognitionService _faceService = FaceRecognitionService();
  final isLoading = StateProvider<bool>((ref) => false);
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      await _faceService.initialize();
      await cameraService
          .initialize(await availableCameras().then((value) => value[1]));
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

  Future<void> changeCamera() async {
    if (cameraService.controller.value.isInitialized) {
      if (cameraService.controller.value.description.lensDirection ==
          CameraLensDirection.back) {
        await cameraService
            .initialize(await availableCameras().then((value) => value[1]));
      } else {
        await cameraService
            .initialize(await availableCameras().then((value) => value[0]));
      }
    }
  }

  Future<void> _registerFace() async {
    ref.read(isLoading.notifier).state = true;
    final image = await cameraService.controller.takePicture();

    InputImage inputImage = InputImage.fromFile(File(image.path));
    final faces = await _faceService.detectFaces(inputImage);
    if (faces.isEmpty) {
      if (mounted) {
        showMessage('No face detected', context, isError: true);
      }
      return;
    }

    final input = FaceRecognitionService.prepareInputFromImagePath({
      'imgPath': image.path,
      'face': faces.first,
    });
    final embedding = _faceService.getEmbedding(input);
    final emp = await _faceService.identifyFace(embedding);
    if (emp.isNotEmpty) {
      if (mounted) {
        showMessage('Face already registered', context, isError: true);
      }
      return;
    }
    try {
      debugPrint('embedding $embedding');
      await _faceService.registerFace(
          widget.name ?? '', widget.empCode ?? "", embedding);
      await Services.registerEmployees(
          empCode: widget.empCode ?? '',
          embeding: json.encode(embedding),
          img: image.path);
    } catch (e) {
      if (mounted) {
        showMessage('Error registering face: $e', context, isError: true);
      }
    } finally {
      if (mounted) {
        ref.read(isLoading.notifier).state = false;
        Navigator.pop(context);
        showMessage('Face registered successfully', context);
        ref.invalidate(registeredEmployeesListProvider);
        ref.invalidate(unregisteredEmployeesListProvider);
      }
    }
    ref.read(isLoading.notifier).state = false;
  }

  @override
  void dispose() {
    cameraService.dispose();
    _faceService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoad = ref.watch(isLoading);
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
            backgroundColor: Colors.white,
            title: const Text('Register Page'),
            actions: [
              IconButton(
                  onPressed: () async {
                    await changeCamera();
                    setState(() {});
                  },
                  icon: const Icon(Icons.sync))
            ]),
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
              return Column(
                children: [
                  Expanded(
                      child: Transform.scale(
                    scale: 1,
                    child: OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: width *
                              cameraService.controller.value.aspectRatio,
                          child: CameraPreview(cameraService.controller),
                        ),
                      ),
                    ),
                  )),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: CustomButton(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isLoad)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: AppColor.white,
                                ),
                              ),
                            Text(isLoad ? "Loading..." : "Register"),
                          ],
                        ),
                        onPressed: isLoad
                            ? null
                            : () {
                                ref.read(isLoading.notifier).state = true;
                                _registerFace();
                                ref.read(isLoading.notifier).state = false;
                              }),
                  ),
                ],
              );
            }));
  }
}
