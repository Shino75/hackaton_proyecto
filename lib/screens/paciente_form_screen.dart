// lib/screens/paciente_form_screen.dart

import 'package:flutter/material.dart';
// Importa la vista del doctor para poder navegar
import 'doctor_ticket_screen.dart'; 

class PacienteFormScreen extends StatefulWidget {
  const PacienteFormScreen({super.key});

  @override
  State<PacienteFormScreen> createState() => _PacienteFormScreenState();
}

class _PacienteFormScreenState extends State<PacienteFormScreen> {
  // Clave global para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // --- VARIABLES DE DATOS DEL PACIENTE ---
  String _nombre = '';
  String _apellidoPaterno = '';
  DateTime? _fechaNacimiento;
  String? _generoSeleccionado;
  final List<String> _generos = ['M', 'F', 'O']; 
  String _curp = '';
  String _telefono = '';
  String _direccion = '';

  // --- VARIABLES DE LA CONSULTA/SIGNOS VITALES ---
  String _motivoConsulta = '';
  String _frecuenciaCardiaca = ''; 
  String _frecuenciaRespiratoria = ''; 
  String _temperatura = ''; 
  String _saturacionOxigeno = ''; 
  String _peso = '';
  String _talla = '';

  // Controlador para el campo de texto de la fecha
  final TextEditingController _fechaController = TextEditingController();

  // Función para seleccionar la fecha con un calendario
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _fechaNacimiento) {
      setState(() {
        _fechaNacimiento = picked;
        _fechaController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  // Lógica principal: Validar, Generar el Ticket y NAVEGAR
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // Mapear el código de género a un texto legible
      String generoTexto = '';
      if (_generoSeleccionado == 'M') {
        generoTexto = 'Masculino';
      } else if (_generoSeleccionado == 'F') {
        generoTexto = 'Femenino';
      } else {
        generoTexto = 'Otro';
      }

      // 2. Crear la cadena de texto con formato de "Ticket"
      final String mensajeTicket = '''
========================================
     TICKET DE REGISTRO Y CONSULTA
========================================
Hora de Envío: ${DateTime.now().hour}:${DateTime.now().minute}
Fecha de Envío: ${DateTime.now().toLocal().toString().split(' ')[0]}

----------------------------------------

DATOS DE IDENTIFICACIÓN:
- Nombre: $_nombre
- Apellido Paterno: $_apellidoPaterno
- Fecha Nacimiento: ${_fechaController.text}
- Género: $generoTexto
- CURP: $_curp

CONTACTO Y UBICACIÓN:
- Teléfono: $_telefono
- Dirección: $_direccion

----------------------------------------

ATENCIÓN DE CONSULTA:
- Motivo: $_motivoConsulta

SIGNOS VITALES:
- Frecuencia Cardiaca (F. C.): $_frecuenciaCardiaca lpm
- Frecuencia Respiratoria (F. R.): $_frecuenciaRespiratoria rpm
- Temperatura (Tº): $_temperatura °C
- Saturación O₂ (SpO₂): $_saturacionOxigeno %
- Peso: $_peso kg
- Talla: $_talla cm

----------------------------------------
El doctor puede revisar la información a continuación.
========================================
''';

      // 3. NAVEGAR a la pantalla del Doctor, pasando el ticket como argumento
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => DoctorTicketScreen(
            ticketMessage: mensajeTicket,
          ),
        ),
      );
      
      // Opcional: Mostrar un SnackBar de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket de $_nombre enviado a la bandeja del Doctor.')),
      );
      
      // Opcional: Reiniciar el formulario después de la navegación
      _formKey.currentState?.reset();
      _fechaController.clear();
      setState(() {
        _fechaNacimiento = null;
        _generoSeleccionado = null;
      });
    }
  }

  @override
  void dispose() {
    _fechaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Ingreso de Paciente y Signos Vitales'),
        backgroundColor: Colors.indigo,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- SECCIÓN: DATOS DEL PACIENTE ---
              const Text(
                'Datos Básicos del Paciente',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 15),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre(s)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa el nombre.' : null,
                onSaved: (value) => _nombre = value!,
              ),
              const SizedBox(height: 15),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Apellido Paterno', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa el apellido paterno.' : null,
                onSaved: (value) => _apellidoPaterno = value!,
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: _fechaController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Fecha de Nacimiento', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                onTap: () => _selectDate(context),
                validator: (value) => (_fechaNacimiento == null) ? 'Selecciona la fecha.' : null,
              ),
              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Género', border: OutlineInputBorder(), prefixIcon: Icon(Icons.transgender)),
                value: _generoSeleccionado,
                hint: const Text('Seleccionar'),
                items: _generos.map((String genero) {
                  return DropdownMenuItem<String>(
                    value: genero,
                    child: Text(genero == 'M' ? 'Masculino' : (genero == 'F' ? 'Femenino' : 'Otro')),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() => _generoSeleccionado = newValue);
                },
                validator: (value) => (value == null || value.isEmpty) ? 'Selecciona el género.' : null,
                onSaved: (value) => _generoSeleccionado = value,
              ),
              const SizedBox(height: 15),

              TextFormField(
                decoration: const InputDecoration(labelText: 'CURP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                maxLength: 18,
                validator: (value) => (value == null || value.length != 18) ? 'La CURP debe tener 18 caracteres.' : null,
                onSaved: (value) => _curp = value!,
              ),
              const SizedBox(height: 15),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Teléfono de Contacto', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa el teléfono.' : null,
                onSaved: (value) => _telefono = value!,
              ),
              const SizedBox(height: 15),

              TextFormField(
                decoration: const InputDecoration(labelText: 'Dirección Completa', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
                maxLines: 3,
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa la dirección.' : null,
                onSaved: (value) => _direccion = value!,
              ),
              
              const SizedBox(height: 30),
              
              // --- SECCIÓN: MOTIVO Y VITALES ---
              const Divider(height: 40, thickness: 2),
              
              const Text(
                'Datos de la Consulta y Signos Vitales',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 20),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Motivo de Consulta',
                  hintText: 'Ej: Dolor abdominal, fiebre, revisión de rutina.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sick),
                ),
                maxLines: 3,
                validator: (value) => (value == null || value.isEmpty) ? 'El motivo de consulta es obligatorio.' : null,
                onSaved: (value) => _motivoConsulta = value!,
              ),
              const SizedBox(height: 25),

              // Fila 1 de Vitales
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'F. C. (lpm)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || value.isEmpty) ? 'Requerido.' : null,
                      onSaved: (value) => _frecuenciaCardiaca = value!,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'F. R. (rpm)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || value.isEmpty) ? 'Requerido.' : null,
                      onSaved: (value) => _frecuenciaRespiratoria = value!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              
              // Fila 2 de Vitales
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Tº (°C)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => (value == null || value.isEmpty) ? 'Requerido.' : null,
                      onSaved: (value) => _temperatura = value!,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'SpO₂ (%)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || value.isEmpty) ? 'Requerido.' : null,
                      onSaved: (value) => _saturacionOxigeno = value!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Fila 3 de Vitales
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder()),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) => (value == null || value.isEmpty) ? 'Requerido.' : null,
                      onSaved: (value) => _peso = value!,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Talla (cm)', border: OutlineInputBorder()),
                      keyboardType: TextInputType.number,
                      validator: (value) => (value == null || value.isEmpty) ? 'Requerido.' : null,
                      onSaved: (value) => _talla = value!,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // --- BOTÓN DE ENVIAR TICKET AL DOCTOR ---
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.send),
                label: const Text(
                  'Enviar Ticket al Doctor',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}