import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'package:flutter/services.dart';

class ProductoDetalleScreen extends StatelessWidget {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagenUrl;

  const ProductoDetalleScreen({
    super.key,
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    void agregarAlCarrito() {
      cart.agregarProducto(id, nombre, descripcion, precio, imagenUrl);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$nombre agregado al carrito'),
          duration: const Duration(milliseconds: 500),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Ver carrito',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      HapticFeedback.lightImpact();
    }

    return Scaffold(
      appBar: AppBar(title: Text(nombre), backgroundColor: Colors.orange),
      body: Column(
        children: [
          Hero(
            tag: imagenUrl,
            child: imagenUrl.isNotEmpty
                ? Image.network(
                    imagenUrl,
                    width: double.infinity,
                    height: 300,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: double.infinity,
                    height: 300,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, size: 100),
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(descripcion, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    Text(
                      'Precio: S/ ${precio.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: agregarAlCarrito,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Agregar al carrito'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
