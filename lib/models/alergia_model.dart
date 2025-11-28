// Archivo: lib/models/alergia_model.dart

class AlergiaModel {
  final int? idAlergia;
  final int idPaciente;
  final String agenteAlergico;
  final String reaccion;
  final String severidad;
  final DateTime? fechaRegistro;

  AlergiaModel({
    this.idAlergia,
    required this.idPaciente,
    required this.agenteAlergico,
    required this.reaccion,
    required this.severidad,
    this.fechaRegistro,
  });

  factory AlergiaModel.fromJson(Map<String, dynamic> json) {
    return AlergiaModel(
      idAlergia: json['id_alergia'] as int?,
      idPaciente: json['id_paciente'] as int,
      agenteAlergico: json['agente_alergico'] as String,
      reaccion: json['reaccion'] as String,
      severidad: json['severidad'] as String,
      // Se ajusta la conversión si viene como String (de una API) o DateTime (de PostgreSQL)
      fechaRegistro: json['fecha_registro'] is String 
          ? DateTime.tryParse(json['fecha_registro'] as String) 
          : json['fecha_registro'] as DateTime?,
    );
  }

  // 🟢 Método para convertir el modelo a un Map de parámetros para la consulta SQL
  Map<String, dynamic> toSqlParams() {
    return {
      'id_paciente': idPaciente,
      'agente_alergico': agenteAlergico,
      'reaccion': reaccion,
      'severidad': severidad,
    };
  }
}