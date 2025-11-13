import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'ProductoDetalleScreen.dart'; // ✅ Importamos la pantalla de detalle
import 'package:flutter/services.dart'; // Para HapticFeedback
import 'package:shimmer/shimmer.dart'; // Para efecto shimmer
import 'recommendations_service.dart'; // ✅ Servicio de recomendaciones

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  String _categoriaSeleccionada = 'Todos';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categorias = [
    {'nombre': 'Todos', 'icono': Icons.grid_view},
    {'nombre': 'Salchipapas', 'icono': FontAwesomeIcons.bowlRice},
    {'nombre': 'Hamburguesas', 'icono': FontAwesomeIcons.burger},
    {'nombre': 'Alitas', 'icono': FontAwesomeIcons.drumstickBite},
    {'nombre': 'Broaster', 'icono': FontAwesomeIcons.bowlFood},
    {'nombre': 'Parrillas', 'icono': FontAwesomeIcons.fire},
    {'nombre': 'Bebidas', 'icono': FontAwesomeIcons.wineGlass},
    {'nombre': 'Adicionales', 'icono': FontAwesomeIcons.plus},
  ];

  final AuthService _authService = AuthService();
  final RecommendationsService _recommendationsService = RecommendationsService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cerrarSesion() async {
    await _authService.cerrarSesion();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sesión cerrada correctamente'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase().trim();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          // ✅ Sección de productos recomendados (solo si no hay búsqueda activa)
          if (_searchQuery.isEmpty) _SeccionRecomendados(),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categorias.length,
              itemBuilder: (context, index) {
                final categoria = _categorias[index];
                final isSelected =
                    _categoriaSeleccionada == categoria['nombre'];

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    selected: isSelected,
                    label: Row(
                      children: [
                        Icon(
                          categoria['icono'],
                          size: 18,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(categoria['nombre']),
                      ],
                    ),
                    selectedColor: Colors.orange,
                    backgroundColor: Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[700],
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                    onSelected: (bool selected) {
                      setState(() {
                        _categoriaSeleccionada = categoria['nombre'];
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _categoriaSeleccionada == 'Todos'
                  ? FirebaseFirestore.instance
                        .collection('productos')
                        .snapshots()
                  : FirebaseFirestore.instance
                        .collection('productos')
                        .where('k_cate', isEqualTo: _categoriaSeleccionada)
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay productos disponibles',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final productos = snapshot.data!.docs;

                final productosFiltrados = _searchQuery.isEmpty
                    ? productos
                    : productos.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final categoria = (data['k_cate'] ?? '')
                            .toString()
                            .toLowerCase();
                        final nombre = (data['l_nomb'] ?? '')
                            .toString()
                            .toLowerCase();
                        final descripcion = (data['l_desc'] ?? '')
                            .toString()
                            .toLowerCase();

                        return categoria.contains(_searchQuery) ||
                            nombre.contains(_searchQuery) ||
                            descripcion.contains(_searchQuery);
                      }).toList();

                if (productosFiltrados.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No se encontraron productos',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Intenta con otra búsqueda',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: productosFiltrados.length,
                  itemBuilder: (context, index) {
                    final producto =
                        productosFiltrados[index].data()
                            as Map<String, dynamic>;
                    final productoId = productosFiltrados[index].id;

                    return _ProductoCard(
                      id: productoId, // ✅ Pasamos el id
                      nombre: producto['l_nomb'] ?? 'Sin nombre',
                      descripcion: producto['l_desc'] ?? 'Sin descripción',
                      precio: (producto['s_prec'] ?? 0.0).toDouble(),
                      imagenUrl: producto['l_imag'] ?? '',
                      onAgregarCarrito: () {
                        _agregarAlCarrito(producto, productoId);
                      },
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

  void _agregarAlCarrito(Map<String, dynamic> producto, String id) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    cart.agregarProducto(
      id,
      producto['l_nomb'] ?? 'Sin nombre',
      producto['l_desc'] ?? 'Sin descripción',
      (producto['s_prec'] ?? 0.0).toDouble(),
      producto['l_imag'] ?? '',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${producto['l_nomb']} agregado al carrito'),
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
}

// ✅ Widget para la sección de productos recomendados
class _SeccionRecomendados extends StatelessWidget {
  final RecommendationsService _recommendationsService = RecommendationsService();

  _SeccionRecomendados({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: _recommendationsService.obtenerStreamProductosRecomendados(limit: 5),
      builder: (context, snapshot) {
        // Si está cargando, mostrar un indicador pequeño o nada
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }

        // Si hay error o no hay datos, no mostrar nada
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final productosRecomendados = snapshot.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.recommend,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Recomendados para ti',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Basado en tus compras',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: productosRecomendados.length,
                itemBuilder: (context, index) {
                  final productoDoc = productosRecomendados[index];
                  final producto = productoDoc.data() as Map<String, dynamic>;
                  final productoId = productoDoc.id;

                  return _ProductoRecomendadoCard(
                    id: productoId,
                    nombre: producto['l_nomb'] ?? 'Sin nombre',
                    descripcion: producto['l_desc'] ?? 'Sin descripción',
                    precio: (producto['s_prec'] ?? 0.0).toDouble(),
                    imagenUrl: producto['l_imag'] ?? '',
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ✅ Widget para la tarjeta de producto recomendado (formato horizontal)
class _ProductoRecomendadoCard extends StatelessWidget {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagenUrl;

  const _ProductoRecomendadoCard({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenUrl,
  });

  void _abrirDetalle(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductoDetalleScreen(
          id: id,
          nombre: nombre,
          descripcion: descripcion,
          precio: precio,
          imagenUrl: imagenUrl,
        ),
      ),
    );
  }

  void _agregarAlCarrito(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    cart.agregarProducto(
      id,
      nombre,
      descripcion,
      precio,
      imagenUrl,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$nombre agregado al carrito'),
        duration: const Duration(milliseconds: 500),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _abrirDetalle(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge de "Recomendado"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Recomendado',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            // Imagen del producto
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: imagenUrl.isNotEmpty
                  ? Image.network(
                      imagenUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image_not_supported,
                            size: 30,
                            color: Colors.grey[500],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 100,
                            width: double.infinity,
                            color: Colors.grey[300],
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 100,
                      color: Colors.grey[300],
                      child: Icon(
                        Icons.image,
                        size: 30,
                        color: Colors.grey[500],
                      ),
                    ),
            ),
            // Información del producto
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey[600],
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'S/ ${precio.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _agregarAlCarrito(context),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.add_shopping_cart,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductoCard extends StatefulWidget {
  final String id; // ✅ id del producto
  final String nombre;
  final String descripcion;
  final double precio;
  final String imagenUrl;
  final VoidCallback onAgregarCarrito;

  const _ProductoCard({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.imagenUrl,
    required this.onAgregarCarrito,
  });

  @override
  State<_ProductoCard> createState() => _ProductoCardState();
}

class _ProductoCardState extends State<_ProductoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapAgregar() {
    _controller.forward().then((_) => _controller.reverse());
    widget.onAgregarCarrito();
  }

  void _abrirDetalle() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductoDetalleScreen(
          id: widget.id,
          nombre: widget.nombre,
          descripcion: widget.descripcion,
          precio: widget.precio,
          imagenUrl: widget.imagenUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        elevation: _isPressed ? 8 : 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _abrirDetalle, // ✅ Abrimos detalle al tocar la tarjeta
          onHighlightChanged: (pressed) {
            setState(() {
              _isPressed = pressed;
            });
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: widget.imagenUrl, // ✅ Hero para animación
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: widget.imagenUrl.isNotEmpty
                      ? Image.network(
                          widget.imagenUrl,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 140,
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image_not_supported,
                                size: 50,
                                color: Colors.grey[500],
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Shimmer.fromColors(
                              baseColor: Colors.grey[300]!,
                              highlightColor: Colors.grey[100]!,
                              child: Container(
                                height: 140,
                                width: double.infinity,
                                color: Colors.grey[300],
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 140,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.image,
                            size: 50,
                            color: Colors.grey[500],
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.nombre,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.descripcion,
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'S/ ${widget.precio.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          SizedBox(
                            height: 26,
                            width: 50,
                            child: ElevatedButton(
                              onPressed: _onTapAgregar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
