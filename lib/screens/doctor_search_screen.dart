// lib/screens/doctor_search_screen.dart

import 'package:flutter/material.dart';
import '../services/hospital_repository.dart'; 
import 'doctor_ticket_screen.dart'; 
import 'login_screen.dart'; 

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final _curpController = TextEditingController();
  final _repository = HospitalRepository();
  
  String _errorText = '';
  bool _isLoading = false;

  void _buscarPaciente() async {
    final curpInput = _curpController.text.trim();

    if (curpInput.isEmpty) {
      setState(() => _errorText = 'Por favor ingresa una CURP');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorText = '';
    });

    try {
      final pacienteEncontrado = await _repository.buscarPorCurp(curpInput);

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (pacienteEncontrado != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorTicketScreen(pacienteData: pacienteEncontrado),
            ),
          );
        } else {
          setState(() => _errorText = 'No se encontró paciente con esa CURP en la Base de Datos.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = 'Error de conexión: $e';
        });
      }
    }
  }

  void _cerrarSesion() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda de Pacientes'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Oculta flecha atrás
      ),
      body: SingleChildScrollView( // Scroll para evitar overflow en pantallas chicas
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              // --- BOTÓN DE SALIR (ARRIBA) ---
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: const Text(
                    'Cerrar Sesión', 
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    backgroundColor: Colors.red.withOpacity(0.1),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // --- CONTENIDO ORIGINAL CENTRADO ---
              const Icon(Icons.person_search, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              const Text(
                'Consulta Médica',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Ingresa la CURP para buscar el expediente en la base de datos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              
              TextField(
                controller: _curpController,
                decoration: InputDecoration(
                  labelText: 'CURP del Paciente',
                  hintText: 'Ej. ABCD...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.badge),
                  errorText: _errorText.isEmpty ? null : _errorText,
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _buscarPaciente,
                  icon: const Icon(Icons.search),
                  label: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('BUSCAR EXPEDIENTE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}