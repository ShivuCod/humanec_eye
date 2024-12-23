import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/apptheme.dart';
import '../utils/hive_config.dart';
import '../widgets/business_option.dart';
import '../widgets/custom_message.dart';
import 'register.dart';

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});
  static const String routerName = '/employees';

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 2,
      child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: AppColor.white,
            surfaceTintColor: Colors.white,
            title: Consumer(builder: (context, ref, child) {
              final businessFuture = ref.watch(businessFutureProvider);

              return businessFuture.when(
                data: (business) {
                  if (business.isEmpty) {
                    return const Text('No businesses found');
                  }
                  final currentBusiness = business
                      .where((e) => e.id == HiveUser.getUserName())
                      .first;
                  debugPrint('currentBusiness ${currentBusiness.orgName}');
                  return InkWell(
                    onTap: () {
                      showModalBottomSheet(
                          context: context,
                          builder: (_) => const BusinessOption());
                    },
                    child: Row(
                      children: [
                        Text(
                          currentBusiness.orgName
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase() +
                              currentBusiness.orgName
                                  .toString()
                                  .substring(1)
                                  .toLowerCase(),
                          style: const TextStyle(fontWeight: FontWeight.w400),
                        ),
                        const SizedBox(width: 10),
                        const Icon(Icons.arrow_drop_down,
                            size: 12, color: Colors.black54),
                      ],
                    ),
                  );
                },
                loading: () => const Center(),
                error: (error, stackTrace) => Text('Error: $error'),
              );
            }),
            forceMaterialTransparency: true,
            bottom: const TabBar(
              overlayColor: WidgetStatePropertyAll(Colors.white),
              labelColor: AppColor.black,
              indicatorColor: AppColor.black,
              unselectedLabelColor: Colors.grey,
              tabs: <Widget>[
                Tab(text: 'Registered'),
                Tab(text: 'Unregistered'),
              ],
            ),
          ),
          body: Consumer(builder: (c, ref, child) {
            final searchRegisterText = ref.watch(searchResigterProvider);
            final searchUnregisterText = ref.watch(searchUnregisterProvider);

            final registeredEmployeesListValue =
                ref.watch(registeredEmployeesListProvider(searchRegisterText));
            final unregisteredEmployeesListValue = ref
                .watch(unregisteredEmployeesListProvider(searchUnregisterText));

            return TabBarView(children: [
              Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 15, left: 14, right: 14),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search Employee',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColor.black, width: 2.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColor.black, width: 2.0),
                        ),
                      ),
                      onChanged: (value) {
                        Timer(const Duration(milliseconds: 500), () {
                          ref.read(searchResigterProvider.notifier).state =
                              value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification) {
                          ref
                              .read(registeredEmployeesListProvider(
                                      searchRegisterText)
                                  .notifier)
                              .fetchMoreStaffs();
                        }
                        return true;
                      },
                      child: RefreshIndicator(
                        color: AppColor.black,
                        onRefresh: () async {
                          ref.invalidate(registeredEmployeesListProvider);
                        },
                        child: registeredEmployeesListValue.isEmpty
                            ? const Center(
                                child: Text("No Employee Found"),
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 12),
                                itemBuilder: (c, i) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey
                                                .withValues(alpha: 0.5),
                                            width: 1)),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: (registeredEmployeesListValue[i]
                                                      .imgAttn ==
                                                  null ||
                                              registeredEmployeesListValue[i]
                                                      .imgAttn ==
                                                  '')
                                          ? CircleAvatar(
                                              radius: 24,
                                              backgroundColor: Colors.grey
                                                  .withValues(alpha: 0.3),
                                              child: Icon(
                                                  Icons.person_outline_rounded,
                                                  color: Colors.grey.shade700),
                                            )
                                          : Container(
                                              height: 48,
                                              width: 48,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  border: Border.all(
                                                      color: Colors.grey
                                                          .withValues(
                                                              alpha: 0.5),
                                                      width: 1),
                                                  image: DecorationImage(
                                                      image: NetworkImage(
                                                          registeredEmployeesListValue[
                                                                      i]
                                                                  .imgAttn ??
                                                              ''),
                                                      fit: BoxFit.cover)),
                                            ),
                                      title: Text(
                                        '${registeredEmployeesListValue[i].empName} - ${registeredEmployeesListValue[i].code}',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      trailing: PopupMenuButton(
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10)),
                                        color: AppColor.white,
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.more_vert),
                                        itemBuilder: (c) {
                                          return [
                                            PopupMenuItem(
                                                onTap: () => _unregisterEmployee(
                                                    context,
                                                    ref,
                                                    registeredEmployeesListValue[
                                                                i]
                                                            .code ??
                                                        ''),
                                                child: const Text(
                                                  'Remove',
                                                  style:
                                                      TextStyle(fontSize: 16),
                                                )),
                                          ];
                                        },
                                      ),

                                      // trailing: IconButton(
                                      //   icon: const Icon(Icons.chevron_right),
                                      //   onPressed: () => Navigator.push(
                                      //       context,
                                      //       MaterialPageRoute(
                                      //           builder: (context) => RegisterPage(
                                      //               name:
                                      //                   registeredEmployeesListValue[
                                      //                               i]
                                      //                           .empName ??
                                      //                       '',
                                      //               empCode:
                                      //                   registeredEmployeesListValue[
                                      //                               i]
                                      //                           .code ??
                                      //                       ''))
                                      // ),
                                      // ),
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) =>
                                    const SizedBox(
                                  height: 10,
                                ),
                                itemCount: registeredEmployeesListValue.length,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(top: 15, left: 14, right: 14),
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search Employee',
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColor.black, width: 2.0),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: AppColor.black, width: 2.0),
                        ),
                      ),
                      onChanged: (value) {
                        Timer(const Duration(milliseconds: 500), () {
                          ref.read(searchUnregisterProvider.notifier).state =
                              value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification) {
                          ref
                              .read(unregisteredEmployeesListProvider(
                                      searchUnregisterText)
                                  .notifier)
                              .fetchMoreStaffs();
                        }
                        return true;
                      },
                      child: RefreshIndicator(
                        color: AppColor.black,
                        onRefresh: () async {
                          ref.invalidate(unregisteredEmployeesListProvider);
                        },
                        child: unregisteredEmployeesListValue.isEmpty
                            ? const Center(
                                child: Text("No Employee Found"),
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 12),
                                itemBuilder: (c, i) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4, horizontal: 8),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: Colors.grey
                                                .withValues(alpha: 0.5),
                                            width: 1)),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: (unregisteredEmployeesListValue[
                                                          i]
                                                      .imgAttn ==
                                                  null ||
                                              unregisteredEmployeesListValue[i]
                                                      .imgAttn ==
                                                  '')
                                          ? CircleAvatar(
                                              radius: 24,
                                              backgroundColor: Colors.grey
                                                  .withValues(alpha: 0.3),
                                              child: Icon(
                                                  Icons.person_outline_rounded,
                                                  color: Colors.grey.shade700),
                                            )
                                          : Container(
                                              height: 48,
                                              width: 48,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  border: Border.all(
                                                      color: Colors.grey
                                                          .withValues(
                                                              alpha: 0.5),
                                                      width: 1),
                                                  image: DecorationImage(
                                                      image: NetworkImage(
                                                          unregisteredEmployeesListValue[
                                                                      i]
                                                                  .imgAttn ??
                                                              ''),
                                                      fit: BoxFit.cover)),
                                            ),
                                      title: Text(
                                        '${unregisteredEmployeesListValue[i].empName} - ${unregisteredEmployeesListValue[i].code}',
                                        style: const TextStyle(fontSize: 18),
                                      ),
                                      trailing: const Icon(Icons.chevron_right),
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) => RegisterPage(
                                                    name:
                                                        unregisteredEmployeesListValue[
                                                                    i]
                                                                .empName ??
                                                            '',
                                                    empCode:
                                                        unregisteredEmployeesListValue[
                                                                    i]
                                                                .code ??
                                                            '')));
                                      },
                                    ),
                                  );
                                },
                                separatorBuilder: (context, index) =>
                                    const SizedBox(
                                  height: 10,
                                ),
                                itemCount:
                                    unregisteredEmployeesListValue.length,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ]);
          })),
    );
  }

  _unregisterEmployee(
      BuildContext context, WidgetRef ref, String empCode) async {
    await Services.removeEmployees(empCode: empCode).then((value) async {
      if (value == true) {
        ref.invalidate(registeredEmployeesListProvider);
        ref.invalidate(unregisteredEmployeesListProvider);
        showMessage('Employee removed successfully.', context);
      } else {
        showMessage('Failed to remove employee.', context);
      }
    });
  }
}
