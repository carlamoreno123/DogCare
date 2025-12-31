import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../entities/perro.dart';
import 'package:animate_do/animate_do.dart';

class InsertarPerroScreen extends StatefulWidget {
  const InsertarPerroScreen({super.key});

  @override
  State<InsertarPerroScreen> createState() => _InsertarPerroScreenState();
}

class _InsertarPerroScreenState extends State<InsertarPerroScreen> {
  final TextEditingController nombre = TextEditingController();
  final TextEditingController raza = TextEditingController();
  final TextEditingController propietario = TextEditingController();
  final TextEditingController sexo = TextEditingController();
  final TextEditingController chip = TextEditingController();
  final TextEditingController notas = TextEditingController();

  DateTime? nacimiento;
  bool _loading = false;

  @override
  void dispose() {
    nombre.dispose();
    raza.dispose();
    propietario.dispose();
    sexo.dispose();
    chip.dispose();
    notas.dispose();
    super.dispose();
  }

  Future<bool> _insertPerro() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse('http://172.22.12.23/api_dogcare/post_perro.php');
      final response = await http.post(url, body: {
        'nombre': nombre.text.trim(),
        'raza': raza.text.trim(),
        'propietario': propietario.text.trim(),
        'sexo': sexo.text.trim(),
        'chip': chip.text.trim(),
        'notas': notas.text.trim(),
        'nacimiento': nacimiento != null
            ? '${nacimiento!.year.toString().padLeft(4, '0')}-'
              '${nacimiento!.month.toString().padLeft(2, '0')}-'
              '${nacimiento!.day.toString().padLeft(2, '0')}'
            : '',
      });

      if (response.statusCode == 200) {
        final cleanBody = response.body.trim();
        final firstChar = cleanBody.isNotEmpty ? cleanBody[0] : '';
        if (firstChar != '{') {
          debugPrint('Respuesta inválida del servidor: $cleanBody');
          return false;
        }
        final data = jsonDecode(cleanBody);
        return data['success'] == true || data['success'] == 1 || data['success'] == '1';
      } else {
        debugPrint('HTTP Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error insertPerro: $e');
      return false;
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F7),
      appBar: AppBar(
        title: const Text('Nuevo Perro'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BounceIn(
          delay: const Duration(milliseconds: 300),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'Para agregar imagen \nconsultar a administrador',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade700,
                    ),
                  ),
                  SizedBox(width: 20),
                  Icon( 
                    Icons.pets,
                    size: 30,
                    color: Colors.teal.shade700,
                  ),
                ],
              ),
              _card(child: _field('Nombre', nombre)),
              _card(child: _field('Raza', raza)),
              _card(child: _field('Propietario', propietario)),
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field('Sexo', sexo),
                    const SizedBox(height: 4),
                    const Text(
                      "Debe ser 'M' o 'F'",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color.fromARGB(249, 218, 13, 13),
                      ),
                    ),
                  ],
                ),
              ),
              _card(child: _field('Chip', chip)),
              _card(child: _field('Notas', notas, maxLines: 3)),
              const SizedBox(height: 12),
              _card(
                child: ListTile(
                  title: Text(
                    nacimiento != null
                        ? '📅 Nacimiento: ${nacimiento!.day}-${nacimiento!.month}-${nacimiento!.year}'
                        : 'Seleccionar fecha de nacimiento',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: Colors.teal),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: nacimiento ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => nacimiento = picked);
                  },
                ),
              ),
              const SizedBox(height: 24),
              _loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nombre.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('El nombre es obligatorio')),
                            );
                            return;
                          }
                          final ok = await _insertPerro();
                          if (ok) {
                            final nuevoPerro = Perro(
                              idperro: 0,
                              nombre: nombre.text.trim(),
                              raza: raza.text.trim(),
                              propietario: propietario.text.trim(),
                              sexo: sexo.text.trim(),
                              chip: chip.text.trim(),
                              notas: notas.text.trim(),
                              nacimiento: nacimiento,
                              imagen: null,
                            );
                            Navigator.pop(context, nuevoPerro);
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error al insertar el perro')),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Guardar Perro',
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
