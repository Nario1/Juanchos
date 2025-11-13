import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistorialScreen extends StatelessWidget {
  const HistorialScreen({super.key});

  // 🔹 Obtener pedidos según el correo del usuario autenticado
  Stream<QuerySnapshot> _obtenerPedidosUsuario() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final ref = FirebaseFirestore.instance.collection('pedidos');
    return ref.where('correo_usuario', isEqualTo: user.email).snapshots();
  }

  // 🔹 Formatear fecha legible con hora de Perú (UTC-5)
  String _formatearFecha(Timestamp? fecha) {
    if (fecha == null) return '';
    final DateTime datePeru = fecha.toDate().toUtc().subtract(
      const Duration(hours: 5),
    );
    return DateFormat('dd/MM/yyyy hh:mm a').format(datePeru);
  }

  // 🔹 Mostrar fecha y hora actual de Perú
  String _fechaActual() {
    final nowPeru = DateTime.now().toUtc().subtract(const Duration(hours: 5));
    return DateFormat('dd/MM/yyyy hh:mm a').format(nowPeru);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Mis pedidos",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              "Fecha y hora actual: ${_fechaActual()}",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _obtenerPedidosUsuario(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.orange),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No tienes pedidos aún.",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  );
                }

                final pedidos = snapshot.data!.docs;
                pedidos.sort((a, b) {
                  final fa =
                      (a['fecha'] as Timestamp?)?.toDate() ?? DateTime(0);
                  final fb =
                      (b['fecha'] as Timestamp?)?.toDate() ?? DateTime(0);
                  return fb.compareTo(fa);
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: pedidos.length,
                  itemBuilder: (context, index) {
                    final pedido = pedidos[index];
                    final data = pedido.data() as Map<String, dynamic>;

                    final fecha = data["fecha"] as Timestamp?;
                    final total = (data["total"] ?? 0).toDouble();
                    final estado = (data["estado"] ?? "Pendiente").toString();
                    final productos = (data["productos"] ?? []) as List;

                    Color colorEstado;
                    switch (estado.toLowerCase()) {
                      case "entregado":
                        colorEstado = Colors.greenAccent;
                        break;
                      case "cancelado":
                        colorEstado = Colors.redAccent;
                        break;
                      default:
                        colorEstado = Colors.orangeAccent;
                    }

                    return Card(
                      color: Colors.grey[900],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: ExpansionTile(
                          collapsedIconColor: Colors.white,
                          iconColor: Colors.orange,
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Pedido #${index + 1}",
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "S/ ${total.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Estado: $estado",
                                style: TextStyle(
                                  color: colorEstado,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatearFecha(fecha),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          children: [
                            const Divider(color: Colors.orange),
                            ...productos.map((prod) {
                              final nombre = prod["nombre"] ?? "";
                              final cantidad = prod["cantidad"] ?? 1;
                              final subtotal = (prod["subtotal"] ?? 0)
                                  .toDouble();
                              final descripcion =
                                  prod["descripcion"] ?? ""; // 🔹 Ingredientes

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            "$nombre (x$cantidad)",
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          "S/ ${subtotal.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (descripcion.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4,
                                          top: 2,
                                        ),
                                        child: Text(
                                          descripcion,
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
