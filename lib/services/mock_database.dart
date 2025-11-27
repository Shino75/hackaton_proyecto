// lib/services/mock_database.dart

class MockDatabase {
  // Lista estática para guardar los pacientes mientras la app está abierta
  static final List<Map<String, dynamic>> _registros = [];

  // Método para guardar (INSERT)
  static void guardarPaciente(Map<String, dynamic> datos) {
    _registros.add(datos);
    // Imprimimos en consola para verificar
    print("BD: Paciente guardado. Total registros: ${_registros.length}");
    print("Datos: $datos");
  }

  // Método para buscar (SELECT WHERE CURP = ?)
  static Map<String, dynamic>? buscarPorCurp(String curp) {
    try {
      // Busca ignorando mayúsculas/minúsculas
      return _registros.firstWhere(
        (paciente) => paciente['curp'].toString().toUpperCase() == curp.toUpperCase()
      );
    } catch (e) {
      // Si no encuentra nada devuelve null
      return null;
    }
  }
}