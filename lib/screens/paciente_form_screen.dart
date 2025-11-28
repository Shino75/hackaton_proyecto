// lib/screens/paciente_form_screen.dart

import 'package:flutter/material.dart';
import '../services/hospital_repository.dart'; 
import 'login_screen.dart'; 

class PacienteFormScreen extends StatefulWidget {
  const PacienteFormScreen({super.key});

  @override
  State<PacienteFormScreen> createState() => _PacienteFormScreenState();
}

class _PacienteFormScreenState extends State<PacienteFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repository = HospitalRepository(); 

  // Variables del formulario
  String _nombre = '';
  String _apellidoPaterno = '';
  DateTime? _fechaNacimiento;
  String? _generoSeleccionado;
  final List<String> _generos = ['M', 'F']; 
  String _curp = '';
  String _telefono = '';
  String _direccion = '';
  
  // Variables Signos
  String _motivoConsulta = '';
  String _frecuenciaCardiaca = ''; 
  String _frecuenciaRespiratoria = ''; 
  String _temperatura = ''; 
  String _saturacionOxigeno = ''; 
  String _peso = '';
  String _talla = '';

  final TextEditingController _fechaController = TextEditingController();
  bool _isLoading = false; 

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
        _fechaController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true); 

      try {
        await _repository.registrarIngreso({
          'nombre': _nombre,
          'apellido': _apellidoPaterno,
          'fecha_nacimiento': _fechaController.text, 
          'genero': _generoSeleccionado,
          'curp': _curp,
          'telefono': _telefono,
          'direccion': _direccion,
          'motivo': _motivoConsulta,
          'fc': _frecuenciaCardiaca,
          'temp': _temperatura,
          'spo2': _saturacionOxigeno,
          'peso': _peso,
          'talla': _talla,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Paciente $_nombre guardado en Base de Datos'), backgroundColor: Colors.green),
          );
          _formKey.currentState?.reset();
          _fechaController.clear();
          setState(() {
            _fechaNacimiento = null;
            _generoSeleccionado = null;
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error al guardar: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Enfermería - Registro'), 
        backgroundColor: Colors.indigo, 
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Oculta la flecha de atrás automática
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              // --- BOTÓN DE SALIR (MUY VISIBLE) ---
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout),
                  label: const Text('CERRAR SESIÓN Y SALIR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100, // Fondo rojo claro
                    foregroundColor: Colors.red.shade900, // Texto rojo oscuro
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),

              // Campos Datos Personales
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                onSaved: (v) => _nombre = v!,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder()),
                onSaved: (v) => _apellidoPaterno = v!,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _fechaController,
                decoration: const InputDecoration(labelText: 'Fecha Nacimiento', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Género', border: OutlineInputBorder()),
                value: _generoSeleccionado,
                items: _generos.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                onChanged: (v) => setState(() => _generoSeleccionado = v),
                validator: (v) => v == null ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'CURP', border: OutlineInputBorder()),
                onSaved: (v) => _curp = v!,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
                onSaved: (v) => _telefono = v!,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder()),
                onSaved: (v) => _direccion = v!,
              ),
              
              const Divider(height: 30, thickness: 2),
              const Text('Signos Vitales y Triage', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              
              TextFormField(
                decoration: const InputDecoration(labelText: 'Motivo de Consulta', border: OutlineInputBorder()),
                maxLines: 2,
                onSaved: (v) => _motivoConsulta = v!,
                validator: (v) => v!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'FC (lpm)'), keyboardType: TextInputType.number, onSaved: (v) => _frecuenciaCardiaca = v!)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'FR (rpm)'), keyboardType: TextInputType.number, onSaved: (v) => _frecuenciaRespiratoria = v!)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Temp (°C)'), keyboardType: TextInputType.number, onSaved: (v) => _temperatura = v!)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'SpO2 (%)'), keyboardType: TextInputType.number, onSaved: (v) => _saturacionOxigeno = v!)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Peso (kg)'), keyboardType: TextInputType.number, onSaved: (v) => _peso = v!)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Talla (cm)'), keyboardType: TextInputType.number, onSaved: (v) => _talla = v!)),
                ],
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: _isLoading ? const SizedBox() : const Icon(Icons.save),
                  label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('GUARDAR EN BASE DE DATOS'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}