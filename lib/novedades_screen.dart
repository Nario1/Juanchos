import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'cart_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'auth_service.dart'; // 🔹 Import AuthService
import 'login_screen.dart'; // 🔹 Import LoginScreen

class NovedadesScreen extends StatefulWidget {
  const NovedadesScreen({super.key});

  @override
  State<NovedadesScreen> createState() => _NovedadesScreenState();
}

class _NovedadesScreenState extends State<NovedadesScreen> {
  final List<Map<String, String>> _banners = [
    {
      'imagen': 'https://i.ibb.co/0yMSdNzW/parrilla.jpg',
      'titulo': '¡Nuevos Sabores!',
      'subtitulo': '¡Descubre Nuevos Sabores!',
    },
    {
      'imagen': 'https://i.ibb.co/vxqg0yWq/broaster.jpg',
      'titulo': '¡Promo Universitario!',
      'subtitulo': '¡Gaseosa Personal!',
    },
    {
      'imagen': 'https://i.ibb.co/bRsJDQw9/salchipapa.jpg',
      'titulo': '¡Delivery!',
      'subtitulo': '¡Sin Costos Adicionales!',
    },
  ];

  final AuthService _authService = AuthService();

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner carrusel
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: _BannerCarousel(banners: _banners),
            ),

            const SizedBox(height: 24),

            // Productos destacados
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Productos Destacados',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            const _ProductosDestacadosSection(),

            const SizedBox(height: 24),

            // Sección de categorías populares
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.orange, size: 28),
                  const SizedBox(width: 8),
                  const Text(
                    'Categorías Populares',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _buildCategoriasPopulares(),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriasPopulares() {
    final categorias = [
      {
        'nombre': 'Alitas',
        'icono': FontAwesomeIcons.drumstickBite,
        'color': Colors.orange,
      },
      {
        'nombre': 'Burguers',
        'icono': FontAwesomeIcons.burger,
        'color': Colors.red,
      },
      {
        'nombre': 'Parrillas',
        'icono': FontAwesomeIcons.fire,
        'color': Colors.deepOrange,
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          final categoria = categorias[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: (categoria['color'] as Color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (categoria['color'] as Color).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  categoria['icono'] as IconData,
                  size: 40,
                  color: categoria['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  categoria['nombre'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: categoria['color'] as Color,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Widget separado para el carrusel - Carrusel infinito
class _BannerCarousel extends StatefulWidget {
  final List<Map<String, String>> banners;

  const _BannerCarousel({required this.banners});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1000);
    _currentPage = 1000;
    _iniciarAutoScroll();
  }

  void _iniciarAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (mounted) {
                setState(() {
                  _currentPage = index;
                });
              }
            },
            itemBuilder: (context, index) {
              final actualIndex = index % widget.banners.length;
              final banner = widget.banners[actualIndex];

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.orange.shade400,
                      Colors.deepOrange.shade600,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        banner['imagen']!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.orange.shade300);
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            banner['titulo']!,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            banner['subtitulo']!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 12,
            right: 16,
            child: Row(
              children: List.generate(widget.banners.length, (index) {
                final actualIndex = _currentPage % widget.banners.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: actualIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: actualIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget separado para productos destacados que mantiene su estado
class _ProductosDestacadosSection extends StatefulWidget {
  const _ProductosDestacadosSection();

  @override
  State<_ProductosDestacadosSection> createState() =>
      _ProductosDestacadosSectionState();
}

class _ProductosDestacadosSectionState
    extends State<_ProductosDestacadosSection>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('productos').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.star_border, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No hay productos destacados',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega el campo "destacado: true" (boolean) en Firebase',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final productosDestacados = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['destacado'] == true;
        }).toList();

        if (productosDestacados.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.star_border, size: 60, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    'No hay productos destacados',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'En Firebase, cambia "destacado" de String a Boolean (true)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 240,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: productosDestacados.length,
            itemBuilder: (context, index) {
              final producto =
                  productosDestacados[index].data() as Map<String, dynamic>;
              final productoId = productosDestacados[index].id;

              return _ProductoDestacadoCard(
                producto: producto,
                productoId: productoId,
              );
            },
          ),
        );
      },
    );
  }
}

class _ProductoDestacadoCard extends StatelessWidget {
  final Map<String, dynamic> producto;
  final String productoId;

  const _ProductoDestacadoCard({
    required this.producto,
    required this.productoId,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: Image.network(
                    producto['l_imag'] ?? '',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 120,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image_not_supported, size: 40),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.star, size: 12, color: Colors.white),
                        SizedBox(width: 2),
                        Text(
                          'Destacado',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      producto['l_nomb'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'S/ ${(producto['s_prec'] ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(
                          height: 28,
                          width: 28,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              cart.agregarProducto(
                                productoId,
                                producto['l_nomb'] ?? 'Sin nombre',
                                producto['l_desc'] ?? '',
                                (producto['s_prec'] ?? 0.0).toDouble(),
                                producto['l_imag'] ?? '',
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${producto['l_nomb']} agregado',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_shopping_cart, size: 18),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
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
