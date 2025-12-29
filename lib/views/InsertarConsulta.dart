import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../entities/perro.dart';

class InsertarConsultaScreen extends StatefulWidget {
  final Perro? perro;
  const InsertarConsultaScreen({super.key, this.perro});

  @override
  State<InsertarConsultaScreen> createState() => _InsertarConsultaScreenState();
}

class _InsertarConsultaScreenState extends State<InsertarConsultaScreen> {
  // perroController removed as id will come from `widget.perro`
  final TextEditingController veterinarioController = TextEditingController();
  final TextEditingController tipoController = TextEditingController();
  final TextEditingController costeController = TextEditingController();
  final TextEditingController diagnosticoController = TextEditingController();
  final TextEditingController notasController = TextEditingController();

  DateTime? fechaConsulta;
  bool _loading = false;

  @override
  void dispose() {
    veterinarioController.dispose();
    tipoController.dispose();
    costeController.dispose();
    diagnosticoController.dispose();
    notasController.dispose();
    super.dispose();
  }

  Future<bool> _insertConsulta() async {
    if ((widget.perro == null) || veterinarioController.text.trim().isEmpty || fechaConsulta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perro, veterinario y fecha son obligatorios')),
      );
      return false;
    }

    setState(() => _loading = true);
    try {
      final url = Uri.parse('http://172.22.12.23/api_dogcare/post_consulta.php');
      final response = await http.post(url, body: {
        'idperro': widget.perro?.idperro?.toString() ?? '',
        'idconsulta': veterinarioController.text.trim(),
        'tipo': tipoController.text.trim(),
        'fecha': fechaConsulta != null
            ? '${fechaConsulta!.year.toString().padLeft(4,'0')}-'
              '${fechaConsulta!.month.toString().padLeft(2,'0')}-'
              '${fechaConsulta!.day.toString().padLeft(2,'0')} '
              '${fechaConsulta!.hour.toString().padLeft(2,'0')}:'
              '${fechaConsulta!.minute.toString().padLeft(2,'0')}:00'
            : '',
        'coste': costeController.text.trim(),
        'veterinario': veterinarioController.text.trim(),
        'diagnostico': diagnosticoController.text.trim(),
        'notes': notasController.text.trim(),
      });

      if (response.statusCode == 200) {
        final cleanBody = response.body.trim();
        final firstChar = cleanBody.isNotEmpty ? cleanBody[0] : '';
        if (firstChar != '{') {
          debugPrint('Respuesta inválida del servidor: $cleanBody');
          return false;
        }
        final data = jsonDecode(cleanBody);
        return data['success'] == 1;
      } else {
        debugPrint('HTTP Error: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error insertConsulta: $e');
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
                    'Nueva Consulta',
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
              // Mostrar la mascota seleccionada (no editable)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: TextField(
                  controller: TextEditingController(text: widget.perro?.nombre ?? ''),
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Mascota',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              _field('ID Veterinario', veterinarioController),
              _field('Tipo', tipoController),
              _field('Coste', costeController, keyboard: TextInputType.number),
              _field('Diagnóstico', diagnosticoController, maxLines: 3),
              _field('Notas', notasController, maxLines: 3),
              const SizedBox(height: 20),

              // FECHA Y HORA
              ListTile(
                title: Text(
                  fechaConsulta != null
                      ? 'Fecha: ${fechaConsulta!.day}-${fechaConsulta!.month}-${fechaConsulta!.year} '
                        '${fechaConsulta!.hour.toString().padLeft(2,'0')}:${fechaConsulta!.minute.toString().padLeft(2,'0')}'
                      : 'Seleccionar fecha y hora',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: const Icon(Icons.calendar_today, color: Colors.teal),
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: fechaConsulta ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    final pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(fechaConsulta ?? DateTime.now()),
                    );
                    if (pickedTime != null) {
                      setState(() {
                        fechaConsulta = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      });
                    }
                  }
                },
              ),
              const SizedBox(height: 20),

              // BOTÓN GUARDAR
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar Consulta'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () async {
                        final ok = await _insertConsulta();
                        if (ok) {
                          Navigator.pop(context, true);
                        } else {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error al insertar la consulta')),
                            );
                          }
                        }
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
