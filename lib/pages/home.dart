import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humanec_eye/pages/recognize.dart';
import 'package:workmanager/workmanager.dart';
import '../services/sync_service.dart';
import '../utils/apptheme.dart';
import 'employees.dart';
import 'profile.dart';

final indexProvider = StateProvider.autoDispose<int>((ref) => 0);

class HomePage extends StatefulWidget with WidgetsBindingObserver {
  static const routerName = '/home';

  HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List pages = [const EmployeesPage(), const ProfilePage()];

  Timer? _syncTimer;

  @override
  void initState() {
    super.initState();

    Workmanager().initialize(callbackDispatcher);

    Workmanager().registerPeriodicTask(
      "sync-attendance",
      "syncAttendance",
      frequency: const Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (c, ref, child) {
      final int index = ref.watch(indexProvider);
      return Scaffold(
        backgroundColor: Colors.white,
        body: pages[index],
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColor.black,
          foregroundColor: AppColor.white,
          child: const Icon(Icons.camera_alt_outlined),
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
                context, RecognizePage.routerName, (route) => false);
          },
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          unselectedItemColor: Colors.grey,
          selectedItemColor: AppColor.black,
          currentIndex: index,
          onTap: (int idx) {
            ref.read(indexProvider.notifier).state = idx;
          },
          items: const [
            BottomNavigationBarItem(
              label: 'Employee',
              icon: Icon(Icons.people_alt_outlined),
            ),
            BottomNavigationBarItem(
              label: 'Profile',
              icon: Icon(Icons.person_2_outlined),
            ),
          ],
        ),
      );
    });
  }
}
