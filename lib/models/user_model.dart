class User {
  final int id;
  final String email;
  final String nombre;
  final String apellidoPaterno;
  final String apellidoMaterno;
  final String rol;

  User({
    required this.id,
    required this.email,
    required this.nombre,
    required this.apellidoPaterno,
    required this.apellidoMaterno,
    required this.rol,
  });

  // Getter útil para la UI:
  // Si en tu app mostrabas "nombre_completo", usa este getter
  // para no tener que cambiar todo tu diseño visual.
  String get nombreCompleto => '$nombre $apellidoPaterno $apellidoMaterno';
}