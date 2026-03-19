import 'package:flutter/material.dart';
import 'package:my_profkom/models/student.dart';
import 'package:my_profkom/screens/discounts_screen.dart';
import 'package:my_profkom/screens/login_screen.dart';
import 'package:my_profkom/screens/register_screen.dart';
import 'package:my_profkom/screens/set_password_screen.dart';
import 'package:my_profkom/screens/waiting_screen.dart';
import 'package:my_profkom/utils/app_routes.dart';
import 'package:my_profkom/utils/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MY_PROFROM',
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.setPassword: (_) => const SetPasswordScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.waiting) {
          final student = settings.arguments as Student?;
          if (student == null) return null;
          return MaterialPageRoute(
            builder: (_) => WaitingScreen(student: student),
          );
        }

        if (settings.name == AppRoutes.discounts) {
          final student = settings.arguments as Student?;
          if (student == null) return null;
          return MaterialPageRoute(
            builder: (_) => DiscountsScreen(student: student),
          );
        }

        return null;
      },
    );
  }
}
