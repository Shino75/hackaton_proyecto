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
  final _repository = HospitalRepository(); // Instancia correcta
  
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
      // Usamos la nueva función del repositorio
      final pacienteData = await _repository.buscarExpedienteCompleto(curpInput);

      if (mounted) {
        setState(() => _isLoading = false);
        
        if (pacienteData != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DoctorTicketScreen(pacienteData: pacienteData),
            ),
          );
        } else {
          setState(() => _errorText = 'No encontrado. Verifique que Enfermería lo haya registrado.');
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
        automaticallyImplyLeading: false,
        actions: [
          IconButton(onPressed: _cerrarSesion, icon: const Icon(Icons.logout))
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.person_search, size: 80, color: Colors.teal),
              const SizedBox(height: 20),
              const Text('Consulta Médica', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),
              TextField(
                controller: _curpController,
                decoration: InputDecoration(
                  labelText: 'CURP del Paciente',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.badge),
                  errorText: _errorText.isEmpty ? null : _errorText,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _buscarPaciente,
                  icon: const Icon(Icons.search),
                  label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('BUSCAR EXPEDIENTE'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}