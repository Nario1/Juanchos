import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Servicio para obtener recomendaciones de productos basadas en el consumo frecuente del cliente
class RecommendationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Obtiene los productos más frecuentemente comprados por el usuario actual
  /// 
  /// Retorna una lista de IDs de productos ordenados por frecuencia de compra
  /// [limit] - Número máximo de productos recomendados a retornar (por defecto 5)
  Future<List<String>> obtenerProductosRecomendados({
    int limit = 5,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      // Obtener todos los pedidos del usuario
      final pedidosSnapshot = await _firestore
          .collection('pedidos')
          .where('uid_usuario', isEqualTo: user.uid)
          .get();

      if (pedidosSnapshot.docs.isEmpty) {
        return [];
      }

      // Mapa para contar la frecuencia de cada producto
      // Key: id_producto, Value: cantidad total comprada
      final Map<String, int> frecuenciaProductos = {};

      // Recorrer todos los pedidos y contar la frecuencia de cada producto
      for (var pedidoDoc in pedidosSnapshot.docs) {
        final pedidoData = pedidoDoc.data();
        final productos = pedidoData['productos'] as List<dynamic>?;

        if (productos != null) {
          for (var producto in productos) {
            final idProducto = producto['id_producto'] as String?;
            final cantidad = (producto['cantidad'] as int?) ?? 1;

            if (idProducto != null && idProducto.isNotEmpty) {
              frecuenciaProductos[idProducto] =
                  (frecuenciaProductos[idProducto] ?? 0) + cantidad;
            }
          }
        }
      }

      // Si no hay productos frecuentes, retornar lista vacía
      if (frecuenciaProductos.isEmpty) {
        return [];
      }

      // Ordenar por frecuencia (mayor a menor) y obtener los IDs
      final productosOrdenados = frecuenciaProductos.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Retornar los IDs de los productos más frecuentes (hasta el límite especificado)
      return productosOrdenados
          .take(limit)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      print('Error al obtener productos recomendados: $e');
      return [];
    }
  }

  /// Obtiene los detalles completos de los productos recomendados
  /// 
  /// Retorna una lista de documentos de productos con sus detalles completos
  Future<List<QueryDocumentSnapshot>> obtenerDetallesProductosRecomendados({
    int limit = 5,
  }) async {
    try {
      // Obtener los IDs de productos recomendados
      final productosIds = await obtenerProductosRecomendados(limit: limit);

      if (productosIds.isEmpty) {
        return [];
      }

      // Obtener los detalles de cada producto desde Firestore
      // Nota: Firestore limita whereIn a 10 elementos, así que limitamos a 10
      final productosIdsLimitados = productosIds.take(10).toList();
      
      final productosSnapshot = await _firestore
          .collection('productos')
          .where(FieldPath.documentId, whereIn: productosIdsLimitados)
          .get();

      if (productosSnapshot.docs.isEmpty) {
        return [];
      }

      // Crear un mapa para mantener el orden de frecuencia
      final Map<String, QueryDocumentSnapshot> productosMap = {};
      for (var doc in productosSnapshot.docs) {
        productosMap[doc.id] = doc;
      }

      // Retornar los productos en el orden de frecuencia
      final productosOrdenados = <QueryDocumentSnapshot>[];
      for (var id in productosIdsLimitados) {
        if (productosMap.containsKey(id)) {
          productosOrdenados.add(productosMap[id]!);
        }
      }

      return productosOrdenados;
    } catch (e) {
      print('Error al obtener detalles de productos recomendados: $e');
      return [];
    }
  }

  /// Obtiene un stream de productos recomendados que se actualiza en tiempo real
  /// 
  /// Útil para mostrar recomendaciones que se actualizan automáticamente
  Stream<List<QueryDocumentSnapshot>> obtenerStreamProductosRecomendados({
    int limit = 5,
  }) {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    // Stream de pedidos del usuario
    return _firestore
        .collection('pedidos')
        .where('uid_usuario', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((pedidosSnapshot) async {
      if (pedidosSnapshot.docs.isEmpty) {
        return <QueryDocumentSnapshot>[];
      }

      // Contar frecuencia de productos
      final Map<String, int> frecuenciaProductos = {};

      for (var pedidoDoc in pedidosSnapshot.docs) {
        final pedidoData = pedidoDoc.data();
        final productos = pedidoData['productos'] as List<dynamic>?;

        if (productos != null) {
          for (var producto in productos) {
            final idProducto = producto['id_producto'] as String?;
            final cantidad = (producto['cantidad'] as int?) ?? 1;

            if (idProducto != null && idProducto.isNotEmpty) {
              frecuenciaProductos[idProducto] =
                  (frecuenciaProductos[idProducto] ?? 0) + cantidad;
            }
          }
        }
      }

      if (frecuenciaProductos.isEmpty) {
        return <QueryDocumentSnapshot>[];
      }

      // Ordenar por frecuencia
      final productosOrdenados = frecuenciaProductos.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      final productosIds = productosOrdenados
          .take(limit)
          .map((entry) => entry.key)
          .toList();

      // Obtener detalles de productos
      if (productosIds.isEmpty) {
        return <QueryDocumentSnapshot>[];
      }

      try {
        // Nota: Firestore limita whereIn a 10 elementos, así que limitamos a 10
        final productosIdsLimitados = productosIds.take(10).toList();
        
        final productosSnapshot = await _firestore
            .collection('productos')
            .where(FieldPath.documentId, whereIn: productosIdsLimitados)
            .get();

        if (productosSnapshot.docs.isEmpty) {
          return <QueryDocumentSnapshot>[];
        }

        // Mantener el orden de frecuencia
        final Map<String, QueryDocumentSnapshot> productosMap = {};
        for (var doc in productosSnapshot.docs) {
          productosMap[doc.id] = doc;
        }

        final productosOrdenadosList = <QueryDocumentSnapshot>[];
        for (var id in productosIdsLimitados) {
          if (productosMap.containsKey(id)) {
            productosOrdenadosList.add(productosMap[id]!);
          }
        }

        return productosOrdenadosList;
      } catch (e) {
        print('Error al obtener productos en stream: $e');
        return <QueryDocumentSnapshot>[];
      }
    });
  }
}

