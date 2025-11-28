import 'package:flutter/material.dart';
import 'package:inicio/services/hospital_repository.dart';
import 'package:inicio/services/pdf_service.dart';
// Asegúrate de que esta ruta sea correcta según tu proyecto
import '../widgets/modulo_alergias.dart';

class DoctorTicketScreen extends StatefulWidget {
  final Map<String, dynamic> pacienteData;

  const DoctorTicketScreen({super.key, required this.pacienteData});

  @override
  State<DoctorTicketScreen> createState() => _DoctorTicketScreenState();
}

class _DoctorTicketScreenState extends State<DoctorTicketScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _diagnosticoKey = GlobalKey<FormState>();
  final _recetaKey = GlobalKey<FormState>();
  // 🟢 Nueva clave para el formulario de procedimientos
  final _procedimientoKey = GlobalKey<FormState>(); 
  final _repository = HospitalRepository();

  // --- VARIABLES DIAGNÓSTICO ---
  String _diagnosticoPrincipal = '';
  String _codigoCie = '';
  String _estadoDiagnostico = 'Presuntivo';

  // --- VARIABLES MEDICAMENTOS ---
  List<Map<String, dynamic>> _medicamentosRecetados = [];
  String _medNombre = '';
  String _medDosis = '';
  String _medFrecuencia = '';
  String _medDuracion = '';

  // 🟢 --- VARIABLES PROCEDIMIENTOS ---
  List<Map<String, dynamic>> _procedimientos = [];
  String _nombreProcedimiento = '';
  String _codigoCups = '';
  String _descripcionDetallada = '';
  String _tipoProcedimiento = 'Diagnóstico';
  DateTime _fechaProcedimiento = DateTime.now();

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
    // Diagnóstico
    final dx = widget.pacienteData['dx_actual'];
    if (dx != null && dx is Map && dx.isNotEmpty) {
      _diagnosticoPrincipal = dx['nombre'] ?? '';
      _codigoCie = dx['cie'] ?? '';
      _estadoDiagnostico = dx['estado'] ?? 'Presuntivo';
    }

    // Medicamentos
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

    // 🟢 Cargar Procedimientos
    final procs = widget.pacienteData['procs_actual'];
    if (procs != null && procs is List && procs.isNotEmpty) {
      for (var p in procs) {
        _procedimientos.add({
          'nombre_procedimiento': p['nombre_procedimiento'],
          'codigo_cups': p['codigo_cups'],
          'fecha_procedimiento': _parseFecha(p['fecha_procedimiento']),
          'descripcion_detallada': p['descripcion_detallada'],
          'tipo_procedimiento': p['tipo_procedimiento']
        });
      }
    }
  }

  DateTime _parseFecha(dynamic fecha) {
    if (fecha is DateTime) return fecha;
    if (fecha is String) {
      try {
        return DateTime.parse(fecha);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  // 🟢 Función para seleccionar fecha
  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaProcedimiento,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _fechaProcedimiento) {
      setState(() {
        _fechaProcedimiento = picked;
      });
    }
  }

  // 🟢 Función para agregar procedimiento a la lista local
  void _agregarProcedimiento() {
    if (_procedimientoKey.currentState!.validate()) {
      _procedimientoKey.currentState!.save();
      setState(() {
        _procedimientos.add({
          'nombre_procedimiento': _nombreProcedimiento,
          'codigo_cups': _codigoCups,
          'fecha_procedimiento': _fechaProcedimiento, 
          'descripcion_detallada': _descripcionDetallada,
          'tipo_procedimiento': _tipoProcedimiento,
        });
        
        // Limpiar campos
        _nombreProcedimiento = '';
        _codigoCups = '';
        _descripcionDetallada = '';
        _fechaProcedimiento = DateTime.now();
      });
      _procedimientoKey.currentState!.reset();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Procedimiento agregado a la lista'), duration: Duration(seconds: 1)),
      );
    }
  }

  // 🟢 Función para eliminar procedimiento
  void _eliminarProcedimiento(int index) {
    setState(() {
      _procedimientos.removeAt(index);
    });
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
          procedimientos: _procedimientos, // 🟢 Enviamos procedimientos
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Datos guardados correctamente (Borrador)'),
              backgroundColor: Colors.green,
            ),
          );
          // Opcional: _tabController.animateTo(2);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Falta el diagnóstico.')),
      );
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
        procedimientos: _procedimientos, // 🟢 Enviamos procedimientos
      );

      // LLAMADA AL SERVICIO PDF
      if (mounted) {
        await PdfService.imprimirReceta(
          pacienteData: widget.pacienteData,
          medicamentos: _medicamentosRecetados,
          diagnostico: _diagnosticoPrincipal,
          doctorNombre: "Dr. Usuario Actual",
          cedulaDoctor: "987654321", // 🟢 Pasamos procedimientos al PDF
        );
      }

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('✅ Consulta Finalizada'),
            content: const Text(
              'La receta se ha generado y los datos se guardaron correctamente.',
            ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final signos = widget.pacienteData['signos'];
    final historial = widget.pacienteData['historial'] as List;
    final motivo = widget.pacienteData['motivo'];

    // OBTENEMOS LA LISTA DE LABORATORIOS (Puede venir nula o vacía)
    final laboratoriosRaw = widget.pacienteData['laboratorios'];
    List<String> laboratorios = [];
    if (laboratoriosRaw != null && laboratoriosRaw is List) {
      laboratorios = laboratoriosRaw.map((e) => e.toString()).toList();
    }

    final int idPaciente = widget.pacienteData['id_paciente'] as int;

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
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // --- TAB 1: INFO Y HISTORIAL ---
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

                      // Módulo Alergias
                      ModuloAlergias(idPaciente: idPaciente),

                      const SizedBox(height: 10),

                      _buildInfoCard(
                        'Signos Vitales (Triage Actual)',
                        [
                          'Motivo Ingreso: $motivo',
                          'FC: ${signos['fc']} | Temp: ${signos['temp']}°C | SpO2: ${signos['spo2']}%',
                          'Peso: ${signos['peso']}kg | Talla: ${signos['talla']}cm',
                        ],
                        color: Colors.orange.shade50,
                      ),

                      // AQUÍ MOSTRAMOS LOS RESULTADOS DE LABORATORIO (SI EXISTEN)
                      if (laboratorios.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildInfoCard(
                          '🧪 Resultados de Laboratorio',
                          laboratorios, 
                          color: Colors.blue.shade50,
                        ),
                      ],

                      const Divider(height: 30, thickness: 2),

                      const Text(
                        'Historial Clínico',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 10),

                      if (historial.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Text(
                            "No hay consultas anteriores.",
                            style: TextStyle(
                              color: Colors.grey,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        )
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
                                        Text(
                                          h['fecha'],
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.teal,
                                          ),
                                        ),
                                        const Icon(Icons.history, size: 18, color: Colors.grey),
                                      ],
                                    ),
                                    const Divider(),
                                    Text(
                                      "Dx: ${h['diagnostico']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (h['receta'] != null &&
                                        h['receta'] != 'Sin medicamentos')
                                      Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Text(
                                          "💊 ${h['receta']}",
                                          style: TextStyle(
                                            color: Colors.blue.shade900,
                                            fontSize: 13,
                                          ),
                                        ),
                                      )
                                  ],
                                ),
                              ),
                            )),
                    ],
                  ),
                ),

                // --- TAB 2: DIAGNÓSTICO Y PROCEDIMIENTOS ---
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // FORMULARIO DIAGNÓSTICO
                      Form(
                        key: _diagnosticoKey,
                        child: Column(
                          children: [
                            const Text(
                              'Evaluación Clínica',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              initialValue: _diagnosticoPrincipal,
                              decoration: const InputDecoration(
                                labelText: 'Diagnóstico Principal',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                              validator: (v) => v!.isEmpty ? 'Requerido' : null,
                              onSaved: (v) => _diagnosticoPrincipal = v!,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _codigoCie,
                                    decoration: const InputDecoration(
                                      labelText: 'CIE-10',
                                      border: OutlineInputBorder(),
                                    ),
                                    onSaved: (v) => _codigoCie = v!,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    decoration: const InputDecoration(
                                      labelText: 'Estado',
                                      border: OutlineInputBorder(),
                                    ),
                                    value: _estadoDiagnostico,
                                    items: ['Presuntivo', 'Confirmado']
                                        .map((e) => DropdownMenuItem(
                                              value: e,
                                              child: Text(e),
                                            ))
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _estadoDiagnostico = v!),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      const Divider(),

                      // 🟢 FORMULARIO DE PROCEDIMIENTOS
                      Form(
                        key: _procedimientoKey,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📋 Procedimientos Médicos',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Nombre del Procedimiento *',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => v!.isEmpty ? 'Requerido' : null,
                                onSaved: (v) => _nombreProcedimiento = v!,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                        labelText: 'Código CUPS',
                                        border: OutlineInputBorder(),
                                        hintText: 'Opcional',
                                      ),
                                      onSaved: (v) => _codigoCups = v ?? '',
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonFormField<String>(
                                      decoration: const InputDecoration(
                                        labelText: 'Tipo',
                                        border: OutlineInputBorder(),
                                      ),
                                      value: _tipoProcedimiento,
                                      items: [
                                        'Diagnóstico',
                                        'Terapéutico',
                                        'Quirúrgico',
                                        'Preventivo',
                                        'Rehabilitación',
                                        'Otro'
                                      ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                                      onChanged: (v) => setState(() => _tipoProcedimiento = v!),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Selector de fecha
                              InkWell(
                                onTap: _seleccionarFecha,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Fecha del Procedimiento',
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '${_fechaProcedimiento.day}/${_fechaProcedimiento.month}/${_fechaProcedimiento.year}',
                                      ),
                                      const Icon(Icons.calendar_today),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Descripción Detallada',
                                  border: OutlineInputBorder(),
                                  hintText: 'Descripción opcional...',
                                ),
                                maxLines: 3,
                                onSaved: (v) => _descripcionDetallada = v ?? '',
                              ),
                              const SizedBox(height: 15),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _agregarProcedimiento,
                                  icon: const Icon(Icons.add),
                                  label: const Text('AGREGAR PROCEDIMIENTO'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.all(15),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 🟢 LISTA DE PROCEDIMIENTOS AGREGADOS
                      if (_procedimientos.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Procedimientos Agregados:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ..._procedimientos.asMap().entries.map((entry) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          color: Colors.blue.shade50,
                          child: ListTile(
                            leading: const Icon(Icons.medical_services, color: Colors.blue),
                            title: Text(
                              entry.value['nombre_procedimiento'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (entry.value['codigo_cups'] != null && entry.value['codigo_cups'].isNotEmpty)
                                  Text('CUPS: ${entry.value['codigo_cups']}'),
                                Text('Tipo: ${entry.value['tipo_procedimiento']}'),
                                Text('Fecha: ${_formatearFecha(entry.value['fecha_procedimiento'])}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarProcedimiento(entry.key),
                            ),
                          ),
                        )),
                      ],

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _guardarDiagnostico,
                          icon: const Icon(Icons.save),
                          label: const Text('GUARDAR BORRADOR COMPLETO'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.all(15),
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                // --- TAB 3: RECETA ---
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Form(
                        key: _recetaKey,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Agregar Medicamento',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                decoration:
                                    const InputDecoration(labelText: 'Nombre'),
                                validator: (v) =>
                                    v!.isEmpty ? 'Requerido' : null,
                                onSaved: (v) => _medNombre = v!,
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                          labelText: 'Dosis'),
                                      validator: (v) =>
                                          v!.isEmpty ? 'Req' : null,
                                      onSaved: (v) => _medDosis = v!,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      decoration: const InputDecoration(
                                          labelText: 'Frecuencia'),
                                      validator: (v) =>
                                          v!.isEmpty ? 'Req' : null,
                                      onSaved: (v) => _medFrecuencia = v!,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                decoration: const InputDecoration(
                                  labelText: 'Duración (días)',
                                  hintText: 'Ej. 7',
                                ),
                                keyboardType: TextInputType.number,
                                onSaved: (v) => _medDuracion = v!,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: _agregarMedicamento,
                                icon: const Icon(Icons.add),
                                label: const Text('Agregar a la Lista'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 20),
                      if (_medicamentosRecetados.isNotEmpty) ...[
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Receta Actual:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ..._medicamentosRecetados.map((m) => Card(
                              child: ListTile(
                                title: Text(m['nombre']),
                                subtitle: Text(
                                    "${m['dosis']} - ${m['frecuencia']} (${m['duracion']} días)"),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => setState(
                                      () => _medicamentosRecetados.remove(m)),
                                ),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        )
                      ] else
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text(
                            'No hay medicamentos agregados.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _formatearFecha(dynamic fecha) {
    if (fecha is DateTime) {
      return '${fecha.day}/${fecha.month}/${fecha.year}';
    }
    if (fecha is String) {
      try {
        DateTime dt = DateTime.parse(fecha);
         return '${dt.day}/${dt.month}/${dt.year}';
      } catch(e) {
        return fecha;
      }
    }
    return 'Fecha no disponible';
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
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.teal,
              ),
            ),
            const Divider(),
            ...lines.map((line) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(line),
                )),
          ],
        ),
      ),
    );
  }
}