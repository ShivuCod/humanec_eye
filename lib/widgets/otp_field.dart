import 'package:flutter/material.dart';

import '../utils/apptheme.dart';

class OTPTextField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const OTPTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 50,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: 1,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        cursorHeight: 30,
        cursorColor: AppColor.black,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 24, fontWeight: FontWeight.bold, color: AppColor.grey),
        decoration: InputDecoration(
          counter: const SizedBox.shrink(),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColor.black, width: 2),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: AppColor.black.withOpacity(0.6), width: 1),
          ),
          errorBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: Colors.red.withOpacity(0.6), width: 1),
          ),
          disabledBorder: UnderlineInputBorder(
            borderSide:
                BorderSide(color: AppColor.black.withOpacity(0.3), width: 1),
          ),
        ),
      ),
    );
  }
}
