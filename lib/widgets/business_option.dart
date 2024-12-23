import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humanec_eye/pages/home.dart';
import '../providers/providers.dart';
import '../services/services.dart';

class BusinessOption extends ConsumerWidget {
  const BusinessOption({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessFuture = ref.watch(businessFutureProvider);

    return businessFuture.when(
      data: (business) {
        debugPrint('business data ${business[0].id}');
        return SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                const Text(
                  "Switch Business",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final currentBusiness = ref.watch(currentBusinessProvider);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...List.generate(
                          business.length,
                          (index) => RadioListTile<String>(
                            value: business[index].id.toString(),
                            groupValue: currentBusiness,
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
                              ref.read(currentBusinessProvider.notifier).state =
                                  value;

                              if (value != null) {
                                final user = await Services.switchBusiness(
                                  value,
                                );

                                debugPrint('switching business $user $value');

                                if (user != null && context.mounted) {
                                  Navigator.pop(context);
                                  Navigator.pushReplacementNamed(
                                      context, HomePage.routerName);
                                }
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      error: (_, __) => const Center(),
      loading: () => const SizedBox(
        width: double.infinity,
        height: 250.0,
        child: SafeArea(
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
