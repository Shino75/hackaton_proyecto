import 'package:postgres/postgres.dart';
import 'db_service.dart';

class HospitalRepository {
  final DbService _dbService = DbService();

  // --- 1. ENFERMERA: REGISTRAR INGRESO (CON SOPORTE PARA LABORATORIO) ---
  Future<void> registrarIngreso(Map<String, dynamic> datos) async {
    final conn = await _dbService.getConnection();
    
    await conn.runTx((session) async {
      // ---------------------------------------------------
      // PASO A: Insertar o reutilizar Paciente
      // ---------------------------------------------------
      final resultBusqueda = await session.execute(
        Sql.named("SELECT id_paciente FROM pacientes WHERE curp = @curp"),
        parameters: {'curp': datos['curp']},
      );

      int idPaciente;

      if (resultBusqueda.isNotEmpty) {
        // Si ya existe, usamos su ID
        idPaciente = resultBusqueda.first[0] as int;
      } else {
        // Si no existe, lo insertamos
        final resultInsertPaciente = await session.execute(
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
        idPaciente = resultInsertPaciente[0][0] as int;
      }

      // ---------------------------------------------------
      // PASO B: Insertar Episodio Médico
      // ---------------------------------------------------
      final tipoEpisodio = (datos['tipo_servicio'] == 'Estudio') ? 'Laboratorio' : 'Urgencia';

      final resultEpisodio = await session.execute(
        Sql.named("""
          INSERT INTO episodios_medicos (id_paciente, fecha_ingreso, motivo_ingreso, tipo_episodio)
          VALUES (@idPac, @fecha, @motivo, @tipo)
          RETURNING id_episodio
        """),
        parameters: {
          'idPac': idPaciente,
          'fecha': DateTime.now(),
          'motivo': datos['motivo'],
          'tipo': tipoEpisodio,
        },
      );
      final idEpisodio = resultEpisodio[0][0] as int;

      // ---------------------------------------------------
      // PASO C: Insertar Datos Específicos (SWITCH)
      // ---------------------------------------------------
      
      if (datos['tipo_servicio'] == 'Estudio') {
        // >>> CASO 1: LABORATORIO (Insertar múltiples filas) <<<
        
        final estudiosPosibles = {
          'glucosa': 'Glucosa (mg/dL)',
          'urea': 'Urea (mg/dL)',
          'creatinina': 'Creatinina (mg/dL)',
          'acido_urico': 'Ácido Úrico (mg/dL)',
          'colesterol': 'Colesterol (mg/dL)',
          'trigliceridos': 'Triglicéridos (mg/dL)',
        };

        // Recorremos cada campo. Si tiene valor, insertamos una fila.
        for (var entry in estudiosPosibles.entries) {
          String keyFormulario = entry.key;
          String nombreEstudioDb = entry.value;
          
          var valor = datos[keyFormulario];

          // Solo insertamos si el valor no está vacío ni nulo
          if (valor != null && valor.toString().trim().isNotEmpty) {
             await session.execute(
              Sql.named("""
                INSERT INTO resultados_lab (
                  id_episodio, 
                  nombre_estudio,    -- Nombre del estudio (ej. Glucosa)
                  valor_resultado,   -- Valor capturado (ej. 95)
                  fecha_toma,
                  documento_enlace   -- Usamos esto para observaciones
                ) VALUES (
                  @idEp, 
                  @nombre, 
                  @valor, 
                  CURRENT_DATE,
                  @obs
                )
              """),
              parameters: {
                'idEp': idEpisodio,
                'nombre': nombreEstudioDb,
                'valor': valor.toString(),
                'obs': datos['observaciones'] ?? '',
              },
            );
          }
        }

      } else {
        // >>> CASO 2: CONSULTA NORMAL (Signos Vitales) <<<
        await session.execute(
          Sql.named("""
            INSERT INTO evaluacion_enfermeria (
              id_episodio, id_usuario_enfermero, peso_kg, talla_cm, temperatura, frecuencia_cardiaca, saturacion_oxigeno, fecha_registro
            )
            VALUES (@idEp, 1, @peso, @talla, @temp, @fc, @spo2, @fecha)
          """),
          parameters: {
            'idEp': idEpisodio,
            'peso': double.tryParse(datos['peso'].toString()) ?? 0.0,
            'talla': double.tryParse(datos['talla'].toString()) ?? 0.0,
            'temp': double.tryParse(datos['temp'].toString()) ?? 0.0,
            'fc': int.tryParse(datos['fc'].toString()) ?? 0,
            'spo2': int.tryParse(datos['spo2'].toString()) ?? 0,
            'fecha': DateTime.now(),
          },
        );
      }
    });
  }

  // --- 2. DOCTOR: BUSCAR EXPEDIENTE (Actualizado con Labs) ---
  Future<Map<String, dynamic>?> buscarExpedienteCompleto(String curp) async {
    final conn = await _dbService.getConnection();

    // A. Buscar Paciente y Episodio Actual
    final resultPaciente = await conn.execute(
      Sql.named("""
        SELECT 
          p.nombre, p.apellido_paterno, p.fecha_nacimiento, p.genero, p.curp, p.contacto_telefono,
          e.id_episodio, e.motivo_ingreso, e.tipo_episodio,
          ev.frecuencia_cardiaca, ev.temperatura, ev.saturacion_oxigeno, ev.peso_kg, ev.talla_cm,
          p.id_paciente
        FROM pacientes p
        JOIN episodios_medicos e ON p.id_paciente = e.id_paciente
        LEFT JOIN evaluacion_enfermeria ev ON e.id_episodio = ev.id_episodio
        WHERE p.curp = @curp
        ORDER BY e.fecha_ingreso DESC
        LIMIT 1
      """),
      parameters: {'curp': curp},
    );

    if (resultPaciente.isEmpty) return null;

    final row = resultPaciente.first;
    final int idPaciente = row[14] as int;
    final int idEpisodioActual = row[6] as int;
    final fechaNac = row[2] as DateTime;
    final edad = DateTime.now().year - fechaNac.year;

    // B. Alergias
    final resultAlergias = await conn.execute(
      Sql.named("SELECT agente_alergico FROM alergias WHERE id_paciente = @id"),
      parameters: {'id': idPaciente}
    );
    final alergiasList = resultAlergias.map((r) => r[0] as String).toList();

    // --- C. NUEVO: Resultados de Laboratorio del Episodio Actual ---
    final resultLabs = await conn.execute(
      Sql.named("SELECT nombre_estudio, valor_resultado FROM resultados_lab WHERE id_episodio = @id"),
      parameters: {'id': idEpisodioActual}
    );
    // Convertimos a una lista de Strings para facilitar la visualización (Ej: "Glucosa: 100")
    final laboratoriosList = resultLabs.map((r) => "${r[0]}: ${r[1]}").toList();

    // D. Historial
    final resultHistorial = await conn.execute(
      Sql.named("""
        SELECT 
           d.nombre_diagnostico,
           d.fecha_deteccion,
           d.estado_diagnostico
        FROM diagnosticos d
        JOIN episodios_medicos e ON d.id_episodio = e.id_episodio
        WHERE e.id_paciente = @id
        ORDER BY d.fecha_deteccion DESC
      """),
      parameters: {'id': idPaciente} 
    );

    final historialList = resultHistorial.map((r) {
      String fechaStr = '---';
      if (r[1] != null) fechaStr = r[1].toString().split(' ')[0]; 
      return {
        'fecha': fechaStr,
        'diagnostico': "${r[0]} (${r[2] ?? 'Presuntivo'})", 
        'receta': null 
      };
    }).toList();

    // E. Datos actuales (Diagnóstico y Meds)
    Map<String, dynamic> dxActual = {};
    final resultDxActual = await conn.execute(
      Sql.named("SELECT nombre_diagnostico, codigo_cie, estado_diagnostico FROM diagnosticos WHERE id_episodio = @id ORDER BY id_diagnostico DESC LIMIT 1"),
      parameters: {'id': idEpisodioActual}
    );
    if (resultDxActual.isNotEmpty) {
      dxActual = {
        'nombre': resultDxActual.first[0],
        'cie': resultDxActual.first[1],
        'estado': resultDxActual.first[2]
      };
    }

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
        'fc': row[9] ?? 0, 
        'temp': row[10] ?? 0.0, 
        'spo2': row[11] ?? 0, 
        'peso': row[12] ?? 0.0, 
        'talla': row[13] ?? 0.0
      },
      'laboratorios': laboratoriosList, // <--- LISTA AGREGADA
      'alergias': alergiasList,
      'historial': historialList,
      'dx_actual': dxActual,
      'meds_actual': medsActualList
    };
  }

  // --- 3. GUARDAR CONSULTA ---
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

      // 1. Evitar duplicados de diagnóstico
      final existente = await session.execute(
        Sql.named("""
          SELECT id_diagnostico 
          FROM diagnosticos
          WHERE id_episodio = @idEp AND nombre_diagnostico = @nom
        """),
        parameters: {'idEp': idEpisodio, 'nom': diagnostico},
      );

      if (existente.isEmpty) {
        await session.execute(
          Sql.named("""
            INSERT INTO diagnosticos (id_episodio, nombre_diagnostico, codigo_cie, estado_diagnostico, fecha_deteccion)
            VALUES (@idEp, @nom, @cie, @est, @fecha)
          """),
          parameters: {
            'idEp': idEpisodio,
            'nom': diagnostico,
            'cie': cie,
            'est': estado,
            'fecha': DateTime.now(),
          },
        );
      }

      // 2. Actualizar episodio
      await session.execute(
        Sql.named("""
          UPDATE episodios_medicos
          SET diagnostico_principal = @nom, fecha_egreso = @fecha, id_medico_responsable = 1
          WHERE id_episodio = @idEp
        """),
        parameters: {'idEp': idEpisodio, 'nom': diagnostico, 'fecha': DateTime.now()},
      );

      // 3. Reemplazar receta
      await session.execute(
        Sql.named("DELETE FROM medicamentos WHERE id_episodio = @idEp"),
        parameters: {'idEp': idEpisodio},
      );

      for (final med in medicamentos) {
        DateTime? fechaFin;
        if (med['duracion'] != null && med['duracion'].toString().isNotEmpty) {
          final dias = int.tryParse(med['duracion'].toString()) ?? 0;
          if (dias > 0) fechaFin = DateTime.now().add(Duration(days: dias));
        }

        await session.execute(
          Sql.named("""
            INSERT INTO medicamentos (id_episodio, id_paciente, nombre_medicamento, dosis, frecuencia, fecha_inicio, fecha_fin) 
            VALUES (@idEp, @idPac, @nom, @dos, @freq, @ini, @fin)
          """),
          parameters: {
            'idEp': idEpisodio,
            'idPac': idPaciente,
            'nom': med['nombre'],
            'dos': med['dosis'],
            'freq': med['frecuencia'],
            'ini': DateTime.now(),
            'fin': fechaFin,
          },
        );
      }
    });
  }
}