import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/providers.dart';
import 'routers/routers.dart';
import 'utils/apptheme.dart';
import 'utils/hive_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const SystemUiOverlayStyle(statusBarIconBrightness: Brightness.light);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  await loadHive();
  runApp(const ProviderScope(child: MyApp()));
}

final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, child) {
      final initialRoute = ref.watch(initialRouteProvider);

      return MaterialApp(
        title: 'Humanec Eye',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.themeData,
      
        routes: Routers.routers,
        initialRoute: initialRoute,
        navigatorKey: navigatorKey,
      );
    });
  }
}
