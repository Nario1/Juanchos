import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class IdeasDisruptivas {
  /// ⭐ Popup para dejar reseña
  static Future<void> mostrarPopupResena(BuildContext context) async {
    final TextEditingController comentarioController = TextEditingController();
    double estrellas = 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Deja tu reseña ⭐'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Selector de estrellas
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < estrellas ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      estrellas = index + 1;
                    },
                  );
                }),
              ),
              TextField(
                controller: comentarioController,
                decoration: const InputDecoration(
                  hintText: 'Escribe tu comentario...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Enviar'),
              onPressed: () async {
                final user = FirebaseAuth.instance.currentUser;
                if (user != null) {
                  await FirebaseFirestore.instance.collection('reseñas').add({
                    'correo': user.email,
                    'comentario': comentarioController.text.trim(),
                    'estrellas': estrellas,
                    'fecha': FieldValue.serverTimestamp(),
                  });
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Gracias por tu reseña!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  /// 💬 Mensajes emergentes simples
  static void mostrarMensajeEmergente(BuildContext context, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// 🎁 Promoción básica
  static void mostrarPromocion(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🎁 Promoción: ¡Papas gratis con tu próxima compra!'),
        backgroundColor: Colors.purple,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// 🧠 Recordatorio visual
  static void mostrarRecordatorio(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🧠 Consejo'),
        content: const Text(
          'Guarda tus productos favoritos para pedirlos más rápido la próxima vez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  /// 🏆 Sistema de puntos (1 punto por cada S/10 gastado)
  static Future<void> registrarPuntos(double totalCompra) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final puntosGanados = (totalCompra / 10).floor();
    final ref = FirebaseFirestore.instance.collection('usuarios').doc(user.uid);

    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final puntosActuales = (snapshot.data()?['puntos'] ?? 0) as int;
      transaction.update(ref, {'puntos': puntosActuales + puntosGanados});
    });
  }
}
