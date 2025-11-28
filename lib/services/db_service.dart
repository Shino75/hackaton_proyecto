import 'package:postgres/postgres.dart';

class DbService {
  // Ajusta si usas emulador (10.0.2.2) o Windows (localhost)
  static const String host = 'localhost'; 
  static const int port = 5432;
  static const String databaseName = 'Expediente_Clinico_DB';
  static const String username = 'postgres'; 
  static const String password = '123'; // <--- ¡PON TU CONTRASEÑA!

  Connection? _connection;

  Future<Connection> getConnection() async {
    // Verificamos si ya está abierta
    if (_connection != null && _connection!.isOpen) {
      return _connection!;
    }

    try {
      // NUEVA SINTAXIS DE LA VERSIÓN 3.0
      _connection = await Connection.open(
        Endpoint(
          host: host,
          port: port,
          database: databaseName,
          username: username,
          password: password,
        ),
        settings: ConnectionSettings(
          sslMode: SslMode.disable, // Importante para local
        ),
      );
      print("✅ Conexión exitosa a la Base de Datos");
    } catch (e) {
      print("❌ Error conectando a la BD: $e");
      rethrow;
    }

    return _connection!;
  }
}