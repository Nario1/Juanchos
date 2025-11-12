import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Stream de cambios de autenticación
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Verificar si hay sesión guardada
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Guardar estado de sesión
  Future<void> _saveLoginState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', state);
  }

  // Registrar usuario
  Future<Map<String, dynamic>> registrarUsuario({
    required String email,
    required String password,
    required String nombre,
    required String telefono,
  }) async {
    try {
      // Crear usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Guardar datos adicionales en Firestore
      await _firestore.collection('usuarios').doc(userCredential.user!.uid).set({
        'nombre': nombre,
        'email': email,
        'telefono': telefono,
        'fecha_registro': FieldValue.serverTimestamp(),
      });

      // Actualizar displayName
      await userCredential.user!.updateDisplayName(nombre);

      await _saveLoginState(true);

      return {
        'success': true,
        'message': 'Usuario registrado exitosamente',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Error al registrar usuario';
      
      switch (e.code) {
        case 'weak-password':
          message = 'La contraseña es muy débil';
          break;
        case 'email-already-in-use':
          message = 'El correo ya está registrado';
          break;
        case 'invalid-email':
          message = 'El correo no es válido';
          break;
      }

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Iniciar sesión
  Future<Map<String, dynamic>> iniciarSesion({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveLoginState(true);

      return {
        'success': true,
        'message': 'Sesión iniciada correctamente',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Error al iniciar sesión';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'Usuario no encontrado';
          break;
        case 'wrong-password':
          message = 'Contraseña incorrecta';
          break;
        case 'invalid-email':
          message = 'Correo no válido';
          break;
        case 'user-disabled':
          message = 'Usuario deshabilitado';
          break;
        case 'invalid-credential':
          message = 'Credenciales inválidas';
          break;
      }

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
    await _saveLoginState(false);
  }

  // Obtener datos del usuario
  Future<Map<String, dynamic>?> obtenerDatosUsuario() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // Restablecer contraseña
  Future<Map<String, dynamic>> restablecerPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Correo de recuperación enviado',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Error al enviar correo';
      
      if (e.code == 'user-not-found') {
        message = 'Usuario no encontrado';
      } else if (e.code == 'invalid-email') {
        message = 'Correo no válido';
      }

      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: $e',
      };
    }
  }
}