// lib/services/hospital_repository.dart

import 'package:postgres/postgres.dart';
import 'db_service.dart'; // Importa tu archivo de conexión existente

class HospitalRepository {
  // Instancia de tu servicio de conexión
  final DbService _dbService = DbService();

  // --- 1. ENFERMERA: GUARDAR PACIENTE Y EPISODIO ---
  Future<void> registrarIngreso(Map<String, dynamic> datos) async {
    final conn = await _dbService.getConnection();

    // Usamos una transacción para asegurar que se guarden las 3 tablas o ninguna
    await conn.runTx((session) async {
      
      // A. Insertar Paciente y obtener su ID
      final resultPaciente = await session.execute(
        Sql.named("""
          INSERT INTO pacientes 
            (nombre, apellido_paterno, fecha_nacimiento, genero, curp, contacto_telefono, direccion_completa)
          VALUES 
            (@nombre, @apellido, @nacimiento, @genero, @curp, @tel, @dir)
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

      // B. Crear Episodio Médico vinculado al paciente
      final resultEpisodio = await session.execute(
        Sql.named("""
          INSERT INTO episodios_medicos 
            (id_paciente, fecha_ingreso, motivo_ingreso, tipo_episodio)
          VALUES 
            (@idPac, @fecha, @motivo, 'Urgencia')
          RETURNING id_episodio
        """),
        parameters: {
          'idPac': idPaciente,
          'fecha': DateTime.now(),
          'motivo': datos['motivo'],
        },
      );
      final idEpisodio = resultEpisodio[0][0] as int;

      // C. Guardar Signos Vitales (Evaluación Enfermería)
      // NOTA: Asumimos id_usuario_enfermero = 1 por ahora (asegúrate de que exista en tu DB)
      await session.execute(
        Sql.named("""
          INSERT INTO evaluacion_enfermeria 
            (id_episodio, id_usuario_enfermero, peso_kg, talla_cm, temperatura, frecuencia_cardiaca, saturacion_oxigeno, fecha_registro)
          VALUES 
            (@idEpisodio, 1, @peso, @talla, @temp, @fc, @spo2, @fecha)
        """),
        parameters: {
          'idEpisodio': idEpisodio,
          // Convertimos a los tipos correctos (double/int)
          'peso': double.tryParse(datos['peso'].toString()) ?? 0.0,
          'talla': double.tryParse(datos['talla'].toString()) ?? 0.0,
          'temp': double.tryParse(datos['temp'].toString()) ?? 0.0,
          'fc': int.tryParse(datos['fc'].toString()) ?? 0,
          'spo2': int.tryParse(datos['spo2'].toString()) ?? 0,
          'fecha': DateTime.now(),
        },
      );
      
      print("✅ ¡Paciente registrado en PostgreSQL! ID Episodio: $idEpisodio");
    });
  }

  // --- 2. DOCTOR: BUSCAR POR CURP ---
  Future<Map<String, dynamic>?> buscarPorCurp(String curp) async {
    final conn = await _dbService.getConnection();

    // Hacemos JOIN para traer datos del paciente + último episodio + signos
    final result = await conn.execute(
      Sql.named("""
        SELECT 
          p.nombre, p.apellido_paterno, p.fecha_nacimiento, p.genero, p.curp, p.contacto_telefono,
          e.id_episodio, e.motivo_ingreso,
          ev.frecuencia_cardiaca, ev.temperatura, ev.saturacion_oxigeno, ev.peso_kg
        FROM pacientes p
        JOIN episodios_medicos e ON p.id_paciente = e.id_paciente
        JOIN evaluacion_enfermeria ev ON e.id_episodio = ev.id_episodio
        WHERE p.curp = @curp
        ORDER BY e.fecha_ingreso DESC
        LIMIT 1
      """),
      parameters: {'curp': curp},
    );

    if (result.isEmpty) return null;

    final row = result.first;
    
    // Calcular edad
    final fechaNac = row[2] as DateTime;
    final edad = DateTime.now().year - fechaNac.year;

    // Retornamos un mapa limpio para que la pantalla lo entienda
    return {
      'id_episodio': row[6],
      'nombre': "${row[0]} ${row[1]}",
      'curp': row[4],
      'edad': edad.toString(),
      'genero': row[3],
      'telefono': row[5],
      'motivo': row[7],
      'signos': "FC: ${row[8]} | T: ${row[9]}°C | SpO2: ${row[10]}% | Peso: ${row[11]}kg"
    };
  }
}