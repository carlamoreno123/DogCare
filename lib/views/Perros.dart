import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dogcare/views/FichaPerro.dart';
import '../entities/perro.dart';
import 'InsertarPerro.dart';

class PerrosScreen extends StatefulWidget {
  const PerrosScreen({super.key});

  @override
  State<PerrosScreen> createState() => _PerrosScreenState();
}

class _PerrosScreenState extends State<PerrosScreen> {
  late Future<List<Perro>> _perros;
  final Map<String, String?> _imageCache = {};

  Future<String?> _findWorkingImage(String imagen) async {
    if (_imageCache.containsKey(imagen)) return _imageCache[imagen];

    final candidates = [
      'http://172.22.12.23/api_dogcare/$imagen',
      'http://172.22.12.23/DogCare/$imagen',
      'http://172.22.12.23/$imagen',
      'http://10.0.2.2/DogCare/$imagen',
      'http://10.0.2.2/$imagen',
    ];

    for (final url in candidates) {
      try {
        final resp =
            await http.head(Uri.parse(url)).timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          _imageCache[imagen] = url;
          return url;
        }
      } catch (_) {}
    }

    _imageCache[imagen] = null;
    return null;
  }

  Future<void> _reloadPerros() async {
    setState(() {
      _perros = fetchPerros();
    });
    try {
      await _perros;
    } catch (_) {}
  }

  @override
  void initState() {
    super.initState();
    _perros = fetchPerros();
  }

  Future<List<Perro>> fetchPerros() async {
    final url = 'http://172.22.12.23/api_dogcare/get_perro.php';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is Map && data.containsKey('success')) {
        final ok = data['success'] == true ||
            data['success'] == 1 ||
            data['success'] == '1';
        if (ok) {
          return (data['perros'] as List)
              .map((e) => Perro.fromJson(e))
              .toList();
        }
        return [];
      }

      if (data is List) {
        return data.map((e) => Perro.fromJson(e)).toList();
      }
    }

    throw Exception('Error al cargar perros');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE0F7FA), Color(0xFFE8F5E9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.teal),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                  Align(
  alignment: Alignment.centerLeft,
  child: IconButton(
    icon: const Icon(Icons.add, color: Colors.teal),
    onPressed: () async {
      // Navegar a InsertarPerroScreen
      final nuevoPerro = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const InsertarPerroScreen()),
      );

      // Si se insertó un perro, puedes actualizar tu lista o hacer algo con él
      if (nuevoPerro != null) {
        // Por ejemplo, recargar la lista o agregarlo a tu estado
        debugPrint('Nuevo perro insertado: ${nuevoPerro.nombre}');
      }
    },
  ),
),

                ],
              ),
             
              // 🐾 HEADER
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Mis Mascotas🐶',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Toca uno para ver su ficha',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),

              // 📋 LISTA
              Expanded(
                child: FutureBuilder<List<Perro>>(
                  future: _perros,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return _emptyState(
                        message: 'Error al cargar perros',
                        action: _reloadPerros,
                        actionText: 'Reintentar',
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return _emptyState(
                        message: 'No hay perros registrados',
                        action: _reloadPerros,
                        actionText: 'Actualizar',
                      );
                    }

                    final perros = snapshot.data!;

                    return RefreshIndicator(
                      onRefresh: _reloadPerros,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: perros.length,
                        itemBuilder: (context, index) {
                          final perro = perros[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: _avatarPerro(perro),
                              title: Text(
                                perro.nombre,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(perro.raza ?? 'Sin raza'),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.teal,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FichaPerro(perro: perro),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🐕 AVATAR
  Widget _avatarPerro(Perro perro) {
    if (perro.imagen == null) {
      return const CircleAvatar(
        radius: 28,
        backgroundColor: Colors.teal,
        child: Icon(Icons.pets, color: Colors.white),
      );
    }

    return FutureBuilder<String?>(
      future: _findWorkingImage(perro.imagen!),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }

        if (snap.data != null) {
          return CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(snap.data!),
          );
        }

        return const CircleAvatar(
          radius: 28,
          backgroundColor: Colors.teal,
          child: Icon(Icons.pets, color: Colors.white),
        );
      },
    );
  }

  // 📭 ESTADO VACÍO / ERROR
  Widget _emptyState({
    required String message,
    required VoidCallback action,
    required String actionText,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: action,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );
  }
}
