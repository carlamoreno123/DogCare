
import 'package:dogcare/entities/perro.dart';
import 'package:dogcare/views/Dashboard.dart';
import 'package:flutter/material.dart';
import 'package:dogcare/views/Perros.dart';
import 'package:dogcare/views/FichaPerro.dart';
import 'package:dogcare/views/Consultas.dart';

  void main() {
  runApp(const MainApp());
  }


class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App',
      initialRoute: '/',
      routes: {
        '/': (context) => const Dashboard (),
        '/perros': (context) => const PerrosScreen(),
        '/ficha_perro': (context) => FichaPerro(perro: ModalRoute.of(context)!.settings.arguments as Perro),
        '/consultas': (context) => const ConsultasVeterinariasScreen(),
        
      },
    );
  }
}