import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../utils/apptheme.dart';
import '../utils/hive_config.dart';
import '../widgets/set_pin_dialog.dart';
import 'login.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  static const String routerName = '/profile';

  final List<String> _profileItems = const [
    'Terms & Conditions',
    'Privacy Policy',
    'Delete Account',
    'Set PIN',
    'Logout'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile'),
        forceMaterialTransparency: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        children: [
          Row(children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: Colors.grey.withOpacity(0.3),
              child: Icon(
                Icons.person_outline_rounded,
                size: 50,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(
              width: 20,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  HiveUser.getName(),
                  style: const TextStyle(fontSize: 18),
                ),
                Text(
                  HiveUser.getUserName(),
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 45),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _profileItems.length,
                itemBuilder: (c, i) {
                  return InkWell(
                    onTap: () => _itemSelection(context, i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            _profileItems[i],
                            style: const TextStyle(fontSize: 16),
                          ),
                          const Spacer(),
                          const Icon(Icons.chevron_right_outlined),
                        ],
                      ),
                    ),
                  );
                },
                separatorBuilder: (c, i) {
                  return const Divider(
                    thickness: 1,
                  );
                }),
          ),
        ],
      ),
    );
  }

  _itemSelection(BuildContext context, int i) async {
    switch (i) {
      case 0:
        if (!await launchUrl(Uri.parse('https://humanec.ai/'))) {
          throw Exception('Could not launch the url');
        }
        break;
      case 1:
        if (!await launchUrl(Uri.parse('https://humanec.ai/'))) {
          throw Exception('Could not launch the url');
        }
        break;
      case 2:
        showDialog(
            context: context,
            builder: (c) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                      'Are you sure you want to delete your account? This action cannot be undone.'),
                  actions: [
                    TextButton(
                      style:
                          TextButton.styleFrom(foregroundColor: AppColor.black),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                        side: const BorderSide(color: AppColor.black),
                        borderRadius: BorderRadius.circular(10),
                      )),
                      onPressed: () {
                        HiveUser.clearUserBox();
                        Navigator.pushReplacementNamed(
                            context, LoginPage.routerName);
                      },
                      child: const Text('Delete'),
                    ),
                  ],
                ));
        break;
      case 3:
        showDialog(
            context: context,
            builder: (c) => const Dialog(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: SetPinDialog(),
                  ),
                ));
        break;
      case 4:
        HiveUser.clearUserBox();
        HiveUser.clearCache();
        Navigator.pushReplacementNamed(context, LoginPage.routerName);
        break;
    }
  }
}

class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
