import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../entities/perro.dart';

class EditarPerroScreen extends StatefulWidget {
  final Perro perro;
  const EditarPerroScreen({super.key, required this.perro});

  @override
  State<EditarPerroScreen> createState() => _EditarPerroScreenState();
}

class _EditarPerroScreenState extends State<EditarPerroScreen> {
  late TextEditingController nombre;
  late TextEditingController raza;
  late TextEditingController propietario;
  late TextEditingController sexo;
  late TextEditingController chip;
  late TextEditingController notas;

  DateTime? nacimiento;
  bool _loading = false;

  String? _normalizeSexo(String? raw) {
    if (raw == null) return null;
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return null;
    if (s.startsWith('m')) return 'M';
    if (s.startsWith('h') || s.startsWith('f')) return 'F';
    if (s == 'm' || s == 'f') return s.toUpperCase();
    return null;
  }

  @override
  void initState() {
    super.initState();
    nombre = TextEditingController(text: widget.perro.nombre);
    raza = TextEditingController(text: widget.perro.raza);
    propietario = TextEditingController(text: widget.perro.propietario);
    sexo = TextEditingController(text: widget.perro.sexo);
    chip = TextEditingController(text: widget.perro.chip);
    notas = TextEditingController(text: widget.perro.notas);
    nacimiento = widget.perro.nacimiento;
  }

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

  Future<bool> _updatePerro() async {
    setState(() => _loading = true);
    try {
      final url = Uri.parse('http://172.22.12.23/api_dogcare/update_perro.php');

      final Map<String, String> payload = {
        'idperro': widget.perro.idperro?.toString() ?? '',
        'nombre': nombre.text.trim(),
        'raza': raza.text.trim(),
        'propietario': propietario.text.trim(),
        'sexo': _normalizeSexo(sexo.text.trim()) ?? '',
        'chip': chip.text.trim(),
        'notas': notas.text.trim(),
        'nacimiento': nacimiento != null
            ? '${nacimiento!.year.toString().padLeft(4, '0')}-'
              '${nacimiento!.month.toString().padLeft(2, '0')}-'
              '${nacimiento!.day.toString().padLeft(2, '0')}'
            : '',
      };
      // Duplicate common alternative keys in case the API expects them
      payload['id'] = payload['idperro'] ?? '';
      payload['id_perro'] = payload['idperro'] ?? '';
      payload['idPerro'] = payload['idperro'] ?? '';
      payload['nombre_perro'] = payload['nombre'] ?? '';
      payload['nombrePerro'] = payload['nombre'] ?? '';
      payload['fecha_nacimiento'] = payload['nacimiento'] ?? '';
      payload['fechaNacimiento'] = payload['nacimiento'] ?? '';
      payload['nacimiento'] = payload['nacimiento'] ?? '';
      payload['accion'] = 'update';
      payload['action'] = 'update';
      payload['submit'] = 'update';

      // Log final payload for debugging server 'Faltan datos requeridos'
      debugPrint('Final payload to update_perro.php: $payload');

      // Primer intento: form-urlencoded (comportamiento original)
      // Forzamos el header para asegurar que PHP llene $_POST
      final response = await http.post(
        url,
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
        },
        body: payload,
      );

      if (response.statusCode == 200) {
        final cleanBody = response.body.trim();
        final firstChar = cleanBody.isNotEmpty ? cleanBody[0] : '';
        if (firstChar != '{') {
          debugPrint('Respuesta inválida del servidor (no JSON): $cleanBody');
          return false;
        }
        final data = jsonDecode(cleanBody);
        return data['success'] == true || data['success'] == 1 || data['success'] == '1';
      }

      // Log detallado para diagnosticar 500
      debugPrint('HTTP Error: ${response.statusCode}');
      debugPrint('Response headers: ${response.headers}');
      debugPrint('Response body: ${response.body}');

      // Si el servidor responde 500 intentamos reenviar JSON por si la API espera JSON
      if (response.statusCode == 500) {
        debugPrint('Reintentando petición como JSON...');
        final jsonResp = await http.post(
          url,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: jsonEncode(payload),
        );

        debugPrint('JSON attempt status: ${jsonResp.statusCode}');
        debugPrint('JSON attempt body: ${jsonResp.body}');

        if (jsonResp.statusCode == 200) {
          final cleanBody = jsonResp.body.trim();
          if (cleanBody.isEmpty || cleanBody[0] != '{') return false;
          final data = jsonDecode(cleanBody);
          return data['success'] == true || data['success'] == 1 || data['success'] == '1';
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error updatePerro: $e');
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
                    'Editar Perro',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 20),

              // CAMPOS DE TEXTO
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
                        final normalizedSexo = _normalizeSexo(sexo.text.trim());
                        if (sexo.text.trim().isNotEmpty && normalizedSexo == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Sexo inválido. Use M o F.')),
                          );
                          return;
                        }

                        if (widget.perro.idperro == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('ID del perro inválido')),
                          );
                          return;
                        }

                        final ok = await _updatePerro();
                        if (ok) {
                          try {
                            final edited = Perro(
                              idperro: widget.perro.idperro,
                              nombre: nombre.text.trim(),
                              raza: raza.text.trim(),
                              propietario: propietario.text.trim(),
                              sexo: normalizedSexo,
                              chip: chip.text.trim(),
                              notas: notas.text.trim(),
                              nacimiento: nacimiento,
                              imagen: widget.perro.imagen,
                            );
                            Navigator.pop(context, edited);
                          } catch (e) {
                            debugPrint('Error creando Perro editado: $e');
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Error al procesar los datos')),
                              );
                            }
                          }
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Error al actualizar el perro')),
                            );
                          }
                        }
                      },
                      child: const Text('Guardar cambios'),
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
