import 'package:postgres/postgres.dart';
import '../models/user_model.dart';
import 'db_service.dart';

class AuthService {
  final DbService _dbService = DbService();

  Future<User?> login(String email, String password) async {
    try {
      final connection = await _dbService.getConnection();

      // ACTUALIZACIÓN:
      // 1. Cambiamos 'nombre_completo' por 'nombre', 'apellido_paterno', 'apellido_materno'.
      // 2. Mantenemos la seguridad usando parámetros con @ (Sql.named).
      final Result result = await connection.execute(
        Sql.named('''
          SELECT 
            id_usuario, 
            email, 
            nombre, 
            apellido_paterno, 
            apellido_materno, 
            rol 
          FROM usuarios 
          WHERE email = @email AND password_hash = @password
        '''),
        parameters: {
          'email': email,
          'password': password,
        },
      );

      if (result.isNotEmpty) {
        final row = result.first;
        
        // ACTUALIZACIÓN DEL MAPEO:
        // Los índices cambian porque agregamos columnas al SELECT.
        return User(
          id: row[0] as int,
          email: row[1] as String,
          nombre: row[2] as String,           // Antes era nombre_completo
          apellidoPaterno: row[3] as String,  // Nuevo campo
          apellidoMaterno: row[4] as String,  // Nuevo campo
          rol: row[5] as String,              // Se desplazó al índice 5
        );
      }
      return null;
    } catch (e) {
      print("Error en Login: $e");
      return null;
    }
  }
}