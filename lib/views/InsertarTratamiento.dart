import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../entities/perro.dart';

class InsertTratamientoScreen extends StatefulWidget {
  final Perro? selectedPerro; // Se puede pasar un perro seleccionado desde otra pantalla

  const InsertTratamientoScreen({super.key, this.selectedPerro});

  @override
  State<InsertTratamientoScreen> createState() => _InsertTratamientoScreenState();
}

class _InsertTratamientoScreenState extends State<InsertTratamientoScreen> {
  Perro? _selectedPerro;
  List<Perro> _perros = [];
  bool _loadingPerros = false;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _tratamientoController = TextEditingController();
  final TextEditingController _dosisController = TextEditingController();
  final TextEditingController _vecesDiaController = TextEditingController();
  final TextEditingController _razonController = TextEditingController();
  final TextEditingController _notasController = TextEditingController();

  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _activo = true;

  @override
  void initState() {
    super.initState();
    if (widget.selectedPerro != null) {
      _selectedPerro = widget.selectedPerro;
    } else {
      _loadPerros();
    }
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

        if (_perros.isNotEmpty && _selectedPerro == null) {
          await _selectPerroDialog();
        }
      }
    } catch (e) {
      debugPrint('Error loading perros: $e');
    } finally {
      setState(() => _loadingPerros = false);
    }
  }

  Future<void> _selectPerroDialog() async {
    final perro = await showDialog<Perro?>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selecciona una mascota'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: _loadingPerros
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _perros.length,
                  itemBuilder: (context, index) {
                    final p = _perros[index];
                    return ListTile(
                      title: Text(p.nombre),
                      subtitle: Text(p.raza ?? ''),
                      onTap: () => Navigator.pop(context, p),
                    );
                  },
                ),
        ),
      ),
    );

    if (perro != null) {
      setState(() => _selectedPerro = perro);
    }
  }

  Future<void> _pickFechaInicio() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _fechaInicio = date);
  }

  Future<void> _pickFechaFin() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _fechaFin = date);
  }

Future<void> _submitTratamiento() async {
  if (_selectedPerro == null) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona una mascota')));
    return;
  }

  if (_formKey.currentState!.validate() &&
      _fechaInicio != null &&
      _fechaFin != null) {
    
    final body = {
      'idperro': _selectedPerro!.idperro!.toString(),
      'tratamiento': _tratamientoController.text,
      'dosis': _dosisController.text,
      'veces_dia': _vecesDiaController.text,
      'fecha_inicio': _fechaInicio!.toString().substring(0, 10),
      'fecha_fin': _fechaFin!.toString().substring(0, 10),
      'razon': _razonController.text,
      'notas': _notasController.text,
      'activo': _activo ? '1' : '0',
    };

    final uri = Uri.parse(
        'http://172.22.12.23/api_dogcare/post_tratamiento.php');

    final resp = await http.post(uri, body: body);

    debugPrint('STATUS: ${resp.statusCode}');
    debugPrint('BODY: ${resp.body}');

    if (resp.statusCode == 200) {
      final data = jsonDecode(resp.body);
      if (data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tratamiento agregado')));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])));
      }
    }
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insertar Tratamiento'),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (_selectedPerro != null)
              Text(
                'Mascota: ${_selectedPerro!.nombre}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            if (_selectedPerro == null)
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                onPressed: _selectPerroDialog,
                child: const Text('Selecciona una mascota'),
              ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _tratamientoController,
                    decoration: const InputDecoration(labelText: 'Tratamiento'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  TextFormField(
                    controller: _dosisController,
                    decoration: const InputDecoration(labelText: 'Dosis'),
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  TextFormField(
                    controller: _vecesDiaController,
                    decoration: const InputDecoration(labelText: 'Veces al día'),
                    keyboardType: TextInputType.number,
                    validator: (val) =>
                        val == null || val.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_fechaInicio == null
                            ? 'Fecha inicio'
                            : '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'),
                      ),
                      TextButton(
                        onPressed: _pickFechaInicio,
                        child: const Text('Seleccionar'),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(_fechaFin == null
                            ? 'Fecha fin'
                            : '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'),
                      ),
                      TextButton(
                        onPressed: _pickFechaFin,
                        child: const Text('Seleccionar'),
                      ),
                    ],
                  ),
                  TextFormField(
                    controller: _razonController,
                    decoration: const InputDecoration(labelText: 'Razón'),
                  ),
                  TextFormField(
                    controller: _notasController,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                  Row(
                    children: [
                      const Text('Activo:'),
                      Switch(
                        value: _activo,
                        onChanged: (val) => setState(() => _activo = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      minimumSize: const Size.fromHeight(50),
                    ),
                    onPressed: _submitTratamiento,
                    child: const Text('Agregar Tratamiento', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
