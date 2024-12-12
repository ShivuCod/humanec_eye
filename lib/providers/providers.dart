import 'dart:collection';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance.dart';
import '../models/business.dart';
import '../models/employee.dart';
import '../pages/bussiness_option.dart';
import '../pages/home.dart';
import '../pages/login.dart';
import '../services/services.dart';
import '../utils/hive_config.dart';

final connectionsProvider =
    StateProvider.autoDispose<List<ConnectivityResult>>((ref) => []);

final registeredEmployeesListProvider = StateNotifierProvider.autoDispose
    .family<RegisterEmpNotifier, List<Employee>, String?>(
        (ref, search) => RegisterEmpNotifier(ref, search));

final unregisteredEmployeesListProvider = StateNotifierProvider.autoDispose
    .family<UnregisterEmpNotifier, List<Employee>, String?>(
        (ref, search) => UnregisterEmpNotifier(ref, search));

final searchResigterProvider = StateProvider.autoDispose<String>((ref) => '');
final searchUnregisterProvider = StateProvider.autoDispose<String>((ref) => '');

class RegisterEmpNotifier extends StateNotifier<List<Employee>> {
  final String? search;
  RegisterEmpNotifier(this.ref, this.search) : super([]) {
    _fetchStaffs();
  }

  final Ref ref;
  int _page = 1;
  bool _isFetching = false;

  Future<void> _fetchStaffs() async {
    if (_isFetching) return;
    _isFetching = true;

    debugPrint("register $_page query $search");
    final newStaffs =
        await Services.getRegisteredEmployees(search ?? "", _page);
    state = [...state, ...newStaffs];

    _page++;
    _isFetching = false;
  }

  Future<void> fetchMoreStaffs() async {
    await _fetchStaffs();
  }
}

class UnregisterEmpNotifier extends StateNotifier<List<Employee>> {
  final String? search;
  UnregisterEmpNotifier(this.ref, this.search) : super([]) {
    _fetchStaffs();
  }

  final Ref ref;
  int _page = 1;
  bool _isFetching = false;

  Future<void> _fetchStaffs() async {
    if (_isFetching) return;
    _isFetching = true;

    debugPrint('query ---- dsfjk $search');
    final newStaffs = await Services.getEmployees(search ?? "", _page);
    state = [...state, ...newStaffs];

    _page++;
    _isFetching = false;
  }

  Future<void> fetchMoreStaffs() async {
    await _fetchStaffs();
  }
}

final attendanceListProvider =
    FutureProvider.autoDispose<List<Attendance>>((ref) async {
  return Services.getAttendance();
});

final attendanceDataNotifierProvider = StateNotifierProvider<AttendanceNotifier,
    UnmodifiableMapView<String, DateTime>>((ref) => AttendanceNotifier());

class AttendanceNotifier
    extends StateNotifier<UnmodifiableMapView<String, DateTime>> {
  AttendanceNotifier() : super(UnmodifiableMapView({}));

  addEmployee(String key, DateTime value) {
    state = UnmodifiableMapView({...state, key: value});
  }

  bool checkRepeat(String key,
      {Duration threshold = const Duration(minutes: 5)}) {
    final data = state[key];
    return data != null && DateTime.now().isBefore(data.add(threshold));
  }
}

final businessFutureProvider = FutureProvider.autoDispose<List<Business>>(
  (ref) async {
    return Services.allBusiness();
  },
);

final currentBusinessProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final initialRouteProvider = Provider.autoDispose<String>(
  (ref) {
    final token = HiveUser.getAccessToken();
    if (token.isEmpty) {
      return LoginPage.routerName;
    }
    final mobileNumber = HiveUser.getUserName();
    if (mobileNumber.isEmpty) {
      return BusinessOptionPage.routerName;
    }
    return HomePage.routerName;
  },
);

class RecognizedListNotifier extends StateNotifier<List<String>> {
  RecognizedListNotifier() : super([]);

  void addItem(String item) {
    state = [...state, item];
  }

  void removeItem(String item) {
    state = state.where((element) => element != item).toList();
  }

  bool containsItem(String item) {
    return state.contains(item);
  }
}

final recognizedListProvider =
    StateNotifierProvider.autoDispose<RecognizedListNotifier, List<String>>(
        (ref) => RecognizedListNotifier());
