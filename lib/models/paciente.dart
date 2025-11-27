// lib/models/paciente.dart

class Paciente {
  // id_paciente es serial, se generaría en la BD, no lo incluimos en el formulario.

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