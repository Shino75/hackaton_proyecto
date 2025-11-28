import 'package:postgres/postgres.dart';
import 'db_service.dart';

class HospitalRepository {
  final DbService _dbService = DbService();

  // --- 1. ENFERMERA: REGISTRAR INGRESO (Sin cambios, funciona bien) ---
  Future<void> registrarIngreso(Map<String, dynamic> datos) async {
    final conn = await _dbService.getConnection();
    await conn.runTx((session) async {
      // A. Insertar Paciente
      final resultPaciente = await session.execute(
        Sql.named("""
          INSERT INTO pacientes (nombre, apellido_paterno, fecha_nacimiento, genero, curp, contacto_telefono, direccion_completa)
          VALUES (@nombre, @apellido, @nacimiento, @genero, @curp, @tel, @dir)
          RETURNING id_paciente
        """),
        parameters: {
          'nombre': datos['nombre'],
          'apellido': datos['apellido'],
          'nacimiento': DateTime.parse(datos['fecha_nacimiento']),
          'genero': datos['genero'],
          'curp': datos['curp'],
          'tel': datos['telefono'],
          'dir': datos['direccion'],
        },
      );
      final idPaciente = resultPaciente[0][0] as int;

      // B. Insertar Episodio
      final resultEpisodio = await session.execute(
        Sql.named("""
          INSERT INTO episodios_medicos (id_paciente, fecha_ingreso, motivo_ingreso, tipo_episodio)
          VALUES (@idPac, @fecha, @motivo, 'Urgencia')
          RETURNING id_episodio
        """),
        parameters: {'idPac': idPaciente, 'fecha': DateTime.now(), 'motivo': datos['motivo']},
      );
      final idEpisodio = resultEpisodio[0][0] as int;

      // C. Insertar Signos Vitales
      await session.execute(
        Sql.named("""
          INSERT INTO evaluacion_enfermeria (id_episodio, id_usuario_enfermero, peso_kg, talla_cm, temperatura, frecuencia_cardiaca, saturacion_oxigeno, fecha_registro)
          VALUES (@idEpisodio, 1, @peso, @talla, @temp, @fc, @spo2, @fecha)
        """),
        parameters: {
          'idEpisodio': idEpisodio,
          'peso': double.tryParse(datos['peso'].toString()) ?? 0.0,
          'talla': double.tryParse(datos['talla'].toString()) ?? 0.0,
          'temp': double.tryParse(datos['temp'].toString()) ?? 0.0,
          'fc': int.tryParse(datos['fc'].toString()) ?? 0,
          'spo2': int.tryParse(datos['spo2'].toString()) ?? 0,
          'fecha': DateTime.now(),
        },
      );
    });
  }

