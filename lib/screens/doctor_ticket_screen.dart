// lib/screens/doctor_ticket_screen.dart

import 'package:flutter/material.dart';

class DoctorTicketScreen extends StatefulWidget {
  final Map<String, dynamic> pacienteData;

  const DoctorTicketScreen({super.key, required this.pacienteData});

  @override
  State<DoctorTicketScreen> createState() => _DoctorTicketScreenState();
}

class _DoctorTicketScreenState extends State<DoctorTicketScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _diagnosticoKey = GlobalKey<FormState>();
  final _recetaKey = GlobalKey<FormState>();

  // Variables Diagnóstico
  String _diagnosticoPrincipal = '';
  String _codigoCie = '';
  String _estadoDiagnostico = 'Presuntivo';

  // Variables Receta
  List<Map<String, String>> _medicamentosRecetados = []; 
  String _medNombre = '';
  String _medDosis = '';
  String _medFrecuencia = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _guardarDiagnostico() {
    if (_diagnosticoKey.currentState!.validate()) {
      _diagnosticoKey.currentState!.save();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Diagnóstico actualizado temporalmente.')),
      );
      _tabController.animateTo(2); // Ir a Receta
    }
  }

  void _agregarMedicamento() {
    if (_recetaKey.currentState!.validate()) {
      _recetaKey.currentState!.save();
      setState(() {
        _medicamentosRecetados.add({
          'nombre': _medNombre,
          'dosis': _medDosis,
          'frecuencia': _medFrecuencia,
        });
      });
      _recetaKey.currentState!.reset();
    }
  }

  void _finalizarConsulta() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('✅ Consulta Finalizada'),
        content: Text('Se ha registrado el diagnóstico y ${_medicamentosRecetados.length} medicamentos para el paciente ${widget.pacienteData['nombre']}.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(); // Cerrar alerta
              Navigator.of(context).pop(); // Cerrar ticket (volver a búsqueda)
            },
            child: const Text('Aceptar y Salir'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍⚕️ Panel Médico'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.teal.shade100,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.person), text: 'Info'),
            Tab(icon: Icon(Icons.assignment), text: 'Diagnóstico'),
            Tab(icon: Icon(Icons.medication), text: 'Receta'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: INFO PACIENTE
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard('Datos Generales', [
                  'Nombre: ${widget.pacienteData['nombre']}',
                  'CURP: ${widget.pacienteData['curp']}',
                  'Edad: ${widget.pacienteData['edad']} años',
                  'Género: ${widget.pacienteData['genero'] == 'M' ? 'Masculino' : 'Femenino'}',
                  'Teléfono: ${widget.pacienteData['telefono']}',
                ]),
                const SizedBox(height: 10),
                _buildInfoCard('Signos Vitales (Triage)', [
                  'Motivo: ${widget.pacienteData['motivo']}',
                  '${widget.pacienteData['signos']}',
                ], color: Colors.orange.shade50),
              ],
            ),
          ),

          // TAB 2: DIAGNÓSTICO
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _diagnosticoKey,
              child: Column(
                children: [
                  const Text('Evaluación Clínica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Diagnóstico Principal', border: OutlineInputBorder()),
                    maxLines: 2,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    onSaved: (v) => _diagnosticoPrincipal = v!,
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'CIE-10', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          onSaved: (v) => _codigoCie = v!,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                          value: _estadoDiagnostico,
                          items: ['Presuntivo', 'Confirmado'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setState(() => _estadoDiagnostico = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _guardarDiagnostico,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar Diagnóstico'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                  )
                ],
              ),
            ),
          ),

          // TAB 3: RECETA
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Form(
                  key: _recetaKey,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Column(
                      children: [
                        const Text('Agregar Medicamento', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        TextFormField(
                          decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                          validator: (v) => v!.isEmpty ? 'Requerido' : null,
                          onSaved: (v) => _medNombre = v!,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Dosis', border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                              onSaved: (v) => _medDosis = v!,
                            )),
                            const SizedBox(width: 10),
                            Expanded(child: TextFormField(
                              decoration: const InputDecoration(labelText: 'Frecuencia', border: OutlineInputBorder()),
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                              onSaved: (v) => _medFrecuencia = v!,
                            )),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _agregarMedicamento,
                          child: const Text('Agregar'),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 30),
                
                if (_medicamentosRecetados.isNotEmpty) ...[
                  const Text('Resumen de Receta:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _medicamentosRecetados.length,
                    itemBuilder: (ctx, index) {
                      final med = _medicamentosRecetados[index];
                      return ListTile(
                        leading: const Icon(Icons.medication),
                        title: Text(med['nombre']!),
                        subtitle: Text('${med['dosis']} - ${med['frecuencia']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _medicamentosRecetados.removeAt(index)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _finalizarConsulta,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green, 
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(15)
                      ),
                      child: const Text('FINALIZAR CONSULTA', style: TextStyle(fontSize: 16)),
                    ),
                  )
                ] else 
                   const Text('No hay medicamentos agregados.', style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> lines, {Color color = Colors.white}) {
    return Card(
      color: color,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
            const Divider(),
            ...lines.map((line) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Text(line),
            )).toList(),
          ],
        ),
      ),
    );
  }
}