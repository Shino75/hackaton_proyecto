// lib/screens/home_screen.dart (REEMPLAZAR CONTENIDO COMPLETO)

import 'package:flutter/material.dart';
// Importación corregida (solo necesitas importar el repositorio)
import '../services/hospital_repository.dart'; 

class AdminManagementScreen extends StatefulWidget {
  const AdminManagementScreen({super.key});

  @override
  State<AdminManagementScreen> createState() => _AdminManagementScreenState();
}

class _AdminManagementScreenState extends State<AdminManagementScreen> with SingleTickerProviderStateMixin {
  
  late TabController _tabController;
  
  // --- ESTADO Y REPOSITORIO PARA DIRECTORIO ---
  final HospitalRepository _repository = HospitalRepository(); 
  List<Map<String, dynamic>> _staffList = []; 
  bool _isLoadingStaff = false; 
  // -------------------------------------------

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
  final Color _doctorPrimaryColor = Colors.blue[800]!; 
  final Color _nursePrimaryColor = Colors.cyan[800]!; 
  final Color _directoryColor = Colors.blue; 


  // --- MÉTODO DE CARGA DE DATOS REAL DE DB ---
  Future<void> _loadStaffData() async {
    if (_isLoadingStaff) return; 

    setState(() {
      _isLoadingStaff = true;
      _staffList = []; 
    });
    
    try {
      // Intenta obtener la lista de personal de la DB
      final data = await _repository.getRegisteredStaff(); 
      
      setState(() {
        _staffList = data;
        _isLoadingStaff = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingStaff = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al cargar personal: $e. Verifique la conexión a PostgreSQL y los nombres de columnas.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  // --- MÉTODO AUXILIAR PARA ABREVIAR GÉNERO (FIX para VARCHAR(1)) ---
  String _getGenderAbbreviation(String gender) {
    if (gender.isEmpty) return '';
    // Toma la primera letra en mayúsculas: 'Masculino' -> 'M'
    return gender[0].toUpperCase(); 
  }


  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); 

    _loadStaffData(); 
    
    // Definición de controladores 
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

    _doctorControllers = {...baseControllers, 'especialidad': TextEditingController()};
    _nurseControllers = {...baseControllers, 'area_especializacion': TextEditingController()};
    
    _tabController.addListener(() {
      // Recarga el directorio cuando se selecciona la pestaña 'Directorio'
      if (_tabController.index == 3 && !_isLoadingStaff) { 
        _loadStaffData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _doctorControllers.forEach((key, controller) => controller.dispose());
    _nurseControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // --- MÉTODO _saveUser ACTUALIZADO para guardar en DB ---
  void _saveUser(String role, GlobalKey<FormState> formKey, Map<String, TextEditingController> controllers) async {
    if (formKey.currentState!.validate()) {
      
      // OBTENEMOS EL GÉNERO ABREVIADO
      final String abbreviatedGender = _getGenderAbbreviation(controllers['genero']!.text);

      // 1. Recolectar datos del formulario
      final Map<String, dynamic> userData = {
        'rol': role,
        'nombre': controllers['nombre']!.text,
        'apellido_paterno': controllers['apellido_paterno']!.text,
        'apellido_materno': controllers['apellido_materno']!.text,

        // CAMPOS PERSONALES 
        'curp': controllers['curp']!.text,
        'fecha_nacimiento': controllers['fecha_nacimiento']!.text,
        'genero': abbreviatedGender, // <-- USA LA ABREVIATURA
        'telefono': controllers['telefono']!.text,
        'domicilio': controllers['domicilio']!.text,
        
        // DATOS DE ACCESO
        'email': controllers['email']!.text,
        'password': controllers['password']!.text, 
        'cedula': controllers['cedula']!.text,
        
        // CAMPOS CONDICIONALES/OPCIONALES: Usamos ?.text ?? '' para evitar null
        'firma': controllers['firma']?.text ?? '', 
        'especialidad': controllers['especialidad']?.text ?? '', 
        'area_especializacion': controllers['area_especializacion']?.text ?? '', 
      };
      
      // 2. Intentar guardar en la base de datos
      try {
        await _repository.registrarUsuario(userData);

        // Éxito:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Expediente COMPLETO de $role registrado con éxito: ${userData['email']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 5),
          ),
        );

        // Resetear el formulario 
        formKey.currentState!.reset();
        setState(() {
           controllers['genero']!.text = _generoOpciones.first;
        });
        
        // <--- CORRECCIÓN CLAVE: Esperar a que los datos se recarguen completamente.
        await _loadStaffData(); 

      } catch (e) {
        // Error (ej: conexión fallida, email/cédula duplicada en la DB)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al registrar $role. Posiblemente cédula/email duplicado o fallo de conexión: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    }
  }

  // --- Widget de Gestión de BAJAS (Se mantiene igual) ---
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
    _loadStaffData();
  }


  // --- Widget del Formulario de CREACIÓN (Se mantiene igual) ---
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

  // --- Widget de Directorio de Personal (MUESTRA LA LISTA REAL) ---
  Widget _buildDirectoryScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Directorio de Personal Registrado (${_staffList.length})',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _directoryColor),
          ),
        ),
        
        if (_isLoadingStaff)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_staffList.isEmpty)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 50),
                const Text('No hay Médicos ni Enfermeras registrados en la BD.', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: _loadStaffData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Intentar Recargar Datos'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _directoryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _staffList.length,
              itemBuilder: (context, index) {
                final staff = _staffList[index];
                final isDoctor = staff['rol'] == 'medico';
                final primaryColor = isDoctor ? _doctorPrimaryColor : _nursePrimaryColor;

                return Card(
                  elevation: 1,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: primaryColor,
                      // Muestra la primera letra del nombre
                      child: Text(staff['nombre'] != null && staff['nombre'].isNotEmpty ? staff['nombre'][0] : '?', style: const TextStyle(color: Colors.white)),
                    ),
                    title: Text(
                      staff['nombre'] ?? 'Nombre no disponible',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Rol: ${staff['rol'].toUpperCase()} | Cédula: ${staff['cedula'] ?? 'N/D'}',
                    ),
                    trailing: Icon(
                      isDoctor ? Icons.local_hospital : Icons.medical_services,
                      color: primaryColor,
                    ),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Email: ${staff['email']}')),
                      );
                    },
                  ),
                );
              },
            ),
          ),
      ],
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
        leading: BackButton(
          color: Colors.white,
        ),
        title: const Text('⚙️ Panel de Administración de Usuarios'),
        backgroundColor: _appBarColor, 
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
          _buildUserForm(role: 'Doctor', formKey: _doctorFormKey, controllers: _doctorControllers),
          _buildUserForm(role: 'Enfermera', formKey: _nurseFormKey, controllers: _nurseControllers),
          _buildDeactivationForm(), 
          _buildDirectoryScreen(), 
        ],
      ),
    );
  }
}