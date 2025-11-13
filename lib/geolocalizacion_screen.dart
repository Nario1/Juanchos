// geolocalizacion_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

class GeolocalizacionScreen extends StatefulWidget {
  const GeolocalizacionScreen({super.key});

  @override
  State<GeolocalizacionScreen> createState() => _GeolocalizacionScreenState();
}

class _GeolocalizacionScreenState extends State<GeolocalizacionScreen> {
  GoogleMapController? mapController;
  LatLng? ubicacionUsuario;
  LatLng? ubicacionTienda;
  Set<Marker> marcadores = {};
  Set<Polyline> polylines = {};

  // 🔑 Agrega esta variable para controlar el estado del widget
  bool _isMounted = false;

  final String apiKey = 'AIzaSyBIZrptkE0IGakPhzMzMpq4PaW_gw_D1vk';

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _obtenerUbicacionUsuario();
    _obtenerUbicacionTienda();
  }

  @override
  void dispose() {
    _isMounted = false; // 🔑 Marcar como no montado al destruir
    super.dispose();
  }

  // 🔑 Método seguro para llamar setState()
  void _safeSetState(VoidCallback callback) {
    if (_isMounted) {
      setState(callback);
    }
  }

  // Obtener ubicación del usuario
  Future<void> _obtenerUbicacionUsuario() async {
    try {
      bool servicioHabilitado = await Geolocator.isLocationServiceEnabled();
      if (!servicioHabilitado) return;

      LocationPermission permiso = await Geolocator.checkPermission();
      if (permiso == LocationPermission.denied) {
        permiso = await Geolocator.requestPermission();
        if (permiso == LocationPermission.denied) return;
      }
      if (permiso == LocationPermission.deniedForever) return;

      Position posicion = await Geolocator.getCurrentPosition();
      
      // 🔑 Verificar si el widget sigue montado antes de actualizar
      if (!_isMounted) return;
      
      _safeSetState(() {
        ubicacionUsuario = LatLng(posicion.latitude, posicion.longitude);
        _agregarMarcadores();
        _trazarRuta();
      });
    } catch (e) {
      print('Error obteniendo ubicación usuario: $e');
    }
  }

  // Obtener ubicación de la tienda desde Firebase
  Future<void> _obtenerUbicacionTienda() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('tienda')
          .doc('ubicacion')
          .get();

      // 🔑 Verificar si el widget sigue montado
      if (!_isMounted) return;

      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data != null && data['ubicacion'] != null) {
        final geo = data['ubicacion'] as GeoPoint;
        
        _safeSetState(() {
          ubicacionTienda = LatLng(geo.latitude, geo.longitude);
          _agregarMarcadores();
          _trazarRuta();
        });
      }
    } catch (e) {
      print('Error obteniendo ubicación tienda: $e');
    }
  }

  // Agregar marcadores al mapa
  void _agregarMarcadores() {
    if (ubicacionUsuario == null && ubicacionTienda == null) return;

    final nuevosMarcadores = <Marker>{};

    if (ubicacionUsuario != null) {
      nuevosMarcadores.add(
        Marker(
          markerId: const MarkerId('usuario'),
          position: ubicacionUsuario!,
          infoWindow: const InfoWindow(title: 'Tu ubicación'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }

    if (ubicacionTienda != null) {
      nuevosMarcadores.add(
        Marker(
          markerId: const MarkerId('tienda'),
          position: ubicacionTienda!,
          infoWindow: const InfoWindow(title: 'Tienda'),
        ),
      );
    }

    if (!mounted) return;
    setState(() => marcadores = nuevosMarcadores);
  }

  // Trazar ruta usando flutter_polyline_points versión 3.x
  Future<void> _trazarRuta() async {
    if (ubicacionUsuario == null || ubicacionTienda == null) return;

    try {
      PolylinePoints polylinePoints = PolylinePoints(apiKey: apiKey);

      final request = PolylineRequest(
        origin: PointLatLng(
          ubicacionUsuario!.latitude,
          ubicacionUsuario!.longitude,
        ),
        destination: PointLatLng(
          ubicacionTienda!.latitude,
          ubicacionTienda!.longitude,
        ),
        mode: TravelMode.driving,
      );

      PolylineResult result = await polylinePoints.getRouteBetweenCoordinates(
        request: request,
      );

      // 🔑 Verificar si el widget sigue montado
      if (!_isMounted) return;

      if (result.points.isNotEmpty) {
        List<LatLng> puntos = result.points
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        _safeSetState(() {
          polylines = {
            Polyline(
              polylineId: const PolylineId('ruta'),
              color: Colors.blue,
              width: 5,
              points: puntos,
            ),
          };
        });
      }
    } catch (e) {
      print('Error trazando ruta: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: (ubicacionUsuario == null || ubicacionTienda == null)
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                target: ubicacionUsuario!,
                zoom: 14,
              ),
              markers: marcadores,
              polylines: polylines,
              myLocationEnabled: true,
              onMapCreated: (controller) => mapController = controller,
            ),
    );
  }
}