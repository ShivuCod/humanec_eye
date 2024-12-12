import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/services.dart';
import '../utils/apptheme.dart';
import '../utils/custom_buttom.dart';
import '../widgets/custom_message.dart';
import 'verify.dart';

class LoginPage extends StatefulWidget {
  static const routerName = '/login';

  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _globalKey = GlobalKey<FormState>();
  final TextEditingController _phoneController = TextEditingController();
  final loginLoadingProvider = StateProvider.autoDispose<bool>((ref) => false);
  final loginByPin = StateProvider.autoDispose<bool>((ref) => false);

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      body: Consumer(builder: (context, ref, child) {
        final pin = ref.watch(loginByPin);
        final loading = ref.watch(loginLoadingProvider);
        debugPrint('pin is $pin');
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 5),
            child: Form(
              key: _globalKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/2.png",
                    width: 200,
                    fit: BoxFit.fitWidth,
                  ),
                  const Text(
                    "Login with your mobile number",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.black,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const Text(
                    "Please enter a valid mobile number to access your humaneclite account",
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Phone Number",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextFormField(
                    scrollPadding: EdgeInsets.zero,
                    cursorColor: AppColor.black,
                    textAlignVertical: TextAlignVertical.center,
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    maxLength: 10,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                      hintText: "9832XXXXXX",
                      fillColor: Colors.grey.shade100,
                      filled: true,
                      border: AppTheme.outlineInputBorder,
                      focusedBorder: AppTheme.focusedOutlineInputBorder,
                      errorBorder: AppTheme.errorOutlineInputBorder,
                      focusedErrorBorder: AppTheme.focusedOutlineInputBorder,
                      counter: const SizedBox.shrink(),
                    ),
                    validator: (value) {
                      debugPrint('value is $value');
                      if (value!.isEmpty) {
                        return 'Mobile number cannot be empty';
                      } else if (!_isNumeric(value)) {
                        return "Please use only numbers";
                      } else if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                        return 'Enter a valid 10-digit mobile number';
                      }
                      return null;
                    },
                  ),
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    value: pin,
                    onChanged: (value) =>
                        ref.read(loginByPin.notifier).state = value!,
                    activeColor: Colors.black,
                    title: const Text("Login with PIN instead of OTP",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ),
                  CustomButton(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (loading)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: AppColor.white,
                            ),
                          ),
                        if (loading) const SizedBox(width: 10),
                        Text(loading ? "Loading..." : "Continue"),
                      ],
                    ),
                    onPressed: loading
                        ? null
                        : pin
                            ? () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VerifyPage(
                                      phoneNumber: _phoneController.text,
                                      isPin: true,
                                    ),
                                  ),
                                )
                            : () => _onPressed(context, ref),
                  )
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  bool _isNumeric(String? str) {
    if (str == null) {
      return false;
    }
    return double.tryParse(str) != null;
  }

  _onPressed(BuildContext context, WidgetRef ref) async {
    if (_globalKey.currentState!.validate()) {
      ref.read(loginLoadingProvider.notifier).state = true;

      final value = await Services.sendWithOTP(_phoneController.text);

      if (value && context.mounted) {
        Navigator.of(context).pushReplacementNamed(
          VerifyPage.routerName,
          arguments: VerifyPage(
            phoneNumber: _phoneController.text,
          ),
        );

        ref.read(loginLoadingProvider.notifier).state = false;

        return;
      }

      showMessage("User Not Found", context, isError: true);

      ref.read(loginLoadingProvider.notifier).state = false;
    }
  }
}
