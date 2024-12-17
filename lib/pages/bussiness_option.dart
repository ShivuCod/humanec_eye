import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../utils/apptheme.dart';
import '../utils/custom_buttom.dart';
import '../utils/hive_config.dart';
import '../widgets/custom_message.dart';
import 'fetching_data.dart';

final _loaderBtnProvider = StateProvider.autoDispose((ref) => false);

class BusinessOptionPage extends StatelessWidget {
  static const routerName = '/business_option';

  const BusinessOptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
          bottom: 100.0,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text.rich(
                  TextSpan(
                    text: "Welcome ",
                    style: TextStyle(fontSize: 25),
                    children: [
                      TextSpan(
                        text: "To \nHumanec ",
                        style: TextStyle(fontSize: 20),
                      ),
                      TextSpan(
                        text: "Eye",
                        style: TextStyle(
                            fontWeight: FontWeight.w900, fontSize: 20),
                      ),
                      TextSpan(
                        text: "\n\nSelect your Business?",
                        style: TextStyle(
                          fontWeight: FontWeight.w300,
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Consumer(
                  builder: (context, ref, child) {
                    final businessFuture = ref.watch(businessFutureProvider);

                    return businessFuture.when(
                      data: (business) {
                        return Consumer(
                          builder: (context, ref, child) {
                            final currentBusiness = ref.watch(
                              currentBusinessProvider,
                            );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ...List.generate(
                                  business.length,
                                  (index) => RadioListTile<String>(
                                    value: business[index].id.toString(),
                                    groupValue: currentBusiness,
                                    activeColor: AppColor.black,
                                    title: Text(
                                      business[index]
                                              .orgName
                                              .toString()
                                              .substring(0, 1)
                                              .toUpperCase() +
                                          business[index]
                                              .orgName
                                              .toString()
                                              .substring(1)
                                              .toLowerCase(),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    onChanged: (String? value) async {
                                      debugPrint('onChanged $value');
                                      ref
                                          .read(
                                            currentBusinessProvider.notifier,
                                          )
                                          .state = value;
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      error: (_, __) => const Center(),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(10.0),
        child: Consumer(
          builder: (context, ref, child) {
            final loaderBtn = ref.watch(_loaderBtnProvider);

            final currentBusiness = ref.watch(
              currentBusinessProvider,
            );

            if (loaderBtn) {
              return const CircularProgressIndicator(color: AppColor.black);
            }

            return CustomButton(
              title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (loaderBtn)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColor.white,
                      ),
                    ),
                  Text(loaderBtn ? "Loading..." : "Continue"),
                ],
              ),
              onPressed: currentBusiness != null && currentBusiness.isNotEmpty
                  ? () async {
                      ref.read(_loaderBtnProvider.notifier).state = true;

                      HiveUser.setUserName(currentBusiness);
                      await Services.switchBusiness(
                        currentBusiness,
                      );
                      await Permission.camera
                          .onDeniedCallback(() {
                            showMessage(
                                "Please Grant Camera Permission", context,
                                isError: true);
                          })
                          .onGrantedCallback(() {})
                          .onPermanentlyDeniedCallback(() {
                            showMessage(
                                "Please Enable Camera Permission", context,
                                isError: true);
                          })
                          .onRestrictedCallback(() {
                            showMessage(
                                "Please Enable Camera Permission", context,
                                isError: true);
                          })
                          .onLimitedCallback(() {
                            showMessage(
                                "Please Enable Camera Permission", context,
                                isError: true);
                          })
                          .request();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FetchingDataPage(
                            isSwitching: true,
                          ),
                        ),
                      );
                      ref.read(_loaderBtnProvider.notifier).state = false;
                    }
                  : null,
            );
          },
        ),
      ),
    );
  }
}
