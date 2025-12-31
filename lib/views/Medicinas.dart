import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../entities/perro.dart';
import '../entities/tratamiento.dart';
import 'InsertarTratamiento.dart';

class MedicinasScreen extends StatefulWidget {
  const MedicinasScreen({super.key});

  @override
  State<MedicinasScreen> createState() => _MedicinasScreenState();
}

class _MedicinasScreenState extends State<MedicinasScreen> {
  List<Perro> _perros = [];
  Perro? _selectedPerro;
  bool _loadingPerros = false;
  bool _selectionShown = false;

  List<Tratamiento> _tratamientos = [];
  bool _loadingTratamientos = false;

  bool showActivas = true; // Nueva variable para pestañas Activas / Pasadas

  @override
  void initState() {
    super.initState();
    _loadPerros();
  }

  Future<void> _loadPerros() async {
    setState(() => _loadingPerros = true);
    try {
      final url = 'http://172.22.12.23/api_dogcare/get_perro.php';
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        List list = data is Map && data.containsKey('perros') ? data['perros'] : data is List ? data : [];
        _perros = list.map((e) => Perro.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading perros: $e');
    } finally {
      setState(() => _loadingPerros = false);

      if (!_selectionShown) {
        _selectionShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final p = await _showSelectPerroDialog();
          if (p != null) {
            setState(() => _selectedPerro = p);
            _loadTratamientos(forPerro: p);
          } else {
            _loadTratamientos();
          }
        });
      }
    }
  }

  Future<Perro?> _showSelectPerroDialog() async {
    return showDialog<Perro?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Selecciona una mascota'),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: _loadingPerros
                ? const Center(child: CircularProgressIndicator())
                : _perros.isEmpty
                    ? const Center(child: Text('No hay mascotas'))
                    : ListView.builder(
                        itemCount: _perros.length + 1,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return ListTile(
                              title: const Text('Todas las mascotas'),
                              onTap: () => Navigator.pop(context, null),
                            );
                          }
                          final perro = _perros[index - 1];
                          return ListTile(
                            title: Text(perro.nombre),
                            subtitle: Text(perro.raza ?? ''),
                            onTap: () => Navigator.pop(context, perro),
                          );
                        },
                      ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadTratamientos({Perro? forPerro}) async {
    setState(() => _loadingTratamientos = true);
    try {
      final uri = Uri.parse('http://172.22.12.23/api_dogcare/get_tratamiento.php');
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        List list = data['tratamientos'] ?? [];

        if (forPerro != null) {
          list = list.where((e) {
            final id = int.tryParse(e['idperro']?.toString() ?? '');
            return id != null && id == forPerro.idperro;
          }).toList();
        }

        setState(() {
          _tratamientos = list.map((e) => Tratamiento.fromJson(e)).toList();
        });
      } else {
        debugPrint('Error cargando tratamientos: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loadTratamientos: $e');
    } finally {
      setState(() => _loadingTratamientos = false);
    }
  }

  Future<void> _insertTratamiento() async {
    if (_selectedPerro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona una mascota')),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InsertTratamientoScreen(selectedPerro: _selectedPerro),
      ),
    );

    if (result == true) {
      _loadTratamientos(forPerro: _selectedPerro);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    // Filtrado de tratamientos activos o pasados
    final filteredTratamientos = _tratamientos.where((t) {
      final isVigente = t.activo && (t.fecha_fin.isAfter(now) || t.fecha_fin.isAtSameMomentAs(now));
      return showActivas ? isVigente : !isVigente;
    }).toList();

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
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.teal, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Medicinas 🩺',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.teal),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedPerro == null
                          ? 'Mostrando todas las mascotas'
                          : 'Medicinas de: ${_selectedPerro!.nombre}',
                      style: const TextStyle(color: Colors.black54, fontSize: 28),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Row(
                  children: [
                    _segmentButton('Activas', showActivas, () {
                      setState(() => showActivas = true);
                    }),
                    const SizedBox(width: 12),
                    _segmentButton('Pasadas', !showActivas, () {
                      setState(() => showActivas = false);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              BounceInUp(
                delay: const Duration(milliseconds: 1500),
                child: ElevatedButton(
                  onPressed: _insertTratamiento,
                  child: const Text('Insertar Tratamiento', style: TextStyle(fontSize: 23, color: Colors.teal)),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _loadingTratamientos
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTratamientos.isEmpty
                        ? const Center(child: Text('No hay tratamientos', style: TextStyle(fontSize: 20)))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredTratamientos.length,
                            itemBuilder: (context, index) {
                              final t = filteredTratamientos[index];
                              return BounceInLeft(
                                delay: Duration(milliseconds: 300 * index),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Colors.orangeAccent,
                                            child: const Icon(Icons.local_hospital, color: Colors.white),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              t.tratamiento,
                                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Text(
                                            '${t.fecha_inicio.day}/${t.fecha_inicio.month}/${t.fecha_inicio.year}',
                                            style: const TextStyle(color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      _infoRow(Icons.medication, 'Dosis: ${t.dosis}'),
                                      _infoRow(Icons.repeat, 'Veces al día: ${t.veces_dia}'),
                                      _infoRow(Icons.event, 'Fecha fin: ${t.fecha_fin.day}/${t.fecha_fin.month}/${t.fecha_fin.year}'),
                                      _infoRow(Icons.note, 'Razón: ${t.razon}'),
                                      _infoRow(Icons.notes, 'Notas: ${t.notas}'),
                                    
                                    ],
                                  ),
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

  Widget _segmentButton(String text, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? Colors.teal : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.teal),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(color: selected ? Colors.white : Colors.teal, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.orangeAccent),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
