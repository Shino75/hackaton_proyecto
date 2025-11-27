// lib/models/paciente.dart

class Paciente {
  // Estos campos reflejan los datos permanentes del paciente.

  String nombre;
  String apellidoPaterno;
  DateTime fechaNacimiento;
  String genero;
  String curp;
  String contactoTelefono;
  String direccionCompleta;

  Paciente({
    required this.nombre,
    required this.apellidoPaterno,
    required this.fechaNacimiento,
    required this.genero,
    required this.curp,
    required this.contactoTelefono,
    required this.direccionCompleta,
  });
}