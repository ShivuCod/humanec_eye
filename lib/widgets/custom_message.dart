import 'package:flutter/material.dart';

import '../utils/apptheme.dart';

showMessage(String message, BuildContext context, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(0),
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
            decoration: BoxDecoration(
              color: isError
                  ? AppColor.red.withValues(alpha: 0.6)
                  : AppColor.green.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
            child: Center(
              child: isError
                  ? const Icon(
                      Icons.error,
                      color: AppColor.white,
                      size: 20,
                    )
                  : const Icon(
                      Icons.check,
                      color: AppColor.white,
                      size: 20,
                    ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
              child: Text(
            message,
            style: const TextStyle(
              color: AppColor.black,
              fontSize: 14,
            ),
          )),
        ],
      ),
    ),
  );
}
