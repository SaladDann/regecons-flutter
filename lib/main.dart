import 'package:flutter/material.dart';
import 'package:regcons/screens/gestion_obras/obras_screen.dart';
import 'package:regcons/screens/home_page.dart';
import 'package:regcons/screens/auth/login_page.dart';
import 'package:regcons/screens/auth/registro_form_page.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RegCons',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.orange,
        scaffoldBackgroundColor: const Color(0xFF10121D),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegistroFormPage(),
        '/home': (context) => const HomePage(nombreUsuario: 'Usuario'),
        '/obras': (context) => const ObrasScreen(),

      },
    );
  }
}
