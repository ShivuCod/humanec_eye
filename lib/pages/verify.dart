import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:humanec_eye/utils/apptheme.dart';

import '../services/services.dart';
import '../utils/custom_buttom.dart';
import '../widgets/custom_message.dart';
import '../widgets/otp_field.dart';
import 'bussiness_option.dart';
import 'login.dart';

class VerifyPage extends ConsumerStatefulWidget {
  static const routeName = '/verify';
  const VerifyPage({super.key, this.phoneNumber, this.isPin = false});
  final String? phoneNumber;
  final bool isPin;
  static const routerName = '/verify';
  @override
  ConsumerState<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends ConsumerState<VerifyPage> {
  final resendTimerProvider = StateProvider<int>((ref) => 30);
  final otlLoader = StateProvider<bool>((ref) => false);
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  Timer? _timer;

  @override
  void initState() {
    if (!widget.isPin) {
      _startResendTimer();
    }
    super.initState();
  }

  void _startResendTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final currentTime = ref.read(resendTimerProvider);
      if (currentTime > 0) {
        ref.read(resendTimerProvider.notifier).state = currentTime - 1;
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendOtp() async {
    ref.read(otlLoader.notifier).state = true;
    if (await Services.sendWithOTP(widget.phoneNumber!)) {
      showMessage("OTP Resent successfully", context);
      ref.read(resendTimerProvider.notifier).state = 60;
      _startResendTimer();
    }
    ref.read(otlLoader.notifier).state = false;
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resendTimer = ref.watch(resendTimerProvider);
    final loader = ref.watch(otlLoader);
    final size = MediaQuery.sizeOf(context).width;
    return Scaffold(
      backgroundColor: AppColor.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, LoginPage.routerName);
                },
                icon: const Icon(Icons.arrow_back_ios, color: AppColor.black),
              ),
              const SizedBox(
                height: 10,
              ),
              Text(
                "Enter the ${widget.isPin ? "PIN for" : "OTP sent to"}  \n+ 91 ${widget.phoneNumber}",
                style: const TextStyle(
                    color: AppColor.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
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
              const SizedBox(height: 10),
              if (!widget.isPin)
                resendTimer > 0
                    ? Text(
                        'Resend OTP in $resendTimer seconds',
                        style:
                            TextStyle(fontSize: size > 1000 ? size * 0.02 : 15),
                      )
                    : TextButton(
                        onPressed: loader ? null : _resendOtp,
                        child: Text.rich(TextSpan(
                            text: "I didn't get OTP | ",
                            style: TextStyle(
                                color: Colors.grey,
                                fontSize: size > 1000 ? size * 0.02 : 20),
                            children: const [
                              TextSpan(
                                  text: "Resend",
                                  style: TextStyle(
                                      color: AppColor.black,
                                      fontStyle: FontStyle.italic,
                                      fontWeight: FontWeight.w500)),
                            ])),
                      ),
              if (widget.isPin)
                InkWell(
                  child: const Row(
                    children: [
                      Text("Not Remembered PIN?"),
                      SizedBox(width: 8),
                      Text(
                        "By OTP Login",
                        style: TextStyle(
                            color: AppColor.grey, fontWeight: FontWeight.bold),
                      )
                    ],
                  ),
                  onTap: () {
                    _resendOtp();
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => VerifyPage(
                                  phoneNumber: widget.phoneNumber,
                                  isPin: false,
                                )));
                  },
                ),
              const Spacer(),
              Text(
                "By signing up, you agree to our Terms of Service and Privacy Policy",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppColor.black.withOpacity(0.8)),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: CustomButton(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (loader)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColor.white,
                          ),
                        ),
                      if (loader) const SizedBox(width: 10),
                      Text(loader ? "Loading..." : "Login"),
                    ],
                  ),
                  onPressed: loader
                      ? null
                      : () {
                          debugPrint("controllers ${_controllers.join("")}");
                          _handleOtpSubmission(
                            _controllers.map((e) => e.text).join(""),
                          );
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleOtpSubmission(String value) async {
    ref.read(otlLoader.notifier).state = true;

    if (value.isNotEmpty) {
      final auth = await Services.getLogin(
        username: widget.phoneNumber!,
        password: value,
      );

      if (auth != null && context.mounted) {
        if (mounted) {
          Navigator.pushReplacementNamed(
            context,
            BusinessOptionPage.routerName,
          );
        }

        ref.read(otlLoader.notifier).state = false;

        return;
      } else {
        showMessage("You Entered Wrong OTP", context, isError: true);
      }
    }

    ref.read(otlLoader.notifier).state = false;
  }
}
