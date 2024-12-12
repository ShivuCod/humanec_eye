// ignore_for_file: unused_result, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';
import '../utils/apptheme.dart';
import '../utils/custom_buttom.dart';
import 'custom_message.dart';
import 'otp_field.dart';

class SetPinDialog extends ConsumerStatefulWidget {
  const SetPinDialog({super.key});

  @override
  ConsumerState<SetPinDialog> createState() => _NameChangeState();
}

class _NameChangeState extends ConsumerState<SetPinDialog> {
  final globalKey = GlobalKey<FormState>();
  final load = StateProvider.autoDispose<bool>((ref) => false);
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(load);
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Set PIN",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close,
                  size: 15,
                  color: Colors.black,
                ),
              )
            ],
          ),
          const Text("Enter the PIN",
              style: TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 10),
          Row(
            children: List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: OTPTextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  onChanged: (value) {
                    if (value.isNotEmpty && index < 3) {
                      FocusScope.of(context)
                          .requestFocus(_focusNodes[index + 1]);
                    } else if (value.isEmpty && index > 0) {
                      FocusScope.of(context)
                          .requestFocus(_focusNodes[index - 1]);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.black),
                )
              : SizedBox(
                  height: 45,
                  child: CustomButton(
                    title: Row(
                      children: [
                        if (isLoading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColor.white,
                            ),
                          ),
                        if (isLoading) const SizedBox(width: 10),
                        Text(isLoading ? "Saving..." : "Save"),
                      ],
                    ),
                    onPressed: () async {
                      if (globalKey.currentState!.validate()) {
                        _handleOtpSubmission(
                            _controllers.map((e) => e.text).join(""));
                      }
                    },
                  ),
                )
        ],
      ),
    );
  }

  _handleOtpSubmission(String value) async {
    ref.read(load.notifier).state = true;
    if (await Services().setPin(value)) {
      ref.read(load.notifier).state = false;
      showMessage("Pin set successfully", context);
      Navigator.pop(context);
    }
    ref.read(load.notifier).state = false;
  }
}
