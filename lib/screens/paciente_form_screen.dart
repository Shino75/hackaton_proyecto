// lib/screens/paciente_form_screen.dart

import 'package:flutter/material.dart';
import '../services/mock_database.dart'; // Importamos la DB

class PacienteFormScreen extends StatefulWidget {
  const PacienteFormScreen({super.key});

  @override
  State<PacienteFormScreen> createState() => _PacienteFormScreenState();
}

class _PacienteFormScreenState extends State<PacienteFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- VARIABLES DE DATOS ---
  String _nombre = '';
  String _apellidoPaterno = '';
  DateTime? _fechaNacimiento;
  String? _generoSeleccionado;
  final List<String> _generos = ['M', 'F']; 
  String _curp = '';
  String _telefono = '';
  String _direccion = '';

  String _motivoConsulta = '';
  String _frecuenciaCardiaca = ''; 
  String _frecuenciaRespiratoria = ''; 
  String _temperatura = ''; 
  String _saturacionOxigeno = ''; 
  String _peso = '';
  String _talla = '';

  final TextEditingController _fechaController = TextEditingController();

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

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      // 1. Crear el objeto de datos
      Map<String, dynamic> nuevoRegistro = {
        'curp': _curp, // CLAVE PRINCIPAL
        'nombre': '$_nombre $_apellidoPaterno',
        'edad': (DateTime.now().year - _fechaNacimiento!.year).toString(),
        'genero': _generoSeleccionado,
        'fecha_nacimiento': _fechaController.text,
        'telefono': _telefono,
        'direccion': _direccion,
        'motivo': _motivoConsulta,
        'signos': 'FC: $_frecuenciaCardiaca | FR: $_frecuenciaRespiratoria | T: $_temperatura | SpO2: $_saturacionOxigeno | Peso: $_peso | Talla: $_talla'
      };

      // 2. Guardar en Base de Datos Simulada
      MockDatabase.guardarPaciente(nuevoRegistro);
      
      // 3. Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Paciente $_nombre registrado. Datos guardados.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
      
      // 4. Limpiar Formulario
      _formKey.currentState?.reset();
      _fechaController.clear();
      setState(() {
        _fechaNacimiento = null;
        _generoSeleccionado = null;
      });
      
      // Subir scroll al inicio
      Scrollable.ensureVisible(_formKey.currentContext!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏥 Triage Enfermería'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Datos del Paciente',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 10),
              
              // NOMBRE Y APELLIDO
              Row(
                children: [
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                    onSaved: (v) => _nombre = v!,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder()),
                    onSaved: (v) => _apellidoPaterno = v!,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                  )),
                ],
              ),
              const SizedBox(height: 10),
              
              // FECHA Y GENERO
              Row(
                children: [
                   Expanded(
                    child: TextFormField(
                      controller: _fechaController,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'Fecha Nac.', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                      onTap: () => _selectDate(context),
                      validator: (v) => _fechaNacimiento == null ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Género', border: OutlineInputBorder()),
                      value: _generoSeleccionado,
                      items: _generos.map((g) => DropdownMenuItem(value: g, child: Text(g == 'M' ? 'Masculino' : 'Femenino'))).toList(),
                      onChanged: (v) => setState(() => _generoSeleccionado = v),
                      validator: (v) => v == null ? 'Requerido' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // CURP
              TextFormField(
                decoration: const InputDecoration(labelText: 'CURP', border: OutlineInputBorder(), prefixIcon: Icon(Icons.badge)),
                textCapitalization: TextCapitalization.characters,
                maxLength: 18,
                onSaved: (v) => _curp = v!,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),

              // CONTACTO
              TextFormField(
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
                onSaved: (v) => _telefono = v!,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder(), prefixIcon: Icon(Icons.home)),
                maxLines: 2,
                onSaved: (v) => _direccion = v!,
              ),
              
              const SizedBox(height: 25),
              const Divider(thickness: 2),
              
              const Text(
                'Signos Vitales y Motivo',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
              ),
              const SizedBox(height: 10),

              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Motivo de Ingreso', 
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services)
                ),
                maxLines: 2,
                onSaved: (v) => _motivoConsulta = v!,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              
              const SizedBox(height: 15),
              
              // SIGNOS VITALES (FILAS DE 3)
              Row(
                children: [
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(labelText: 'F.C. (lpm)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _frecuenciaCardiaca = v!,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Temp (°C)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _temperatura = v!,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(labelText: 'SpO2 (%)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _saturacionOxigeno = v!,
                  )),
                ],
              ),
              const SizedBox(height: 10),
               Row(
                children: [
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(labelText: 'F.R. (rpm)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _frecuenciaRespiratoria = v!,
                  )),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Peso (kg)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _peso = v!,
                  )),
                   const SizedBox(width: 10),
                  Expanded(child: TextFormField(
                    decoration: const InputDecoration(labelText: 'Talla (cm)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _talla = v!,
                  )),
                ],
              ),

              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _submitForm,
                icon: const Icon(Icons.save),
                label: const Text('GUARDAR Y LIBERAR'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}