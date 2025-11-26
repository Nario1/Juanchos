import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/custom_app_bar.dart';
import 'perfil_screen.dart';

// 🔸 Importaciones de tus pantallas y providers
import 'cart_provider.dart';
import 'productos_screen.dart';
import 'novedades_screen.dart';
import 'carrito_screen.dart';
import 'login_screen.dart';
import 'geolocalizacion_screen.dart';
import 'ModoChefScreen.dart';
import 'widgets/logo_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Timer? _inactivityTimer;
  DateTime? _lastInteraction;

  // 🔹 INICIA EL TIMER DE 5 MINUTOS
  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(const Duration(minutes: 5), () {
      final now = DateTime.now();
      if (_lastInteraction != null &&
          now.difference(_lastInteraction!).inMinutes >= 5) {
        print('🔴 CERRANDO SESIÓN POR INACTIVIDAD - 5 minutos');
        FirebaseAuth.instance.signOut();
      }
    });
  }

  // 🔹 REINICIA EL TIMER AL INTERACTUAR
  void _resetInactivityTimer() {
    if (!mounted) return;
    _lastInteraction = DateTime.now();
    _startInactivityTimer();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastInteraction = DateTime.now();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _inactivityTimer?.cancel();
    super.dispose();
  }

  // 🔥🔥🔥 CORREGIDO: YA NO SE CIERRA SESIÓN AL ABRIR LA CÁMARA 🔥🔥🔥
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // Ya NO cerramos sesión aquí
      _inactivityTimer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _lastInteraction = DateTime.now();
      _startInactivityTimer();
    }
  }

  // 🔹 WIDGET QUE CAPTURA INTERACCIONES EN TODA LA APP
  Widget _buildInteractionDetector(Widget child) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      onPointerUp: (_) => _resetInactivityTimer(),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _resetInactivityTimer,
        onPanDown: (_) => _resetInactivityTimer(),
        onPanUpdate: (_) => _resetInactivityTimer(),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildInteractionDetector(
      ChangeNotifierProvider(
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
          home: const SplashScreen(),
        ),
      ),
    );
  }
}

// 🟠 SPLASH SCREEN INTEGRADO EN MAIN.DART
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
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
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: const LogoWidget(size: 150),
            ),
            const SizedBox(height: 20),
            const Text(
              "Bienvenido a Juanchos",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// 🧭 Navegación principal
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
    const ChefScreen(),
    const PerfilScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: CustomAppBar(
        onLogoutPressed: () async {
          await FirebaseAuth.instance.signOut();
        },
      ),
      body: _screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _resetAppTimer();
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
            label: 'Modo Chef',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  // 🔹 MÉTODO PARA REINICIAR TIMER DESDE MainNavigation
  void _resetAppTimer() {
    final myAppState = context.findAncestorStateOfType<_MyAppState>();
    myAppState?._resetInactivityTimer();
  }
}

// 🔹 EXTENSIÓN PARA ACCEDER AL MÉTODO DESDE MainNavigation
extension on _MyAppState {
  void _resetInactivityTimer() {
    _resetInactivityTimer();
  }
}
