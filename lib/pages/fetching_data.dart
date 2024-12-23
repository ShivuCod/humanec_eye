import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:humanec_eye/pages/home.dart';
import 'package:humanec_eye/utils/apptheme.dart';
import '../providers/providers.dart';
import '../services/face_recognition_service.dart';
import '../services/services.dart';

class FetchingDataPage extends ConsumerStatefulWidget {
  static const routerName = '/fetching-data';

  const FetchingDataPage({super.key, this.isSwitching = false});
  final bool isSwitching;

  @override
  ConsumerState<FetchingDataPage> createState() => _FetchingDataPageState();
}

class _FetchingDataPageState extends ConsumerState<FetchingDataPage> {
  final isFetching = StateProvider<bool>((ref) => false);
  String currentStatus = "Fetching employee data...";
  int totalEmployees = 0;
  int processedEmployees = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchData();
    });
  }

  Future<void> fetchData() async {
    try {
      setState(() {
        currentStatus = "Fetching employee data...";
      });

      final data = await Services.getRegisteredEmployees('', 1, pageSize: 1000);
      totalEmployees = data.length;

      setState(() {
        currentStatus = "Processing employee data...";
      });

      for (var item in data) {
        if (!mounted) return;

        setState(() {
          currentStatus = "Processing ${item.empName ?? 'employee'}...";
        });

        try {
          String arrayString = jsonDecode(item.img);

          List<String> stringList =
              arrayString.replaceAll('[', '').replaceAll(']', '').split(',');

          List<double> faceData =
              stringList.map((e) => double.parse(e)).toList();

          debugPrint('Converted face data length: ${faceData.length}');

          final data = await FaceRecognitionService().identifyFace(faceData);
          if (data.isEmpty) {
            await FaceRecognitionService()
                .registerFace(item.empName ?? '', item.code ?? '', faceData);
          }

          processedEmployees++;
          setState(() {});

          debugPrint('Processed: ${item.empName}');
        } catch (e) {
          debugPrint('Error processing face data for ${item.empName}: $e');
        }
      }

      setState(() {
        currentStatus = "Finalizing...";
      });
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        Navigator.pop(
          context,
          HomePage.routerName,
        );
      }
      ref.invalidate(registeredEmployeesListProvider);
      ref.invalidate(unregisteredEmployeesListProvider);
      ref.invalidate(businessFutureProvider);
      if (widget.isSwitching) {
        if (mounted) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => HomePage()));
        }
      }
    } catch (e) {
      setState(() {
        currentStatus = "Error: $e";
      });
      debugPrint('error $e');
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SpinKitWanderingCubes(
                color: AppColor.black,
                size: 50.0,
              ),
              const SizedBox(height: 20),
              Text(
                currentStatus,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const Text(
                "Please wait while we are fetching your data...",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              )
            ],
          ),
        ),
      ),
    );
  }
}
