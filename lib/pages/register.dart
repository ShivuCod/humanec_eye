import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:humanec_eye/pages/home.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/camera_service.dart';
import '../services/services.dart';
import '../utils/apptheme.dart';
import '../utils/custom_buttom.dart';
import '../utils/utils.dart';
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
  final isLoading = StateProvider<bool>((ref) => false);
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeControllerFuture = _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
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

  @override
  void dispose() {
    cameraService.dispose();
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
                                _registerEmployee(
                                    widget.empCode ?? "", widget.name ?? "");
                                ref.read(isLoading.notifier).state = false;
                              }),
                  ),
                ],
              );
            }));
  }

  _registerEmployee(String empCode, String empName) async {
    final XFile xImage = await cameraService.controller.takePicture();
    final File image = await Utils.getOrientedImage(xImage);
    debugPrint('image path ${image.path} empCode $empCode empName $empName');

    await Services.addEmployees(
            empCode: empCode, empName: empName, image: image)
        .then((value) async {
      debugPrint("addEmployees response is $value");
      if (value["status"]) {
        debugPrint('registering employee');
        await Services.registerEmployees(empCode: empCode, image: image)
            .then((regValue) {
          if (regValue) {
            ref.read(isLoading.notifier).state = false;
            showMessage("Face Registered Successfully", context);
            Navigator.pop(context, true);
          } else {
            ref.read(isLoading.notifier).state = false;
            showMessage("Failed to register employee.", context, isError: true);
          }
        });
      } else {
        ref.read(isLoading.notifier).state = false;
        showMessage(value["message"], context, isError: true);
      }
    });
  }
}
