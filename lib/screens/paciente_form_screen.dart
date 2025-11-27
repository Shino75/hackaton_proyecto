// lib/screens/paciente_form_screen.dart

import 'package:flutter/material.dart';

// No necesitamos importar 'paciente.dart' ya que no creamos el objeto,
// pero si lo haces no hay problema.

class PacienteFormScreen extends StatefulWidget {
  const PacienteFormScreen({super.key});

  @override
  State<PacienteFormScreen> createState() => _PacienteFormScreenState();
}

class _PacienteFormScreenState extends State<PacienteFormScreen> {
  // Clave global para validar el formulario
  final _formKey = GlobalKey<FormState>();

  // Variables para almacenar los valores
  String _nombre = '';
  String _apellidoPaterno = '';
  DateTime? _fechaNacimiento;
  String? _generoSeleccionado;
  final List<String> _generos = ['M', 'F', 'O']; // Opciones: Masculino, Femenino, Otro
  String _curp = '';
  String _telefono = '';
  String _direccion = '';

  // Controlador para el campo de texto de la fecha
  final TextEditingController _fechaController = TextEditingController();

  // Función para seleccionar la fecha con un calendario
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'), // Para mostrar el calendario en español
    );
    if (picked != null && picked != _fechaNacimiento) {
      setState(() {
        _fechaNacimiento = picked;
        // Formatear la fecha para mostrarla
        _fechaController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  // Lógica principal: Validar y Generar el Ticket/Mensaje
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // 1. Mapear el código de género a un texto legible para el ticket
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
             TICKET DE REGISTRO DE PACIENTE
             (Pendiente de Ingreso a la BD)
        ========================================
        Hora de Registro: ${DateTime.now().hour}:${DateTime.now().minute}
        Fecha de Registro: ${DateTime.now().toLocal().toString().split(' ')[0]}
        
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
        ATENCIÓN: Doctor, revise y confirme el ingreso.
        ========================================
      ''';

      // 3. Mostrar el ticket en la consola (debug) y una alerta al usuario
      print(mensajeTicket);
      
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('✅ Ticket Generado'),
          content: Text('Los datos de $_nombre $_apellidoPaterno han sido listos para ser enviados al doctor.\n\nEl ticket completo se muestra en la consola.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Aceptar'),
              onPressed: () {
                Navigator.of(ctx).pop();
                // Opcional: Reiniciar el formulario después de generar el ticket
                _formKey.currentState?.reset();
                _fechaController.clear();
                setState(() {
                  _fechaNacimiento = null;
                  _generoSeleccionado = null;
                });
              },
            )
          ],
        ),
      );
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
        title: const Text('📋 Ingreso Básico de Paciente'),
        backgroundColor: Colors.indigo,
      ),
      // ScrollView es crucial para que el teclado no cause errores de desbordamiento
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- CAMPO: Nombre ---
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre(s)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person)),
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa el nombre.' : null,
                onSaved: (value) => _nombre = value!,
              ),
              const SizedBox(height: 15),

              // --- CAMPO: Apellido Paterno ---
              TextFormField(
                decoration: const InputDecoration(labelText: 'Apellido Paterno', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_outline)),
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa el apellido paterno.' : null,
                onSaved: (value) => _apellidoPaterno = value!,
              ),
              const SizedBox(height: 15),

              // --- CAMPO: Fecha de Nacimiento (con selector) ---
              TextFormField(
                controller: _fechaController,
                readOnly: true,
                decoration: const InputDecoration(labelText: 'Fecha de Nacimiento', border: OutlineInputBorder(), prefixIcon: Icon(Icons.calendar_today)),
                onTap: () => _selectDate(context),
                validator: (value) => (_fechaNacimiento == null) ? 'Selecciona la fecha.' : null,
              ),
              const SizedBox(height: 15),

              // --- CAMPO: Género (Dropdown) ---
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

              // --- CAMPO: CURP ---
              TextFormField(
                decoration: const InputDecoration(labelText: 'CURP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                maxLength: 18,
                validator: (value) => (value == null || value.length != 18) ? 'La CURP debe tener 18 caracteres.' : null,
                onSaved: (value) => _curp = value!,
              ),
              const SizedBox(height: 15),

              // --- CAMPO: Teléfono de Contacto ---
              TextFormField(
                decoration: const InputDecoration(labelText: 'Teléfono de Contacto', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa el teléfono.' : null,
                onSaved: (value) => _telefono = value!,
              ),
              const SizedBox(height: 15),

              // --- CAMPO: Dirección Completa ---
              TextFormField(
                decoration: const InputDecoration(labelText: 'Dirección Completa', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
                maxLines: 3,
                validator: (value) => (value == null || value.isEmpty) ? 'Ingresa la dirección.' : null,
                onSaved: (value) => _direccion = value!,
              ),
              const SizedBox(height: 30),
              
              // --- BOTÓN DE GENERAR TICKET ---
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.send),
                label: const Text(
                  'Generar y Enviar Ticket',
                  style: TextStyle(fontSize: 18),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
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