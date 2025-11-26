import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  final ImagePicker _picker = ImagePicker();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController direccionController = TextEditingController();

  bool _editando = false;
  bool _subiendoImagen = false;
  bool _guardandoDatos = false;

  @override
  void dispose() {
    nombreController.dispose();
    telefonoController.dispose();
    direccionController.dispose();
    super.dispose();
  }

  // ============================================================
  // 📌 PERMISOS DE CÁMARA Y GALERÍA
  // ============================================================

  Future<bool> _pedirPermisoCamara() async {
    var status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  Future<bool> _pedirPermisoGaleria() async {
    // Android 13+ usa READ_MEDIA_IMAGES
    var status = await Permission.photos.status;

    if (status.isDenied) {
      status = await Permission.photos.request();
    }

    if (status.isPermanentlyDenied) {
      openAppSettings();
      return false;
    }

    return status.isGranted;
  }

  // ============================================================
  // 📌 BOTTOM SHEET – SELECCIÓN DE MÉTODO
  // ============================================================
  void _mostrarOpcionesImagen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                "Cambiar foto de perfil",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              // 📌 GALERÍA
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.orange),
                title: const Text("Elegir desde galería"),
                onTap: () async {
                  Navigator.pop(context);

                  bool permiso = await _pedirPermisoGaleria();
                  if (!permiso) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Permiso de galería denegado o bloqueado",
                        ),
                      ),
                    );
                    return;
                  }

                  _seleccionarImagen(ImageSource.gallery);
                },
              ),

              // 📌 CÁMARA
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.orange),
                title: const Text("Tomar una foto"),
                onTap: () async {
                  Navigator.pop(context);

                  bool permiso = await _pedirPermisoCamara();
                  if (!permiso) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Permiso de cámara denegado o bloqueado"),
                      ),
                    );
                    return;
                  }

                  _seleccionarImagen(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 📌 SUBIR FOTO A IMGBB CON LOADER
  // ============================================================
  Future<void> _seleccionarImagen(ImageSource source) async {
    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    if (!mounted) return;
    setState(() => _subiendoImagen = true);

    File imagen = File(pickedFile.path);
    final url = await _subirImagenAImgbb(imagen);

    if (url != null) {
      await _guardarFotoEnFirestore(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto de perfil actualizada")),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error al subir la imagen")),
        );
      }
    }

    if (!mounted) return;
    setState(() => _subiendoImagen = false);
  }

  Future<String?> _subirImagenAImgbb(File imagen) async {
    const String apiKey = "77986ad806fe01ad301463ea8241b360";

    final uri = Uri.parse("https://api.imgbb.com/1/upload?key=$apiKey");

    try {
      final request = http.MultipartRequest("POST", uri);
      request.files.add(
        await http.MultipartFile.fromPath("image", imagen.path),
      );

      final response = await request.send();
      final body = await response.stream.bytesToString();
      final json = jsonDecode(body);

      if (json["status"] == 200) {
        return json["data"]["url"];
      }
    } catch (e) {
      print("Error subiendo imagen: $e");
    }
    return null;
  }

  // ============================================================
  // 📌 GUARDAR EN FIRESTORE
  // ============================================================
  Future<void> _guardarFotoEnFirestore(String url) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = FirebaseFirestore.instance
        .collection("perfil_usuarios")
        .doc(user.uid);

    await doc.set({
      "fotoPerfil": url,
      "fechaActualizacion": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _guardarDatos() async {
    if (!mounted) return;
    setState(() => _guardandoDatos = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = FirebaseFirestore.instance
        .collection("perfil_usuarios")
        .doc(user.uid);

    await doc.set({
      "nombre": nombreController.text.trim(),
      "telefono": telefonoController.text.trim(),
      "direccion": direccionController.text.trim(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    setState(() {
      _editando = false;
      _guardandoDatos = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Datos actualizados")));
  }

  // ============================================================
  // 📌 INTERFAZ DE USUARIO
  // ============================================================
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Inicia sesión primero")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Mi Perfil",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.orange,
      ),

      floatingActionButton: _editando
          ? FloatingActionButton.extended(
              backgroundColor: Colors.orange,
              label: _guardandoDatos
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Guardar cambios"),
              onPressed: !_guardandoDatos ? _guardarDatos : null,
            )
          : null,

      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection("perfil_usuarios")
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!.data() ?? {};

          final fotoPerfil =
              data["fotoPerfil"] ??
              "https://cdn-icons-png.flaticon.com/512/149/149071.png";

          nombreController.text = data["nombre"] ?? "";
          telefonoController.text = data["telefono"] ?? "";
          direccionController.text = data["direccion"] ?? "";
          final correo = user.email ?? "";

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOut,
                      height: 140,
                      width: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange, width: 3),
                      ),
                      child: ClipOval(
                        child: _subiendoImagen
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.orange,
                                ),
                              )
                            : Image.network(fotoPerfil, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => _mostrarOpcionesImagen(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              Card(
                elevation: 5,
                shadowColor: Colors.orange.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      _campoEditable("Nombre completo", nombreController),
                      const SizedBox(height: 15),
                      _campoEditable(
                        "Teléfono",
                        telefonoController,
                        teclado: TextInputType.phone,
                      ),
                      const SizedBox(height: 15),
                      _campoEditable("Dirección", direccionController),
                      const SizedBox(height: 15),
                      _campoSoloLectura("Correo", correo),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          );
        },
      ),

      bottomNavigationBar: (!_editando)
          ? Container(
              padding: const EdgeInsets.all(15),
              color: Colors.white,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.edit, color: Colors.white),
                label: const Text(
                  "Editar información",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                onPressed: () => setState(() => _editando = true),
              ),
            )
          : null,
    );
  }

  // ============================================================
  // 📌 WIDGETS PROFESIONALES
  // ============================================================
  Widget _campoEditable(
    String label,
    TextEditingController controller, {
    TextInputType teclado = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      enabled: _editando,
      keyboardType: teclado,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _campoSoloLectura(String label, String valor) {
    return TextField(
      enabled: false,
      controller: TextEditingController(text: valor),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
