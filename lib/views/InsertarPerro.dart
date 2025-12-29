import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../entities/perro.dart';

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.teal),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Nuevo Perro',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 20),

              // CAMPOS
              _field('Nombre', nombre),
              _field('Raza', raza),
              _field('Propietario', propietario),
              _field('Sexo', sexo),
              _field('Chip', chip),
              _field('Notas', notas),
              const SizedBox(height: 20),

              // FECHA DE NACIMIENTO
              ListTile(
                title: Text(
                  nacimiento != null
                      ? 'Nacimiento: ${nacimiento!.day}-${nacimiento!.month}-${nacimiento!.year}'
                      : 'Seleccionar fecha de nacimiento',
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
              const SizedBox(height: 20),

              // BOTÓN GUARDAR
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size.fromHeight(50),
                      ),
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
                            idperro: 0, // PHP debería devolver el ID real si quieres
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
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error al insertar el perro')),
                            );
                          }
                        }
                      },
                      child: const Text('Guardar'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
