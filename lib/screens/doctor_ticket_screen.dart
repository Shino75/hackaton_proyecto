import 'package:flutter/material.dart';
import 'package:inicio/services/hospital_repository.dart';
import 'package:inicio/services/pdf_service.dart';


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
  final _repository = HospitalRepository(); 

  // --- VARIABLES ---
  String _diagnosticoPrincipal = '';
  String _codigoCie = '';
  String _estadoDiagnostico = 'Presuntivo';

  List<Map<String, dynamic>> _medicamentosRecetados = []; 
  String _medNombre = '';
  String _medDosis = '';
  String _medFrecuencia = '';
  String _medDuracion = ''; 
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _cargarDatosBorrador();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _cargarDatosBorrador() {
    final dx = widget.pacienteData['dx_actual'];
    if (dx != null && dx is Map && dx.isNotEmpty) {
      _diagnosticoPrincipal = dx['nombre'] ?? '';
      _codigoCie = dx['cie'] ?? '';
      _estadoDiagnostico = dx['estado'] ?? 'Presuntivo';
    }

    final meds = widget.pacienteData['meds_actual'];
    if (meds != null && meds is List && meds.isNotEmpty) {
      for (var m in meds) {
        _medicamentosRecetados.add({
          'nombre': m['nombre'],
          'dosis': m['dosis'],
          'frecuencia': m['frecuencia'],
          'duracion': m['duracion']
        });
      }
    }
  }

  void _guardarDiagnostico() async {
    if (_diagnosticoKey.currentState!.validate()) {
      _diagnosticoKey.currentState!.save();
      setState(() => _isSaving = true);

      try {
        await _repository.guardarConsulta(
          idEpisodio: widget.pacienteData['id_episodio'],
          idPaciente: widget.pacienteData['id_paciente'],
          diagnostico: _diagnosticoPrincipal,
          cie: _codigoCie,
          estado: _estadoDiagnostico,
          medicamentos: _medicamentosRecetados,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Diagnóstico guardado (Borrador)'), backgroundColor: Colors.green),
          );
          _tabController.animateTo(2); 
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
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
          'duracion': _medDuracion,
        });
      });
      _recetaKey.currentState!.reset();
    }
  }

  // --- FUNCIÓN FINALIZAR CON PDF ---
  void _finalizarConsulta() async {
    if (_diagnosticoKey.currentState != null) {
       if (_diagnosticoKey.currentState!.validate()) {
         _diagnosticoKey.currentState!.save();
       }
    }

    if (_diagnosticoPrincipal.isEmpty) {
      _tabController.animateTo(1); 
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('⚠️ Falta el diagnóstico.')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _repository.guardarConsulta(
        idEpisodio: widget.pacienteData['id_episodio'],
        idPaciente: widget.pacienteData['id_paciente'],
        diagnostico: _diagnosticoPrincipal,
        cie: _codigoCie,
        estado: _estadoDiagnostico,
        medicamentos: _medicamentosRecetados,
      );

      // LLAMADA AL SERVICIO PDF
      if (mounted) {
        await PdfService.imprimirReceta(
          pacienteData: widget.pacienteData,
          medicamentos: _medicamentosRecetados,
          diagnostico: _diagnosticoPrincipal,
          doctorNombre: "Dr. Usuario Actual", 
          cedulaDoctor: "987654321",          
        );
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('✅ Consulta Finalizada'),
            content: const Text('La receta se ha generado y los datos se guardaron correctamente.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); 
                },
                child: const Text('Aceptar'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signos = widget.pacienteData['signos'];
    final historial = widget.pacienteData['historial'] as List;
    final alergias = widget.pacienteData['alergias'] as List;
    final motivo = widget.pacienteData['motivo'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel Médico'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.teal.shade100,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Info & Historial'),
            Tab(icon: Icon(Icons.assignment), text: 'Diagnóstico'),
            Tab(icon: Icon(Icons.medication), text: 'Receta'),
          ],
        ),
      ),
      body: _isSaving ? const Center(child: CircularProgressIndicator()) : TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard('Datos Generales', [
                  'Nombre: ${widget.pacienteData['nombre']}',
                  'CURP: ${widget.pacienteData['curp']}',
                  'Edad: ${widget.pacienteData['edad']} años | Sexo: ${widget.pacienteData['genero']}',
                  'Teléfono: ${widget.pacienteData['telefono']}',
                ]),
                const SizedBox(height: 10),
                if (alergias.isNotEmpty)
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(10), color: Colors.red.shade100,
                    child: Text('⚠️ ALERGIAS: ${alergias.join(", ")}', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.bold)),
                  ),
                const SizedBox(height: 10),
                _buildInfoCard('Signos Vitales (Triage Actual)', [
                  'Motivo Ingreso: $motivo',
                  'FC: ${signos['fc']} | Temp: ${signos['temp']}°C | SpO2: ${signos['spo2']}%',
                  'Peso: ${signos['peso']}kg | Talla: ${signos['talla']}cm',
                ], color: Colors.orange.shade50),
                const Divider(height: 30, thickness: 2),
                const Text('Historial Clínico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.teal)),
                const SizedBox(height: 10),
                if (historial.isEmpty)
                  const Padding(padding: EdgeInsets.all(20.0), child: Text("No hay consultas anteriores.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)))
                else
                  ...historial.map((h) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(h['fecha'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                              const Icon(Icons.history, size: 18, color: Colors.grey),
                            ],
                          ),
                          const Divider(),
                          Text("Dx: ${h['diagnostico']}", style: const TextStyle(fontWeight: FontWeight.w600)),
                          if (h['receta'] != null && h['receta'] != 'Sin medicamentos')
                            Padding(padding: const EdgeInsets.only(top: 5), child: Text("💊 ${h['receta']}", style: TextStyle(color: Colors.blue.shade900, fontSize: 13)))
                        ],
                      ),
                    ),
                  )),
              ],
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _diagnosticoKey,
              child: Column(
                children: [
                  const Text('Evaluación Clínica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  TextFormField(
                    initialValue: _diagnosticoPrincipal,
                    decoration: const InputDecoration(labelText: 'Diagnóstico Principal', border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    onSaved: (v) => _diagnosticoPrincipal = v!,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: TextFormField(initialValue: _codigoCie, decoration: const InputDecoration(labelText: 'CIE-10', border: OutlineInputBorder()), onSaved: (v) => _codigoCie = v!)),
                      const SizedBox(width: 10),
                      Expanded(child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
                        value: _estadoDiagnostico,
                        items: ['Presuntivo', 'Confirmado'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => _estadoDiagnostico = v!),
                      )),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _guardarDiagnostico,
                    icon: const Icon(Icons.save),
                    label: const Text('GUARDAR BORRADOR'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.all(15)),
                  )
                ],
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Form(
                  key: _recetaKey,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
                    child: Column(
                      children: [
                        const Text('Agregar Medicamento', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        TextFormField(decoration: const InputDecoration(labelText: 'Nombre'), validator: (v) => v!.isEmpty ? 'Requerido' : null, onSaved: (v) => _medNombre = v!),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Dosis'), validator: (v) => v!.isEmpty ? 'Req' : null, onSaved: (v) => _medDosis = v!)),
                            const SizedBox(width: 10),
                            Expanded(child: TextFormField(decoration: const InputDecoration(labelText: 'Frecuencia'), validator: (v) => v!.isEmpty ? 'Req' : null, onSaved: (v) => _medFrecuencia = v!)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(decoration: const InputDecoration(labelText: 'Duración (días)', hintText: 'Ej. 7'), keyboardType: TextInputType.number, onSaved: (v) => _medDuracion = v!),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(onPressed: _agregarMedicamento, icon: const Icon(Icons.add), label: const Text('Agregar a la Lista')),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 20),
                if (_medicamentosRecetados.isNotEmpty) ...[
                  const Align(alignment: Alignment.centerLeft, child: Text("Receta Actual:", style: TextStyle(fontWeight: FontWeight.bold))),
                  ..._medicamentosRecetados.map((m) => Card(
                    child: ListTile(
                      title: Text(m['nombre']),
                      subtitle: Text("${m['dosis']} - ${m['frecuencia']} (${m['duracion']} días)"),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _medicamentosRecetados.remove(m))),
                    ),
                  )),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _finalizarConsulta,
                      icon: const Icon(Icons.check_circle),
                      label: const Text('FINALIZAR Y GUARDAR TODO'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    ),
                  )
                ] else 
                  const Padding(padding: EdgeInsets.all(20), child: Text('No hay medicamentos agregados.', style: TextStyle(color: Colors.grey)))
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
            ...lines.map((line) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(line))).toList(),
          ],
        ),
      ),
    );
  }
}