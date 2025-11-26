import 'package:flutter/material.dart';
import '../historial_screen.dart'; // 👈 Import corregido (afuera de la carpeta widgets)

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onLogoutPressed;

  const CustomAppBar({super.key, this.onLogoutPressed});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.orange,
      title: const Text(
        'Juanchos',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      leading: const Padding(
        padding: EdgeInsets.only(left: 8.0),
        child: Image(image: AssetImage('assets/icono_app.png'), height: 40),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.history),
          tooltip: 'Historial de pedidos',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistorialScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'Cerrar sesión',
          onPressed: onLogoutPressed,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
