// lib/main.dart

import 'package:flutter/material.dart';
// Importa la pantalla de formulario que contiene todo
import 'screens/paciente_form_screen.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Triage Médico',
      // Configuración de Localización para Español
      localizationsDelegates: const [
        // Se pueden añadir más delegados si es necesario
      ],
      supportedLocales: const [
        Locale('en', 'US'), 
        Locale('es', 'ES'), 
      ],
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      
      // La pantalla de formulario es la inicial
      home: const PacienteFormScreen(), 
    );
  }
}