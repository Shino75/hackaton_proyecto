// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import '../services/auth_service.dart'; 
import '../models/user_model.dart'; 

import 'paciente_form_screen.dart'; 
import 'doctor_search_screen.dart'; 
import 'home_screen.dart'; // <--- Usamos HomeScreen como fallback

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ingresa correo y contraseña")));
      return;
    }

    setState(() => _isLoading = true);

    User? user = await _authService.login(
      _emailController.text.trim(), 
      _passController.text.trim()
    );

    setState(() => _isLoading = false);

    if (user != null && mounted) {
      if (user.rol == 'enfermera') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PacienteFormScreen()));
      } 
      else if (user.rol == 'doctor') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DoctorSearchScreen()));
      } 
      else {
        // Redirigimos a HomeScreen si es admin o desconocido
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminManagementScreen()));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Credenciales incorrectas"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.local_hospital, size: 90, color: Colors.indigo),
              const SizedBox(height: 20),
              const Text("Acceso Seguro", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 40),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: "Correo", prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
              const SizedBox(height: 20),
              TextField(controller: _passController, obscureText: true, decoration: const InputDecoration(labelText: "Contraseña", prefixIcon: Icon(Icons.lock), border: OutlineInputBorder())),
              const SizedBox(height: 30),
              _isLoading 
                ? const CircularProgressIndicator()
                : SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _handleLogin, style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white), child: const Text("INGRESAR", style: TextStyle(fontSize: 18)))),
            ],
          ),
        ),
      ),
    );
  }
}