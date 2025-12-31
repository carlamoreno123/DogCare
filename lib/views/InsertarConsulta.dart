import 'package:animate_do/animate_do.dart';
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
  final TextEditingController tipoController = TextEditingController();
  final TextEditingController costeController = TextEditingController();
  final TextEditingController diagnosticoController = TextEditingController();
  final TextEditingController notasController = TextEditingController();
  final TextEditingController veterinarioController = TextEditingController(); // nuevo

  DateTime? fechaConsulta;
  bool _loading = false;

  @override
  void dispose() {
    tipoController.dispose();
    costeController.dispose();
    diagnosticoController.dispose();
    notasController.dispose();
    veterinarioController.dispose();
    super.dispose();
  }

  void _actualizarTipoSegunFecha(DateTime fecha) {
    final hoy = DateTime.now();
    final hoySinHora = DateTime(hoy.year, hoy.month, hoy.day);
    final fechaSinHora = DateTime(fecha.year, fecha.month, fecha.day);

    if (fechaSinHora.isBefore(hoySinHora)) {
      tipoController.text = 'pasadas';
    } else {
      tipoController.text = 'proximas';
    }
  }

  Future<bool> _insertConsulta() async {
    if (widget.perro == null || fechaConsulta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perro y fecha son obligatorios')),
      );
      return false;
    }

    setState(() => _loading = true);
    try {
      final url = Uri.parse('http://172.22.12.23/api_dogcare/post_consulta.php');
      final response = await http.post(url, body: {
        'idperro': widget.perro!.idperro.toString(),
        'tipo': tipoController.text.trim(),
        'fecha':
            '${fechaConsulta!.year.toString().padLeft(4,'0')}-'
            '${fechaConsulta!.month.toString().padLeft(2,'0')}-'
            '${fechaConsulta!.day.toString().padLeft(2,'0')} '
            '${fechaConsulta!.hour.toString().padLeft(2,'0')}:'
            '${fechaConsulta!.minute.toString().padLeft(2,'0')}:00',
        'coste': costeController.text.trim(),
        'veterinario': veterinarioController.text.trim(),
        'diagnostico': diagnosticoController.text.trim(),
        'notes': notasController.text.trim(),
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body.trim());
        return data['success'] == 1;
      }
      return false;
    } catch (e) {
      debugPrint('Error: $e');
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
        title: const Text('Nueva Consulta'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: BounceIn(
          delay: const Duration(milliseconds: 400),
          child: Column(
            children: [
              _card(
                child: _readonlyField('Mascota', widget.perro?.nombre ?? ''),
              ),
              const SizedBox(height: 12),
              _card(
                child: Column(
                  children: [
                    _field('Tipo', tipoController),
                    Row(
                      children: const [
                        Text(
                          'Se asigna automáticamente al elegir la fecha',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color.fromARGB(249, 218, 13, 13),
                          ),
                        )
                      ],
                    ),
                    _field('Coste', costeController,
                        keyboard: TextInputType.number),
                    _field('Veterinario', veterinarioController), // editable
                    _field('Diagnóstico', diagnosticoController, maxLines: 3),
                    _field('Notas', notasController, maxLines: 3),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _card(
                child: ListTile(
                  title: Text(
                    fechaConsulta != null
                        ? '📅 ${fechaConsulta!.day}-${fechaConsulta!.month}-${fechaConsulta!.year} '
                          '${fechaConsulta!.hour.toString().padLeft(2,'0')}:'
                          '${fechaConsulta!.minute.toString().padLeft(2,'0')}'
                        : 'Seleccionar fecha y hora',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: Colors.teal),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
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
                          _actualizarTipoSegunFecha(fechaConsulta!);
                        });
                      }
                    }
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
                          final ok = await _insertConsulta();
                          if (ok && mounted) Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Guardar Consulta',
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _readonlyField(String label, String value) {
    return TextField(
      enabled: false,
      controller: TextEditingController(text: value),
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _field(String label, TextEditingController controller,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
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
