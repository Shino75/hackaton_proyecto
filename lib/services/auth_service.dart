import 'package:postgres/postgres.dart'; // Importante importar esto
import '../models/user_model.dart';
import 'db_service.dart';

class AuthService {
  final DbService _dbService = DbService();

  Future<User?> login(String email, String password) async {
    try {
      final connection = await _dbService.getConnection();

      // NUEVA SINTAXIS DE CONSULTA (v3)
      // Usamos Sql.named para pasar parámetros con @
      final Result result = await connection.execute(
        Sql.named('SELECT id_usuario, email, nombre_completo, rol FROM usuarios WHERE email = @email AND password_hash = @password'),
        parameters: {
          'email': email,
          'password': password, 
        },
      );

      if (result.isNotEmpty) {
        // En la v3, accedemos a la primera fila (row) así:
        final row = result.first;
        
        return User(
          id: row[0] as int,
          email: row[1] as String,
          nombre: row[2] as String,
          rol: row[3] as String,
        );
      }
      return null;
    } catch (e) {
      print("Error en Login: $e");
      return null;
    }
  }
}