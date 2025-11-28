// Archivo: lib/widgets/modulo_alergias.dart

import 'package:flutter/material.dart';
import '../services/alergia_repository.dart'; // 🟢 Repositorio dedicado
import '../models/alergia_model.dart';      // 🟢 Modelo de datos

class ModuloAlergias extends StatefulWidget {
  final int idPaciente;

  const ModuloAlergias({super.key, required this.idPaciente});

  @override
  State<ModuloAlergias> createState() => _ModuloAlergiasState();
}

class _ModuloAlergiasState extends State<ModuloAlergias> {
  final _formKey = GlobalKey<FormState>();
  // 🟢 Instancia del repositorio dedicado
  final _repository = AlergiaRepository(); 
  
  List<AlergiaModel> _alergias = [];
  bool _isLoading = true;
  
  // Variables del formulario
  String _agente = '';
  String _reaccion = '';
  String _severidad = 'Leve';

  @override
  void initState() {
    super.initState();
    _cargarAlergias();
  }
  
  void _cargarAlergias() async {
    setState(() => _isLoading = true);
    try {
      final data = await _repository.cargarAlergias(widget.idPaciente);
      setState(() {
        _alergias = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar historial de alergias: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleGuardarAlergia() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      
      setState(() => _isLoading = true);
      
      // 🟢 Crear el objeto Modelo
      final nuevaAlergia = AlergiaModel(
        idPaciente: widget.idPaciente,
        agenteAlergico: _agente,
        reaccion: _reaccion,
        severidad: _severidad,
      );

      try {
        await _repository.guardarAlergia(nuevaAlergia);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Alergia registrada con éxito.'), backgroundColor: Colors.red),
          );
          _formKey.currentState!.reset();
          setState(() {
            _severidad = 'Leve';
          }); 
          _cargarAlergias(); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al guardar alergia: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('⚠️ Alertas Clínicas (Alergias)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
            const Divider(),
            
            // --- MOSTRAR LISTA DE ALERGIAS ---
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _alergias.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text("No hay alergias registradas.", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.green)),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _alergias.map((a) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            // 🟢 Usamos las propiedades del modelo (a.severidad)
                            color: a.severidad == 'Grave' ? Colors.red.shade100 : Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.red)
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(a.agenteAlergico, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                              Text('Reacción: ${a.reaccion}'),
                              Text('Severidad: ${a.severidad}', style: const TextStyle(fontStyle: FontStyle.italic)),
                            ],
                          ),
                        )).toList(),
                      ),
            
            const Divider(height: 30),

            // --- FORMULARIO DE CAPTURA ---
            const Text('Registrar Nueva Alergia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Agente Alérgico'),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    onSaved: (v) => _agente = v!,
                  ),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Reacción / Síntomas'),
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    onSaved: (v) => _reaccion = v!,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Severidad'),
                    value: _severidad, 
                    items: ['Leve', 'Moderada', 'Grave'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setState(() => _severidad = v!),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleGuardarAlergia,
                    icon: _isLoading ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.add_alert),
                    label: Text(_isLoading ? 'Guardando...' : 'REGISTRAR ALERGIA'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}