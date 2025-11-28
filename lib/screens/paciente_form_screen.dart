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

  // --- VARIABLES DE CONTROL ---
  String _tipoServicio = 'Consulta'; // 'Consulta' o 'Estudio'
  bool _isLoading = false;

  // Datos Personales
  String _nombre = '';
  String _apellidoPaterno = '';
  DateTime? _fechaNacimiento;
  String? _generoSeleccionado;
  final List<String> _generos = ['M', 'F'];
  String _curp = '';
  String _telefono = '';
  String _direccion = '';
  final TextEditingController _fechaController = TextEditingController();

  // Variables Signos (Consulta)
  String _motivoConsulta = '';
  String _fc = '';
  String _fr = '';
  String _temp = '';
  String _spo2 = '';
  String _peso = '';
  String _talla = '';

  // Variables Laboratorio (Estudio - KEYS DE DB)
  String _tipoEstudioNombre = 'Química Sanguínea (6)';
  String _glucosa = '';
  String _urea = '';
  String _creatinina = '';
  String _acidoUrico = '';
  String _colesterol = '';
  String _trigliceridos = '';
  String _observacionesLab = '';

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

      // Definimos el motivo general para el historial
      String motivoFinal = _tipoServicio == 'Consulta'
          ? _motivoConsulta
          : "LABORATORIO: $_tipoEstudioNombre";

      try {
        await _repository.registrarIngreso({
          // Datos Comunes
          'tipo_servicio': _tipoServicio, // Importante para el switch en DB
          'nombre': _nombre,
          'apellido': _apellidoPaterno,
          'fecha_nacimiento': _fechaController.text,
          'genero': _generoSeleccionado,
          'curp': _curp,
          'telefono': _telefono,
          'direccion': _direccion,
          'motivo': motivoFinal,

          // Datos Consulta
          'fc': _fc,
          'fr': _fr,
          'temp': _temp,
          'spo2': _spo2,
          'peso': _peso,
          'talla': _talla,

          // Datos Laboratorio (KEYS EXACTAS)
          'tipo_estudio_nombre': _tipoEstudioNombre,
          'glucosa': _glucosa,
          'urea': _urea,
          'creatinina': _creatinina,
          'acido_urico': _acidoUrico,
          'colesterol': _colesterol,
          'trigliceridos': _trigliceridos,
          'observaciones': _observacionesLab,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Registro guardado: $_tipoServicio'), backgroundColor: Colors.green),
          );
          // Limpiar formulario
          _formKey.currentState?.reset();
          _fechaController.clear();
          setState(() {
            _fechaNacimiento = null;
            _generoSeleccionado = null;
            _tipoServicio = 'Consulta'; 
          });
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
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
        actions: [IconButton(icon: const Icon(Icons.logout), onPressed: _cerrarSesion)],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // --- SECCIÓN 1: DATOS DEL PACIENTE ---
              _buildSectionTitle("Datos del Paciente", Icons.person),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()), onSaved: (v) => _nombre = v!, validator: (v) => v!.isEmpty ? 'Req' : null)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Apellidos', border: OutlineInputBorder()), onSaved: (v) => _apellidoPaterno = v!, validator: (v) => v!.isEmpty ? 'Req' : null)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _fechaController, decoration: const InputDecoration(labelText: 'Nacimiento', border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)), readOnly: true, onTap: () => _selectDate(context), validator: (v) => v!.isEmpty ? 'Req' : null)),
                  const SizedBox(width: 10),
                  Expanded(child: DropdownButtonFormField<String>(decoration: const InputDecoration(labelText: 'Sexo', border: OutlineInputBorder()), value: _generoSeleccionado, items: _generos.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(), onChanged: (v) => setState(() => _generoSeleccionado = v))),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(decoration: const InputDecoration(labelText: 'CURP', border: OutlineInputBorder()), onSaved: (v) => _curp = v!, validator: (v) => v!.isEmpty ? 'Req' : null),
              
              const SizedBox(height: 25),

              // --- SECCIÓN 2: TIPO DE REGISTRO ---
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.blue.shade200)),
                child: Column(
                  children: [
                    const Text("¿Qué desea registrar?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 5),
                    DropdownButtonFormField<String>(
                      value: _tipoServicio,
                      decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'Consulta', child: Row(children: [Icon(Icons.monitor_heart, color: Colors.red), SizedBox(width: 10), Text("Signos Vitales (Triage)")])),
                        DropdownMenuItem(value: 'Estudio', child: Row(children: [Icon(Icons.science, color: Colors.teal), SizedBox(width: 10), Text("Resultados Laboratorio")])),
                      ],
                      onChanged: (val) => setState(() => _tipoServicio = val!),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- CAMPOS DINÁMICOS ---
              if (_tipoServicio == 'Consulta') ...[
                _buildSectionTitle("Signos Vitales", Icons.favorite),
                const SizedBox(height: 10),
                TextFormField(decoration: const InputDecoration(labelText: 'Motivo Consulta', border: OutlineInputBorder()), onSaved: (v) => _motivoConsulta = v!, validator: (v) => v!.isEmpty ? 'Req' : null),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'FC (lpm)'), keyboardType: TextInputType.number, onSaved: (v) => _fc = v!)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'FR (rpm)'), keyboardType: TextInputType.number, onSaved: (v) => _fr = v!)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Temp (°C)'), keyboardType: TextInputType.number, onSaved: (v) => _temp = v!)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'SpO2 (%)'), keyboardType: TextInputType.number, onSaved: (v) => _spo2 = v!)),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Peso (kg)'), keyboardType: TextInputType.number, onSaved: (v) => _peso = v!)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Talla (cm)'), keyboardType: TextInputType.number, onSaved: (v) => _talla = v!)),
                ]),

              ] else ...[
                // --- CAMPOS DE LABORATORIO (KEYS DB) ---
                _buildSectionTitle("Resultados Lab (Química 6)", Icons.biotech),
                const SizedBox(height: 10),
                TextFormField(initialValue: 'Química Sanguínea', decoration: const InputDecoration(labelText: 'Tipo de Estudio', border: OutlineInputBorder()), onSaved: (v) => _tipoEstudioNombre = v!),
                const SizedBox(height: 15),
                // FILA 1
                Row(children: [
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Glucosa (mg/dL)', border: OutlineInputBorder()), keyboardType: TextInputType.number, onSaved: (v) => _glucosa = v!)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Urea (mg/dL)', border: OutlineInputBorder()), keyboardType: TextInputType.number, onSaved: (v) => _urea = v!)),
                ]),
                const SizedBox(height: 10),
                // FILA 2
                Row(children: [
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Creatinina (mg/dL)', border: OutlineInputBorder()), keyboardType: TextInputType.number, onSaved: (v) => _creatinina = v!)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Ácido Úrico (mg/dL)', border: OutlineInputBorder()), keyboardType: TextInputType.number, onSaved: (v) => _acidoUrico = v!)),
                ]),
                const SizedBox(height: 10),
                // FILA 3
                Row(children: [
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Colesterol (mg/dL)', border: OutlineInputBorder()), keyboardType: TextInputType.number, onSaved: (v) => _colesterol = v!)),
                  const SizedBox(width: 10),
                  Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Triglicéridos (mg/dL)', border: OutlineInputBorder()), keyboardType: TextInputType.number, onSaved: (v) => _trigliceridos = v!)),
                ]),
                const SizedBox(height: 15),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Observaciones / Notas', border: OutlineInputBorder()),
                  maxLines: 3,
                  onSaved: (v) => _observacionesLab = v!,
                ),
              ],

              const SizedBox(height: 30),
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitForm,
                  icon: const Icon(Icons.save),
                  label: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('GUARDAR DATOS', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(backgroundColor: _tipoServicio == 'Consulta' ? Colors.indigo : Colors.teal, foregroundColor: Colors.white),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(children: [Icon(icon, color: Colors.grey), const SizedBox(width: 8), Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87))]);
  }
}