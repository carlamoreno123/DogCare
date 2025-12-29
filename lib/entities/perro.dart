class Perro {
  int? idperro;
  String nombre;
  String? propietario;
  String? raza;
  DateTime? nacimiento;
  String? _sexo; // privado
  String? chip;
  String? notas;
  String? imagen;

  Perro({
    this.idperro,
    required this.nombre,
    this.propietario,
    this.raza,
    this.nacimiento,
    String? sexo,
    this.chip,
    this.notas,
    this.imagen,
  }) {
    this.sexo = sexo; 
  }

  // setter solo 'M' o 'F'
  set sexo(String? value) {
    if (value != null && value.toUpperCase() != 'M' && value.toUpperCase() != 'F') {
      throw ArgumentError('Sexo debe ser "M" o "F"');
    }
    _sexo = value?.toUpperCase();
  }

  // Getter
  String? get sexo => _sexo;

  // Crear Perro desde JSON (de la API)
  factory Perro.fromJson(Map<String, dynamic> json) {
    int? parseId(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    DateTime? parseNacimiento(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      final s = v.toString();
      // try ISO parse first
      try {
        return DateTime.parse(s);
      } catch (_) {
        final n = int.tryParse(s);
        if (n != null) return DateTime.fromMillisecondsSinceEpoch(n);
      }
      return null;
    }

    return Perro(
      idperro: parseId(json['idperro']),
      nombre: json['nombre'] ?? '',
      propietario: json['propietario'],
      raza: json['raza'],
      nacimiento: parseNacimiento(json['nacimiento']),
      sexo: json['sexo'],
      chip: json['chip'],
      notas: json['notas'],
      imagen: json['imagen'],
    );
  }

  // Convertir Perro a JSON (para enviar a la API)
  Map<String, dynamic> toJson() {
    return {
      "idperro": idperro,
      "nombre": nombre,
      "propietario": propietario,
      "raza": raza,
      "nacimiento": nacimiento != null ? nacimiento!.toIso8601String().split('T')[0] : null,
      "sexo": sexo,
      "chip": chip,
      "notas": notas,
      "imagen": imagen,
    };
  }
}
