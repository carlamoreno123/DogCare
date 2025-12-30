import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../entities/perro.dart';
import 'EditarPerro.dart';

class FichaPerro extends StatefulWidget {
  final Perro perro;
  const FichaPerro({super.key, required this.perro});

  @override
  State<FichaPerro> createState() => _FichaPerroState();
}

class _FichaPerroState extends State<FichaPerro> {
  late final List<String> _candidates;
  int _current = 0;

  @override
  void initState() {
    super.initState();
    final imagen = widget.perro.imagen;
    if (imagen == null) {
      _candidates = [];
    } else if (imagen.toLowerCase().startsWith('http')) {
      _candidates = [imagen];
    } else {
      _candidates = ['http://172.22.12.23/api_dogcare/$imagen'];
    }

    SchedulerBinding.instance.addPostFrameCallback((_) {
      debugPrint(
        'Opening FichaPerro: id=${widget.perro.idperro}, nombre=${widget.perro.nombre}',
      );
    });
  }

  String? get _imageUrl => _candidates.isEmpty ? null : _candidates[_current];

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // HEADER: Back + Edit
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.teal, size: 30),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.teal, size: 26),
                      onPressed: () async {
                        final edited = await Navigator.push<Perro>(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditarPerroScreen(perro: widget.perro),
                          ),
                        );
                        if (edited != null) {
                          setState(() {
                            widget.perro.nombre = edited.nombre;
                            widget.perro.raza = edited.raza;
                            widget.perro.propietario = edited.propietario;
                            widget.perro.nacimiento = edited.nacimiento;
                            widget.perro.sexo = edited.sexo;
                            widget.perro.chip = edited.chip;
                            widget.perro.notas = edited.notas;
                            widget.perro.imagen = edited.imagen;
                          });
                        }
                      },
                    ),
                  ],
                ),

                // 🔙 BOTÓN BACK
                const SizedBox(height: 10),

                // 🐶 FOTO
                _imageUrl != null
                    ? BounceIn(
                        duration: const Duration(milliseconds: 3000),
                      child: CircleAvatar(
                          radius: 85,
                          backgroundColor: Colors.white,
                          backgroundImage: NetworkImage(_imageUrl!),
                          onBackgroundImageError: (_, __) {},
                        ),
                    )
                    : const CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.pets, size: 80, color: Colors.white),
                      ),

                const SizedBox(height: 16),

                // 🐾 NOMBRE
                Text(
                  widget.perro.nombre,
                  style: const TextStyle(
                    fontSize: 33,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  widget.perro.raza ?? 'Sin raza',
                  style: const TextStyle(color: Colors.black54, fontSize: 18),
                ),

                const SizedBox(height: 30),

                // 📋 INFO
                _infoCard(
                  Icons.person,
                  'Propietario',
                  widget.perro.propietario,
                ),
                _infoCard(Icons.pets, 'Raza', widget.perro.raza),
                _infoCard(
                  Icons.cake,
                  'Nacimiento',
                  widget.perro.nacimiento != null
                      ? '${widget.perro.nacimiento!.day}-${widget.perro.nacimiento!.month}-${widget.perro.nacimiento!.year}'
                      : '-',
                ),
                _infoCard(Icons.male, 'Sexo', widget.perro.sexo),
                _infoCard(Icons.qr_code, 'Chip', widget.perro.chip),
                _infoCard(Icons.notes, 'Notas', widget.perro.notas),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🪪 CARD INFO
  Widget _infoCard(IconData icon, String label, String? value) {
    return BounceInLeft(
      delay: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.withOpacity(0.15),
              child: Icon(icon, color: Colors.teal),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(value ?? '-', style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
