import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../entities/perro.dart';
import '../entities/consulta.dart';
import 'InsertarConsulta.dart';

class ConsultasVeterinariasScreen extends StatefulWidget {
  const ConsultasVeterinariasScreen({super.key});

  @override
  State<ConsultasVeterinariasScreen> createState() =>
      _ConsultasVeterinariasScreenState();
}

class _ConsultasVeterinariasScreenState
    extends State<ConsultasVeterinariasScreen> {
  bool showProximas = true;

  List<Perro> _perros = [];
  Perro? _selectedPerro;
  bool _loadingPerros = false;
  bool _selectionShown = false;
  List<Consulta> _consultas = [];
  bool _loadingConsultas = false;

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
        List list = [];
        if (data is Map && data.containsKey('perros')) {
          list = data['perros'];
        } else if (data is List) {
          list = data;
        }
        _perros = list.map((e) => Perro.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('Error loading perros: $e');
    } finally {
      setState(() {
        _loadingPerros = false;
      });

      if (!_selectionShown) {
        _selectionShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final p = await _showSelectPerroDialog();
          if (p != null) {
            setState(() => _selectedPerro = p);
            _loadConsultas(forPerro: p);
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

  Future<void> _loadConsultas({Perro? forPerro}) async {
    setState(() => _loadingConsultas = true);
    try {
      final tipo = showProximas ? 'proximas' : 'pasadas';
      final uri = Uri.parse(
          'http://172.22.12.23/api_dogcare/get_consulta.php?tipo=$tipo');
      final resp = await http.get(uri);

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        List list = data['consultas'] ?? [];

        if (forPerro != null) {
          list = list.where((e) => e['idperro'].toString() == forPerro.idperro.toString()).toList();
        }

        setState(() {
          _consultas = list.map((e) => Consulta.fromJson(e)).toList();
        });
      } else {
        debugPrint('Error cargando consultas: ${resp.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loadConsultas: $e');
    } finally {
      setState(() => _loadingConsultas = false);
    }
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final filteredConsultas = _consultas.where((c) {
      final matchesDate = showProximas ? c.fecha.isAfter(now) || _isSameDay(c.fecha, now) : c.fecha.isBefore(now);
      return matchesDate;
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
                  icon: const Icon(Icons.arrow_back, color: Colors.teal),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Consultas Veterinarias 🩺',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedPerro == null
                          ? 'Mostrando todas las mascotas'
                          : 'Consultas de: ${_selectedPerro!.nombre}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _segmentButton('Próximas', showProximas, () {
                      setState(() => showProximas = true);
                      _loadConsultas(forPerro: _selectedPerro);
                    }),
                    _segmentButton('Pasadas', !showProximas, () {
                      setState(() => showProximas = false);
                      _loadConsultas(forPerro: _selectedPerro);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _loadingConsultas
                    ? const Center(child: CircularProgressIndicator())
                    : filteredConsultas.isEmpty
                        ? const Center(child: Text('No hay consultas'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredConsultas.length,
                            itemBuilder: (context, index) {
                              final c = filteredConsultas[index];
                              final isPast = c.fecha.isBefore(now);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          backgroundColor: isPast ? Colors.grey[300] : Colors.teal,
                                          child: Icon(
                                            Icons.medical_services,
                                            color: isPast ? Colors.grey : Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            c.perro,
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${c.fecha.day}/${c.fecha.month}/${c.fecha.year}',
                                          style: const TextStyle(color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    _infoRow(Icons.person, c.veterinario),
                                    
                                    _infoRow(Icons.notes, c.diagnostico),
                                   
                                  ],
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
              style: TextStyle(
                color: selected ? Colors.white : Colors.teal,
                fontWeight: FontWeight.bold,
              ),
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
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
