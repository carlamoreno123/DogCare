import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../entities/perro.dart';
import '../entities/aviso.dart';

class AvisosScreen extends StatefulWidget {
  const AvisosScreen({super.key});

  @override
  State<AvisosScreen> createState() => _AvisosScreenState();
}

class _AvisosScreenState extends State<AvisosScreen> {
  List<Perro> _perros = [];
  int _selectedIndex = 0;
  bool _loadingPerros = false;

  List<Aviso> _avisos = [];
  bool _loadingAvisos = false;

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
        List list = data['perros'] ?? [];
        _perros = list.map((e) => Perro.fromJson(e)).toList();
        if (_perros.isNotEmpty) {
          _loadAvisos(forPerro: _perros[_selectedIndex]);
        }
      }
    } catch (e) {
      debugPrint('Error loading perros: $e');
    } finally {
      setState(() => _loadingPerros = false);
    }
  }

  Future<void> _loadAvisos({Perro? forPerro}) async {
    setState(() => _loadingAvisos = true);
    try {
      final uri = Uri.parse('http://172.22.12.23/api_dogcare/get_avisos.php');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        List list = data['avisos'] ?? [];

        if (forPerro != null) {
          list = list
              .where(
                (e) => e['idperro'].toString() == forPerro.idperro.toString(),
              )
              .toList();
        }

        // Filtrar avisos que ya pasaron
        final today = DateTime.now();
        list = list.where((e) {
          final avisoDate = DateTime.parse(e['fechaRecordatorio']);
          return avisoDate.isAfter(today.subtract(const Duration(days: 1)));
        }).toList();

        setState(() {
          _avisos = list.map((e) => Aviso.fromJson(e)).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading avisos: $e');
    } finally {
      setState(() => _loadingAvisos = false);
    }
  }

  void _addAvisoDialog() {
    final _tituloController = TextEditingController();
    final _descripcionController = TextEditingController();
    DateTime? _selectedDate;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Aviso'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              items: const [
                DropdownMenuItem(value: 'Pasear', child: Text('Pasear')),
                DropdownMenuItem(
                  value: 'Cortar uñas',
                  child: Text('Cortar uñas'),
                ),
                DropdownMenuItem(
                  value: 'Reponer comida',
                  child: Text('Reponer comida'),
                ),
                DropdownMenuItem(value: 'Otro', child: Text('Otro')),
              ],
              onChanged: (val) {
                _tituloController.text = val ?? '';
              },
              decoration: const InputDecoration(labelText: 'Tipo de aviso'),
            ),
            TextField(
              controller: _descripcionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
              child: const Text('Seleccionar fecha'),
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (date != null) _selectedDate = date;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            onPressed: () {
              if (_tituloController.text.isEmpty || _selectedDate == null)
                return;

              final newAviso = Aviso(
                idAviso:
                    0, // temporal, luego se reemplaza con el ID real de la BD
                idPerro: _perros[_selectedIndex].idperro!,
// minúscula
                titulo: _tituloController.text,
                descripcion: _descripcionController.text,
                fechaRecordatorio: _selectedDate!,
                completado: false,
              );

              setState(() {
                _avisos.add(newAviso);
              });

              Navigator.pop(context);
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _addAvisoDialog,
        child: const Icon(Icons.add),
      ),
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
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.teal,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text(
                  'Avisos 🐾',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 140,
                child: _loadingPerros
                    ? const Center(child: CircularProgressIndicator())
                    : PageView.builder(
                        controller: PageController(viewportFraction: 0.6),
                        itemCount: _perros.length,
                        onPageChanged: (index) {
                          setState(() => _selectedIndex = index);
                          _loadAvisos(forPerro: _perros[index]);
                        },
                        itemBuilder: (context, index) {
                          final perro = _perros[index];
                          final isSelected = index == _selectedIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: isSelected ? 0 : 20,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.teal
                                  : Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                perro.nombre,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _loadingAvisos
                    ? const Center(child: CircularProgressIndicator())
                    : _avisos.isEmpty
                    ? const Center(child: Text('No hay avisos'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _avisos.length,
                        itemBuilder: (context, index) {
                          final aviso = _avisos[index];
                          return BounceInLeft(
                            delay: Duration(milliseconds: 300 * index),
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              color: Colors.white,
                              elevation: 4,
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                title: Text(
                                  aviso.titulo,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                subtitle: Text(
                                  '${aviso.descripcion}\nRecordatorio: ${aviso.fechaRecordatorio.day}/${aviso.fechaRecordatorio.month}/${aviso.fechaRecordatorio.year}',
                                ),
                                trailing: Checkbox(
                                  value: aviso.completado,
                                  onChanged: (val) {
                                    setState(
                                      () => aviso.completado = val ?? false,
                                    );
                                  },
                                ),
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
}
