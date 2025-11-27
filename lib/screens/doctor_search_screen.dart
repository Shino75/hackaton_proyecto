// lib/screens/doctor_search_screen.dart

import 'package:flutter/material.dart';
import '../services/mock_database.dart';
import 'doctor_ticket_screen.dart';

class DoctorSearchScreen extends StatefulWidget {
  const DoctorSearchScreen({super.key});

  @override
  State<DoctorSearchScreen> createState() => _DoctorSearchScreenState();
}

class _DoctorSearchScreenState extends State<DoctorSearchScreen> {
  final _curpController = TextEditingController();
  String _errorText = '';

  void _buscarPaciente() {
    final curpInput = _curpController.text.trim();

    if (curpInput.isEmpty) {
      setState(() => _errorText = 'Por favor ingresa una CURP');
      return;
    }

    // Buscamos en la BD simulada
    final pacienteEncontrado = MockDatabase.buscarPorCurp(curpInput);

    if (pacienteEncontrado != null) {
      setState(() => _errorText = '');
      
      // Si encuentra, vamos al ticket
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctorTicketScreen(pacienteData: pacienteEncontrado),
        ),
      );
    } else {
      setState(() => _errorText = 'No se encontró paciente con CURP: $curpInput');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Búsqueda de Expediente'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_shared, size: 80, color: Colors.teal),
            const SizedBox(height: 20),
            const Text(
              'Ingreso Médico',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ingresa la CURP registrada por enfermería para abrir el episodio.',
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
                prefixIcon: const Icon(Icons.search),
                errorText: _errorText.isEmpty ? null : _errorText,
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _buscarPaciente,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('BUSCAR Y ABRIR'),
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
    );
  }
}