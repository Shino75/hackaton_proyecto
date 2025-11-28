import 'package:flutter/material.dart';

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  
  // Claves de formulario
  final GlobalKey<FormState> _doctorFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _nurseFormKey = GlobalKey<FormState>();
  
  // Controladores de Bajas
  final TextEditingController _searchController = TextEditingController();

  // Variables de Estado de los Formularios (Expediente Completo)
  late Map<String, TextEditingController> _doctorControllers;
  late Map<String, TextEditingController> _nurseControllers;
  
  final List<String> _generoOpciones = ['Masculino', 'Femenino', 'Otro'];

  // Definición de Colores Azules
  final Color _appBarColor = Colors.indigo;
  final Color _doctorPrimaryColor = Colors.blue[800]!; // Azul fuerte para Doctor
  final Color _nursePrimaryColor = Colors.cyan[800]!; // Azul verdoso para Enfermera
  final Color _directoryColor = Colors.blue; 


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); 

    // Definición de controladores comunes y nuevos campos
    final Map<String, TextEditingController> baseControllers = {
      'nombre': TextEditingController(),
      'apellido_paterno': TextEditingController(),
      'apellido_materno': TextEditingController(),
      'email': TextEditingController(),
      'password': TextEditingController(),
      'cedula': TextEditingController(),
      'firma': TextEditingController(),
      'fecha_nacimiento': TextEditingController(),
      'genero': TextEditingController(text: _generoOpciones.first),
      'telefono': TextEditingController(),
      'curp': TextEditingController(),
      'domicilio': TextEditingController(),
    };

    // Controladores específicos por rol
    _doctorControllers = {...baseControllers, 'especialidad': TextEditingController()};
    _nurseControllers = {...baseControllers, 'area_especializacion': TextEditingController()};
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _doctorControllers.forEach((key, controller) => controller.dispose());
    _nurseControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // --- Método de Simulación de Guardado/Actualización ---
  void _saveUser(String role, GlobalKey<FormState> formKey, Map<String, TextEditingController> controllers) {
    if (formKey.currentState!.validate()) {
      final userData = {
        'Rol': role,
        'Nombre Completo': '${controllers['nombre']!.text} ${controllers['apellido_paterno']!.text} ${controllers['apellido_materno']!.text}',
        'CURP': controllers['curp']!.text,
        'Cédula/Matrícula': controllers['cedula']!.text,
        'Especialidad/Área': controllers[role == 'Doctor' ? 'especialidad' : 'area_especializacion']!.text,
      };
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Expediente COMPLETO de $role guardado con éxito. Datos clave: ${userData.toString()}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
        ),
      );
      formKey.currentState!.reset();
      setState(() {
         controllers['genero']!.text = _generoOpciones.first;
      });
    }
  }

  // --- Método de Simulación de Baja/Desactivación ---
  void _deactivateUser() {
    final identifier = _searchController.text.trim();

    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Por favor, ingrese el Email o Cédula para dar de baja.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🛑 Usuario con identificador "$identifier" marcado como INACTIVO (Simulación de UPDATE en BD).'),
        backgroundColor: Colors.red,
      ),
    );
    _searchController.clear();
  }


  // --- Widget del Formulario de CREACIÓN (Reutilizable con más campos) ---
  Widget _buildUserForm({required String role, required GlobalKey<FormState> formKey, required Map<String, TextEditingController> controllers}) {
    final Color primaryColor = role == 'Doctor' ? _doctorPrimaryColor : _nursePrimaryColor;

    return Form(
      key: formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Registro de Expediente $role COMPLETO',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor),
            ),
            const Divider(color: Colors.grey, height: 25),

            // =========================================================
            // SECCIÓN 1: DATOS DE ACCESO
            // =========================================================
            _buildSectionTitle('Datos de Acceso y Credenciales', Icons.vpn_key, primaryColor),
            _buildTextField(controller: controllers['email'], label: 'Correo Electrónico (Login ID)', icon: Icons.email, keyboardType: TextInputType.emailAddress, isRequired: true, hint: 'correo@ejemplo.com'),
            _buildTextField(controller: controllers['password'], label: 'Contraseña Provisional', icon: Icons.lock, isPassword: true, isRequired: true),
            _buildTextField(controller: controllers['firma'], label: 'Firma Digital (URL/ID)', icon: Icons.fingerprint, isRequired: false, hint: 'ID o URL de la firma'),
            
            const Divider(height: 30, color: Colors.blueGrey),

            // =========================================================
            // SECCIÓN 2: DATOS PERSONALES DEL EXPEDIENTE
            // =========================================================
            _buildSectionTitle('Datos Personales de Expediente', Icons.assignment_ind, primaryColor),

            // Nombres y Apellidos
            Row(
              children: [
                Expanded(child: _buildTextField(controller: controllers['nombre'], label: 'Nombre(s)', icon: Icons.person_outline, isRequired: true)),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField(controller: controllers['apellido_paterno'], label: 'Apellido Paterno', icon: Icons.person_outline, isRequired: true)),
              ],
            ),
            _buildTextField(controller: controllers['apellido_materno'], label: 'Apellido Materno', icon: Icons.person_outline, isRequired: true),
            
            // CURP y Fecha de Nacimiento
            _buildTextField(controller: controllers['curp'], label: 'CURP', icon: Icons.article, isRequired: true, hint: '18 caracteres'),
            _buildDateField(controller: controllers['fecha_nacimiento']!),
            
            // Género y Teléfono
            _buildDropdownField(
              controller: controllers['genero']!,
              label: 'Género',
              icon: Icons.wc,
              options: _generoOpciones,
            ),
            _buildTextField(controller: controllers['telefono'], label: 'Teléfono de Contacto', icon: Icons.phone, keyboardType: TextInputType.phone, isRequired: true),
            _buildTextField(controller: controllers['domicilio'], label: 'Domicilio Completo', icon: Icons.location_on, isRequired: true, maxLines: 3, hint: 'Calle, Número, Colonia, C.P., Ciudad'),

            const Divider(height: 30, color: Colors.blueGrey),

            // =========================================================
            // SECCIÓN 3: DATOS PROFESIONALES
            // =========================================================
            _buildSectionTitle('Datos Profesionales', Icons.work, primaryColor),
            _buildTextField(controller: controllers['cedula'], label: 'Cédula Profesional / Matrícula', icon: Icons.badge, isRequired: true),
            
            // Campo Específico por Rol
            if (role == 'Doctor')
              _buildTextField(controller: controllers['especialidad'], label: 'Especialidad Médica', icon: Icons.stars, isRequired: true, hint: 'Ej: Cardiología, Pediatría'),
            
            if (role == 'Enfermera')
              _buildTextField(controller: controllers['area_especializacion'], label: 'Área de Especialización', icon: Icons.timeline, isRequired: true, hint: 'Ej: Terapia Intensiva, Quirófano'),


            // =========================================================
            // BOTÓN DE GUARDAR
            // =========================================================
            const SizedBox(height: 30),

            ElevatedButton.icon(
              onPressed: () => _saveUser(role, formKey, controllers),
              icon: const Icon(Icons.save),
              label: Text('Guardar Expediente COMPLETO del $role'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget de Gestión de BAJAS ---
  Widget _buildDeactivationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Gestión de Bajas y Desactivación',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const Divider(color: Colors.grey),

          const Text(
            'Para dar de baja a un usuario (Doctor o Enfermera), ingrese su Correo Electrónico o su Cédula Profesional.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 20),

          _buildTextField(
            controller: _searchController,
            label: 'Email o Cédula a Desactivar',
            icon: Icons.person_off,
            isRequired: true,
            hint: 'ID único del usuario',
          ),

          const SizedBox(height: 20),
          
          ElevatedButton.icon(
            onPressed: _deactivateUser,
            icon: const Icon(Icons.warning_amber),
            label: const Text('Dar de Baja / Desactivar Usuario'),
            style: ElevatedButton.styleFrom(
              // Usamos el color rojo para indicar una acción destructiva/de advertencia
              backgroundColor: Colors.red[700], 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 15),
              textStyle: const TextStyle(fontSize: 18),
            ),
          ),
          
          const SizedBox(height: 20),
          const Text(
            'Nota Importante: En bases de datos de salud, los usuarios no se eliminan permanentemente (DELETE), sino que se marcan como inactivos (UPDATE estado = 0) por razones de trazabilidad y auditoría.',
            style: TextStyle(fontSize: 13, color: Colors.red),
          ),
        ],
      ),
    );
  }

  // --- Widget de Directorio de Personal (NUEVA PESTAÑA) ---
  Widget _buildDirectoryScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.people_outline,
              size: 80,
              color: _directoryColor, // Usamos el color del directorio
            ),
            const SizedBox(height: 20),
            const Text(
              'Directorio de Personal Registrado',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Aquí se mostraría la lista completa y paginada de todos los Médicos y Enfermeras registrados en la base de datos (Ejemplo: Nombre, Cédula, Especialidad).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Simulación: aquí se haría la llamada a la DB
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cargando datos del directorio... (Simulación)'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              icon: const Icon(Icons.list),
              label: const Text('Cargar Listado Completo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _directoryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }


  // --- WIDGET AUXILIAR PARA TÍTULO DE SECCIÓN ---
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0, bottom: 15.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  // --- WIDGET AUXILIAR PARA CAMPO DE TEXTO ---

  Widget _buildTextField({
    required TextEditingController? controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool isRequired = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    String hint = '',
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: isPassword,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label + (isRequired ? ' *' : ''),
          alignLabelWithHint: true,
          hintText: hint,
          prefixIcon: Icon(icon, color: Colors.grey),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        validator: validator ?? (value) {
          if (isRequired && (value == null || value.isEmpty)) {
            return 'Este campo es obligatorio.';
          }
          return null;
        },
      ),
    );
  }

  // --- WIDGET AUXILIAR PARA CAMPO DE FECHA ---
  Widget _buildDateField({required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: TextFormField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Fecha de Nacimiento *',
          hintText: 'YYYY-MM-DD',
          prefixIcon: Icon(Icons.calendar_today, color: Colors.grey),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        readOnly: true,
        onTap: () async {
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: DateTime(2000),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );

          if (pickedDate != null) {
            String formattedDate = "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
            setState(() {
              controller.text = formattedDate;
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo es obligatorio.';
          }
          return null;
        },
      ),
    );
  }

  // --- WIDGET AUXILIAR PARA CAMPO DROPDOWN ---
  Widget _buildDropdownField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required List<String> options,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: '$label *',
          prefixIcon: Icon(icon, color: Colors.grey),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        ),
        initialValue: controller.text.isNotEmpty && options.contains(controller.text) ? controller.text : options.first,
        items: options.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              controller.text = newValue;
            });
          }
        },
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Este campo es obligatorio.';
          }
          return null;
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚙️ Panel de Administración de Usuarios'),
        backgroundColor: _appBarColor, // Color de barra de aplicación azul
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Doctor', icon: Icon(Icons.local_hospital)),
            Tab(text: 'Enfermera', icon: Icon(Icons.medical_services)),
            Tab(text: 'Bajas/Gestión', icon: Icon(Icons.remove_circle)), 
            Tab(text: 'Directorio', icon: Icon(Icons.people)), 
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pestaña 1: Doctor
          _buildUserForm(role: 'Doctor', formKey: _doctorFormKey, controllers: _doctorControllers),
          // Pestaña 2: Enfermera
          _buildUserForm(role: 'Enfermera', formKey: _nurseFormKey, controllers: _nurseControllers),
          // Pestaña 3: Gestión de Bajas
          _buildDeactivationForm(), 
          // Pestaña 4: Directorio
          _buildDirectoryScreen(), 
        ],
      ),
    );
  }
}