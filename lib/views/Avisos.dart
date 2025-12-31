import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../entities/perro.dart';
import '../entities/aviso.dart';
import '../main.dart'; // Para scheduleNotification

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

  // GET avisos por idperro
  Future<void> _loadAvisos({required Perro forPerro}) async {
    setState(() => _loadingAvisos = true);
    try {
      final uri = Uri.parse(
          'http://172.22.12.23/api_dogcare/get_aviso.php?idperro=${forPerro.idperro}');
      final resp = await http.get(uri);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        List list = data['avisos'] ?? [];

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

  // POST aviso a la base de datos
  Future<void> _postAviso(Aviso aviso) async {
    try {
      final uri = Uri.parse('http://172.22.12.23/api_dogcare/post_aviso.php');
      final body = {
        'idperro': aviso.idPerro.toString(),
        'titulo': aviso.titulo,
        'descripcion': aviso.descripcion,
        'fechaRecordatorio': aviso.fechaRecordatorio.toIso8601String(),
        'completado': aviso.completado ? '1' : '0',
      };

      final resp = await http.post(uri, body: body);
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        if (data['success'] == true) {
          _loadAvisos(forPerro: _perros[_selectedIndex]);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(data['message'] ?? 'Error')));
        }
      }
    } catch (e) {
      debugPrint('Error posting aviso: $e');
    }
  }

  void _addAvisoDialog() {
    final _tituloController = TextEditingController();
    final _descripcionController = TextEditingController();
    DateTime? _selectedDate;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Agregar Aviso',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  items: const [
                    DropdownMenuItem(value: 'Pasear', child: Text('Pasear')),
                    DropdownMenuItem(value: 'Cortar uñas', child: Text('Cortar uñas')),
                    DropdownMenuItem(value: 'Reponer comida', child: Text('Reponer comida')),
                    DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                  ],
                  onChanged: (val) {
                    _tituloController.text = val ?? '';
                  },
                  decoration: const InputDecoration(labelText: 'Tipo de aviso'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _descripcionController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Descripción'),
                ),
                const SizedBox(height: 15),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    minimumSize: const Size.fromHeight(40),
                  ),
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  label: Text(
                    _selectedDate == null
                        ? 'Seleccionar fecha y hora'
                        : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} '
                          '${_selectedDate!.hour.toString().padLeft(2, '0')}:${_selectedDate!.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setStateDialog(() {
                          _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(fontSize: 16, color: Colors.black)),
            ),
           ElevatedButton(
  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
  onPressed: () async {
    if (_tituloController.text.isEmpty || _selectedDate == null) return;

    final newAviso = Aviso(
      idAviso: 0,
      idPerro: _perros[_selectedIndex].idperro!,
      titulo: _tituloController.text,
      descripcion: _descripcionController.text,
      fechaRecordatorio: _selectedDate!,
      completado: false,
    );

    // Guardar en base de datos
    await _postAviso(newAviso);

    // Programar notificación local
    await scheduleNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000, // ID único
      title: newAviso.titulo,
      body: newAviso.descripcion,
      scheduledDate: newAviso.fechaRecordatorio,
    );

    Navigator.pop(context);
  },
  child: const Text(
    'Agregar',
    style: TextStyle(fontSize: 16, color: Colors.white),
  ),
),

          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _addAvisoDialog,
        child: const Icon(Icons.add, color: Colors.white),
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
                    icon: const Icon(Icons.arrow_back, color: Colors.teal, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Avisos 🐾',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ],
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
                              color: isSelected ? Colors.teal : Colors.orangeAccent,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
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
                        ? const Center(child: Text('No hay avisos', style: TextStyle(fontSize: 20, color: Colors.black54)))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _avisos.length,
                            itemBuilder: (context, index) {
                              final aviso = _avisos[index];
                              final avisoDate = aviso.fechaRecordatorio;
                              final isPast = avisoDate.isBefore(DateTime.now());
                              return BounceInLeft(
                                delay: Duration(milliseconds: 200 * index),
                                child: Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  color: isPast ? Colors.grey[300] : Colors.white,
                                  elevation: 4,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(16),
                                    title: Text(
                                      aviso.titulo,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isPast ? Colors.black38 : Colors.black87,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${aviso.descripcion}\nRecordatorio: ${avisoDate.day}/${avisoDate.month}/${avisoDate.year} '
                                      '${avisoDate.hour.toString().padLeft(2, '0')}:${avisoDate.minute.toString().padLeft(2, '0')}',
                                      style: TextStyle(color: isPast ? Colors.black38 : Colors.black54),
                                    ),
                                    trailing: Checkbox(
                                      value: aviso.completado,
                                      onChanged: (val) {
                                        setState(() => aviso.completado = val ?? false);
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
