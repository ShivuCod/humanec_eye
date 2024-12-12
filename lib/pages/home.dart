import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humanec_eye/pages/recognize.dart';

import '../utils/apptheme.dart';
import 'employees.dart';
import 'profile.dart';

final indexProvider = StateProvider.autoDispose<int>((ref) => 0);

class HomePage extends StatelessWidget {
  static const routerName = '/home';

  HomePage({super.key});
  final List pages = [const EmployeesPage(), const ProfilePage()];

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
