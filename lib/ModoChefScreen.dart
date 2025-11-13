import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';

class ChefScreen extends StatefulWidget {
  const ChefScreen({super.key});

  @override
  State<ChefScreen> createState() => _ChefScreenState();
}

class _ChefScreenState extends State<ChefScreen> {
  int _step = 0;

  // Base y categorías de ingredientes
  String? _base;
  final List<String> bases = ['Hamburguesa', 'Salchipapa', 'Hot Dog'];
  final Map<String, bool> proteinas = {
    'Jamon': false,
    'Carne': false,
    'Pollo': false,
    'Salchicha': false,
  };
  final Map<String, bool> vegetales = {
    'Lechuga': false,
    'Tomate': false,
    'Cebolla': false,
  };
  final Map<String, bool> extras = {
    'Queso': false,
    'Papitas': false,
    'Salsa Especial': false,
  };

  final Map<String, double> precios = {
    'Hamburguesa': 10,
    'Salchipapa': 12,
    'Hot Dog': 8,
    'Jamon': 3,
    'Carne': 4,
    'Pollo': 3.5,
    'Salchicha': 2.5,
    'Lechuga': 1,
    'Tomate': 1,
    'Cebolla': 0.5,
    'Queso': 2,
    'Papitas': 1.5,
    'Salsa Especial': 1,
  };

  double get precioTotal {
    double total = 0;
    if (_base != null) total += precios[_base!]!;
    proteinas.forEach((k, v) {
      if (v) total += precios[k]!;
    });
    vegetales.forEach((k, v) {
      if (v) total += precios[k]!;
    });
    extras.forEach((k, v) {
      if (v) total += precios[k]!;
    });
    return total;
  }

  bool _puedeAvanzar() {
    switch (_step) {
      case 0:
        return _base != null;
      case 1:
        return proteinas.values.any((v) => v);
      case 2:
        return vegetales.values.any((v) => v);
      case 3:
        return extras.values.any((v) => v);
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          Expanded(child: _buildStep()),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => setState(() => _step--),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 5,
                        ),
                        child: const Text(
                          'Anterior',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _puedeAvanzar()
                          ? (_step < 4
                                ? () => setState(() => _step++)
                                : () => _agregarAlCarrito(cart))
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        _step < 4 ? 'Siguiente' : 'Agregar al carrito',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Precio actual: S/ ${precioTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return ListView(
          padding: const EdgeInsets.all(12),
          children: bases.map((b) {
            return RadioListTile<String>(
              title: Text(b),
              value: b,
              groupValue: _base,
              onChanged: (val) => setState(() => _base = val),
            );
          }).toList(),
        );
      case 1:
        return _buildCheckboxList('Proteínas', proteinas);
      case 2:
        return _buildCheckboxList('Vegetales', vegetales);
      case 3:
        return _buildCheckboxList('Extras', extras);
      case 4:
        return _buildResumen();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCheckboxList(String titulo, Map<String, bool> items) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.keys.map((key) {
          return CheckboxListTile(
            title: Text('$key (S/ ${precios[key]})'),
            value: items[key],
            onChanged: (val) => setState(() => items[key] = val ?? false),
          );
        }),
      ],
    );
  }

  Widget _buildResumen() {
    List<String> seleccionados = [];
    if (_base != null) seleccionados.add(_base!);
    seleccionados.addAll(
      proteinas.entries.where((e) => e.value).map((e) => e.key),
    );
    seleccionados.addAll(
      vegetales.entries.where((e) => e.value).map((e) => e.key),
    );
    seleccionados.addAll(
      extras.entries.where((e) => e.value).map((e) => e.key),
    );

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de tu plato:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...seleccionados.map(
            (s) => Text(s, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 12),
          Text(
            'Precio total: S/ ${precioTotal.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            color: Colors.grey[300],
            child: const Center(
              child: Text(
                'Vista previa del plato',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _agregarAlCarrito(CartProvider cart) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    List<String> seleccionados = [];
    if (_base != null) seleccionados.add(_base!);
    seleccionados.addAll(
      proteinas.entries.where((e) => e.value).map((e) => e.key),
    );
    seleccionados.addAll(
      vegetales.entries.where((e) => e.value).map((e) => e.key),
    );
    seleccionados.addAll(
      extras.entries.where((e) => e.value).map((e) => e.key),
    );

    final nombre = 'Plato Chef: ${_base ?? ""}';
    final descripcion = seleccionados.join(', ');

    cart.agregarProducto(id, nombre, descripcion, precioTotal, '');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Plato agregado al carrito'),
        backgroundColor: Colors.green,
      ),
    );

    // Resetear selección
    setState(() {
      _step = 0;
      _base = null;
      proteinas.updateAll((key, value) => false);
      vegetales.updateAll((key, value) => false);
      extras.updateAll((key, value) => false);
    });
  }
}
