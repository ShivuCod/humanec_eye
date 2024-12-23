
import '../pages/bussiness_option.dart';
import '../pages/home.dart';
import '../pages/login.dart';
import '../pages/recognize.dart';
import '../pages/register.dart';
import '../pages/verify.dart';

class Routers {
  static final routers = {
    LoginPage.routerName: (context) => const LoginPage(),
    VerifyPage.routerName: (context) => const VerifyPage(),
    BusinessOptionPage.routerName: (context) => const BusinessOptionPage(),
    RecognizePage.routerName: (context) => const RecognizePage(),
    RegisterPage.routerName: (context) => const RegisterPage(),
    HomePage.routerName: (context) => HomePage(),

  };
}
