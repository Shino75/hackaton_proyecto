// lib/screens/doctor_ticket_screen.dart

import 'package:flutter/material.dart';

class DoctorTicketScreen extends StatelessWidget {
  // La propiedad final que almacena el mensaje del ticket
  final String ticketMessage;

  const DoctorTicketScreen({super.key, required this.ticketMessage});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍⚕️ Ticket para Revisión Médica'),
        backgroundColor: Colors.teal,
        // Oculta el botón de retroceso automático para forzar el uso del botón 'Marcar como Revisado'
        automaticallyImplyLeading: false, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              '⚠️ INFORMACIÓN RECIBIDA PARA REVISIÓN ⚠️',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const Divider(height: 20, thickness: 1),
            
            // Muestra el ticket. SelectableText permite copiar el contenido.
            SelectableText(
              ticketMessage, 
              style: const TextStyle(
                fontFamily: 'monospace', // Ideal para el formato de ticket
                fontSize: 15,
                height: 1.5,
              ),
            ),
            
            const Divider(height: 40, thickness: 1),
            
            // Botón para que el doctor regrese a la pantalla de la enfermera
            ElevatedButton.icon(
              onPressed: () {
                // Navega de vuelta a la pantalla anterior (el formulario)
                Navigator.pop(context); 
              },
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Marcar como Revisado y Volver'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}