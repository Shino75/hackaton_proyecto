import 'package:flutter/material.dart';
import '../services/auth_service.dart'; // Tu servicio de conexión
import '../models/user_model.dart';     // Tu modelo de usuario

// Importamos las pantallas que YA existen en el proyecto
import 'paciente_form_screen.dart';     // Para Enfermería
import 'doctor_search_screen.dart';     // Para Doctor (Búsqueda)
import 'home_screen.dart';              // Para Admin (O por defecto)

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

    // Verificamos credenciales en tu BD real
    User? user = await _authService.login(
      _emailController.text.trim(), 
      _passController.text.trim()
    );

    setState(() => _isLoading = false);

    if (user != null && mounted) {
      // --- TU TRABAJO TERMINA AQUÍ: REDIRIGIR ---
      
      if (user.rol == 'enfermera') {
        // Redirige a la pantalla de Enfermería que ya tienen
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const PacienteFormScreen())
        );
      } 
      else if (user.rol == 'doctor') {
        // Redirige a la pantalla de Búsqueda del Doctor que ya tienen
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const DoctorSearchScreen())
        );
      } 
      else {
        // Si es Admin u otro, lo mandamos al menú general
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const HomeScreen())
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Credenciales incorrectas"), 
            backgroundColor: Colors.red
          ),
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
              const SizedBox(height: 10),
              const Text("Sistema Hospitalario TESI"),
              const SizedBox(height: 40),
              
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Correo Electrónico",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              
              TextField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Contraseña",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),

              _isLoading 
                ? const CircularProgressIndicator()
                : SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text("INGRESAR", style: TextStyle(fontSize: 18)),
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}