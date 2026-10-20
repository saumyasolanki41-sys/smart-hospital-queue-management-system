
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/queue_viewmodel.dart';
import 'viewmodels/department_viewmodel.dart';
import 'viewmodels/doctor_viewmodel.dart';
import 'viewmodels/token_viewmodel.dart';
import 'viewmodels/ambulance_viewmodel.dart';

import 'view/splash_screen.dart';
import 'view/login_screen.dart';
import 'view/signup_screen.dart';
import 'view/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HospitalQueueApp());
}

class HospitalQueueApp extends StatelessWidget {
  const HospitalQueueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => QueueViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => DepartmentViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => DoctorViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => TokenViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => AmbulanceViewModel(),
        ),
      ],
      child: MaterialApp(
        title: 'Smart Hospital Queue',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1479A4),
          ),
          scaffoldBackgroundColor: const Color(0xFFF3F8FB),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFD9E2EC),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF1479A4),
                width: 1.5,
              ),
            ),
          ),
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1479A4),
            brightness: Brightness.dark,
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }
}
