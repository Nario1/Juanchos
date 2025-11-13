import 'package:flutter/material.dart';
import 'auth_service.dart';
import 'main.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  double _progress = 0.0;

  final Map<String, bool> _touched = {
    'nombre': false,
    'email': false,
    'telefono': false,
    'password': false,
    'confirm': false,
  };

  @override
  void initState() {
    super.initState();
    _nombreController.addListener(_updateProgress);
    _emailController.addListener(_updateProgress);
    _telefonoController.addListener(_updateProgress);
    _passwordController.addListener(_updateProgress);
    _confirmPasswordController.addListener(_updateProgress);
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    if (!mounted) return;
    double p = 0;

    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final telefono = _telefonoController.text.trim();
    final pass = _passwordController.text.trim();
    final confirm = _confirmPasswordController.text.trim();

    final nombreOk = RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]{3,}$').hasMatch(nombre);
    final emailOk = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
    final telefonoOk = RegExp(r'^[0-9]{9}$').hasMatch(telefono);
    final passOk = pass.length >= 6;
    final confirmOk = confirm == pass && confirm.isNotEmpty;

    if (nombreOk) p += 0.2;
    if (emailOk) p += 0.2;
    if (telefonoOk) p += 0.2;
    if (passOk) p += 0.2;
    if (confirmOk) p += 0.2;

    setState(() => _progress = p.clamp(0, 1));
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await _authService.registrarUsuario(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
      nombre: _nombreController.text.trim(),
      telefono: _telefonoController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crear Cuenta'), centerTitle: true),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add,
                      size: 50,
                      color: Colors.orange,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                LinearProgressIndicator(
                  value: _progress,
                  color: Colors.orange,
                  backgroundColor: Colors.orange.shade100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(10),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Text(
                    'Progreso: ${(100 * _progress).toInt()}%',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                _buildFieldWithError(
                  keyName: 'nombre',
                  controller: _nombreController,
                  label: 'Nombre completo',
                  icon: Icons.person,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu nombre';
                    if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ ]+$').hasMatch(v)) {
                      return 'Solo se permiten letras';
                    }
                    if (v.length < 3) return 'Nombre muy corto';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                _buildFieldWithError(
                  keyName: 'email',
                  controller: _emailController,
                  label: 'Correo electrónico',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu correo';
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                      return 'Correo no válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                _buildFieldWithError(
                  keyName: 'telefono',
                  controller: _telefonoController,
                  label: 'Teléfono (9 dígitos)',
                  icon: Icons.phone,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu teléfono';
                    if (!RegExp(r'^[0-9]+$').hasMatch(v)) {
                      return 'Solo números permitidos';
                    }
                    if (v.length != 9) return 'Debe tener 9 dígitos';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                _buildPasswordWithError(
                  keyName: 'password',
                  controller: _passwordController,
                  label: 'Contraseña',
                  obscure: _obscurePassword,
                  toggle: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                    if (v.length < 6) return 'Mínimo 6 caracteres';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                _buildPasswordWithError(
                  keyName: 'confirm',
                  controller: _confirmPasswordController,
                  label: 'Confirmar contraseña',
                  obscure: _obscureConfirmPassword,
                  toggle: () => setState(
                    () => _obscureConfirmPassword = !_obscureConfirmPassword,
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                    if (v != _passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                        : const Text(
                            'Registrarme',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '¿Ya tienes cuenta?',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: const Text(
                        'Iniciar Sesión',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldWithError({
    required String keyName,
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    String? errorText;
    if (_touched[keyName]!) {
      errorText = validator?.call(controller.text);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) _touched[keyName] = true;
            setState(() {});
          },
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: (_) => setState(_updateProgress),
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: Icon(icon, color: Colors.orange),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPasswordWithError({
    required String keyName,
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback toggle,
    String? Function(String?)? validator,
  }) {
    String? errorText;
    if (_touched[keyName]!) {
      errorText = validator?.call(controller.text);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: (hasFocus) {
            if (hasFocus) _touched[keyName] = true;
            setState(() {});
          },
          child: TextFormField(
            controller: controller,
            obscureText: obscure,
            onChanged: (_) => setState(_updateProgress),
            decoration: InputDecoration(
              labelText: label,
              prefixIcon: const Icon(Icons.lock, color: Colors.orange),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: toggle,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.orange, width: 2),
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