  // --- 2. DOCTOR: BUSCAR EXPEDIENTE REAL EN BD ---
  Future<Map<String, dynamic>?> buscarExpedienteCompleto(String curp) async {
    final conn = await _dbService.getConnection();

    // A. Datos del Paciente y Episodio Actual
    final resultPaciente = await conn.execute(
      Sql.named("""
        SELECT 
          p.nombre, p.apellido_paterno, p.fecha_nacimiento, p.genero, p.curp, p.contacto_telefono,
          e.id_episodio, e.motivo_ingreso,
          ev.frecuencia_cardiaca, ev.temperatura, ev.saturacion_oxigeno, ev.peso_kg, ev.talla_cm,
          p.id_paciente
        FROM pacientes p
        JOIN episodios_medicos e ON p.id_paciente = e.id_paciente
        JOIN evaluacion_enfermeria ev ON e.id_episodio = ev.id_episodio
        WHERE p.curp = @curp
        ORDER BY e.fecha_ingreso DESC
        LIMIT 1
      """),
      parameters: {'curp': curp},
    );

    if (resultPaciente.isEmpty) return null;

    final row = resultPaciente.first;
    final int idPaciente = row[13] as int;
    final int idEpisodioActual = row[6] as int;
    final fechaNac = row[2] as DateTime;
    final edad = DateTime.now().year - fechaNac.year;

    // B. Buscar Alergias Reales
    final resultAlergias = await conn.execute(
      Sql.named("SELECT agente_alergico FROM alergias WHERE id_paciente = @id"),
      parameters: {'id': idPaciente}
    );
    final alergiasList = resultAlergias.map((r) => r[0] as String).toList();

    // C. HISTORIAL REAL (Lo que ya se guardó en visitas pasadas)
    final resultHistorial = await conn.execute(
      Sql.named("""
        SELECT 
          e.fecha_ingreso, 
          COALESCE(e.diagnostico_principal, 'Sin diagnóstico') as dx,
          STRING_AGG(m.nombre_medicamento || ' (' || m.dosis || ')', ', ') as receta_resumen
        FROM episodios_medicos e
        LEFT JOIN medicamentos m ON e.id_episodio = m.id_episodio
        WHERE e.id_paciente = @id AND e.id_episodio != @actual
        GROUP BY e.id_episodio, e.fecha_ingreso, e.diagnostico_principal
        ORDER BY e.fecha_ingreso DESC
      """),
      parameters: {'id': idPaciente, 'actual': idEpisodioActual}
    );

    final historialList = resultHistorial.map((r) => {
      'fecha': r[0].toString().split(' ')[0],
      'diagnostico': r[1],
      'receta': r[2] ?? 'Sin medicamentos'
    }).toList();

    // D. Cargar BORRADOR del episodio actual (si el doctor ya guardó algo hoy)
    // Diagnóstico Borrador
    final resultDxActual = await conn.execute(
      Sql.named("SELECT nombre_diagnostico, codigo_cie, estado_diagnostico FROM diagnosticos WHERE id_episodio = @id LIMIT 1"),
      parameters: {'id': idEpisodioActual}
    );
    Map<String, dynamic> dxActual = {};
    if (resultDxActual.isNotEmpty) {
      dxActual = {
        'nombre': resultDxActual.first[0],
        'cie': resultDxActual.first[1],
        'estado': resultDxActual.first[2]
      };
    }

    // Medicamentos Borrador
    final resultMedsActual = await conn.execute(
      Sql.named("SELECT nombre_medicamento, dosis, frecuencia, fecha_inicio, fecha_fin FROM medicamentos WHERE id_episodio = @id"),
      parameters: {'id': idEpisodioActual}
    );
    final medsActualList = resultMedsActual.map((r) {
      String duracion = '';
      if (r[4] != null && r[3] != null) {
        final ini = r[3] as DateTime;
        final fin = r[4] as DateTime;
        duracion = fin.difference(ini).inDays.toString();
      }
      return {
        'nombre': r[0],
        'dosis': r[1],
        'frecuencia': r[2],
        'duracion': duracion
      };
    }).toList();

    return {
      'id_episodio': idEpisodioActual,
      'id_paciente': idPaciente,
      'nombre': "${row[0]} ${row[1]}",
      'curp': row[4],
      'edad': edad.toString(),
      'genero': row[3],
      'telefono': row[5],
      'motivo': row[7],
      'signos': {
        'fc': row[8], 'temp': row[9], 'spo2': row[10], 'peso': row[11], 'talla': row[12]
      },
      'alergias': alergiasList,
      'historial': historialList, // Datos pasados
      'dx_actual': dxActual,      // Datos presentes (si existen)
      'meds_actual': medsActualList
    };
  }

  // --- 3. GUARDAR CONSULTA (Actualizar BD) ---
  Future<void> guardarConsulta({
    required int idEpisodio,
    required int idPaciente,
    required String diagnostico,
    required String cie,
    required String estado,
    required List<Map<String, dynamic>> medicamentos,
  }) async {
    final conn = await _dbService.getConnection();
    await conn.runTx((session) async {
      
      // Borramos datos previos DE ESTE EPISODIO para sobrescribir con la versión nueva
      await session.execute(Sql.named("DELETE FROM diagnosticos WHERE id_episodio = @id"), parameters: {'id': idEpisodio});
      await session.execute(Sql.named("DELETE FROM medicamentos WHERE id_episodio = @id"), parameters: {'id': idEpisodio});

      // Guardar Diagnóstico Nuevo
      await session.execute(
        Sql.named("INSERT INTO diagnosticos (id_episodio, nombre_diagnostico, codigo_cie, estado_diagnostico, fecha_deteccion) VALUES (@id, @nom, @cie, @est, @fecha)"),
        parameters: {'id': idEpisodio, 'nom': diagnostico, 'cie': cie, 'est': estado, 'fecha': DateTime.now()}
      );

      // Actualizar Episodio Principal
      await session.execute(
        Sql.named("UPDATE episodios_medicos SET diagnostico_principal = @diag, fecha_egreso = @fecha, id_medico_responsable = 1 WHERE id_episodio = @id"),
        parameters: {'diag': diagnostico, 'fecha': DateTime.now(), 'id': idEpisodio}
      );

      // Guardar Receta Nueva
      for (var med in medicamentos) {
        DateTime? fechaFin;
        if (med['duracion'] != null && med['duracion'].toString().isNotEmpty) {
           int dias = int.tryParse(med['duracion'].toString()) ?? 0;
           if (dias > 0) fechaFin = DateTime.now().add(Duration(days: dias));
        }
        await session.execute(
          Sql.named("INSERT INTO medicamentos (id_episodio, id_paciente, nombre_medicamento, dosis, frecuencia, fecha_inicio, fecha_fin) VALUES (@idEp, @idPac, @nom, @dos, @frec, @fechaIni, @fechaFin)"),
          parameters: {'idEp': idEpisodio, 'idPac': idPaciente, 'nom': med['nombre'], 'dos': med['dosis'], 'frec': med['frecuencia'], 'fechaIni': DateTime.now(), 'fechaFin': fechaFin}
        );
      }
    });
  }
}