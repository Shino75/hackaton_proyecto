// lib/models/paciente.dart

class Paciente {
  // Coincide con tabla: pacientes
  int? idPaciente; // serial
  String nombre; // varchar(100)
  String apellidoPaterno; // varchar(100)
  DateTime fechaNacimiento; // date
  String genero; // char(1) -> 'M', 'F'
  String curp; // varchar(18)
  String contactoTelefono; // varchar(15)
  String direccionCompleta; // varchar(255)

  Paciente({
    this.idPaciente,
    required this.nombre,
    required this.apellidoPaterno,
    required this.fechaNacimiento,
    required this.genero,
    required this.curp,
    required this.contactoTelefono,
    required this.direccionCompleta,
  });
}