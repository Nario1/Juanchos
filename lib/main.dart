import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

// 🔸 Importaciones de tus pantallas
import 'cart_provider.dart';
import 'productos_screen.dart';
import 'novedades_screen.dart';
import 'carrito_screen.dart';
import 'login_screen.dart';
import 'auth_service.dart';
import 'geolocalizacion_screen.dart'; // 🗺️ NUEVA PANTALLA
import 'ModoChefScreen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Juanchos',
        theme: ThemeData(
          primarySwatch: Colors.orange,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

// ✅ Verifica si hay sesión activa
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        if (snapshot.hasData) {
          return const MainNavigation();
        }

        return const LoginScreen();
      },
    );
  }
}

// 🧭 Navegación principal con 4 pestañas
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const ProductosScreen(),
    const NovedadesScreen(),
    const CarritoScreen(),
    const GeolocalizacionScreen(),
    const ChefScreen(), // 🧑‍🍳 NUEVA PANTALLA DE MODO CHEF
  ];

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: Colors.orange,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Productos',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Novedades',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('${cart.totalCantidad}'),
              isLabelVisible: cart.totalCantidad > 0,
              child: const Icon(Icons.shopping_cart),
            ),
            label: 'Carrito',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Ubicación',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: 'Modo Chef', // 🧑‍🍳 NUEVA PESTAÑA
          ),
        ],
      ),
    );
  }
}
