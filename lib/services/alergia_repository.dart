// Archivo: lib/services/alergia_repository.dart

import 'package:postgres/postgres.dart';
// Asegúrate de que esta ruta sea correcta para tu DbService
import 'db_service.dart'; 
import '../models/alergia_model.dart'; 

// 🌟 REPOSITORIO DEDICADO A ALERGIAS (Implementación real con PostgreSQL) 🌟
class AlergiaRepository {
  // Instancia del servicio de conexión a la base de datos
  final DbService _dbService = DbService();
  
  // FUNCIÓN 1: Guardar una nueva alergia (INSERT en la tabla 'alergias')
  Future<void> guardarAlergia(AlergiaModel nuevaAlergia) async {
    final conn = await _dbService.getConnection();
    
    // Ejecutar la inserción en una transacción
    await conn.runTx((session) async {
      final params = nuevaAlergia.toSqlParams(); // Obtener parámetros del modelo
      
      await session.execute(
        Sql.named("""
          INSERT INTO alergias (
            id_paciente, agente_alergico, reaccion, severidad, fecha_registro
          ) VALUES (
            @id_paciente, @agente_alergico, @reaccion, @severidad, CURRENT_DATE
          )
        """),
        parameters: params,
      );
    });
    // La conexión se cierra automáticamente por runTx/getConnection
  }
  
  // FUNCIÓN 2: Cargar las alergias de un paciente (SELECT en la tabla 'alergias')
  Future<List<AlergiaModel>> cargarAlergias(int idPaciente) async {
    final conn = await _dbService.getConnection();
    
    final result = await conn.execute(
      Sql.named("""
        SELECT 
          id_alergia, id_paciente, agente_alergico, reaccion, severidad, fecha_registro
        FROM alergias
        WHERE id_paciente = @id
        ORDER BY severidad DESC, fecha_registro DESC
      """),
      parameters: {'id': idPaciente}
    );
    
    // Mapear los resultados de la consulta de la DB (PostgreSQL Row) a AlergiaModel
    final List<Map<String, dynamic>> alergiasRaw = result.map((row) {
      // Mapear los índices de la columna a los nombres de las claves del modelo.
      return {
        'id_alergia': row[0] as int,
        'id_paciente': row[1] as int,
        'agente_alergico': row[2] as String,
        'reaccion': row[3] as String,
        'severidad': row[4] as String,
        // PostgreSQL devuelve DateTime para el tipo DATE o TIMESTAMP
        'fecha_registro': row[5] as DateTime?, 
      };
    }).toList();
    
    // Usar el constructor fromJson para convertir el Map a objetos AlergiaModel
    return alergiasRaw.map((data) => AlergiaModel.fromJson(data)).toList();
  }
}