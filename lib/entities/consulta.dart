class Consulta {
  int? idconsulta;
  int? idperro;
  String perro;
  String tipo;
  DateTime fecha;
  String coste;
  String veterinario;
  String diagnostico;
  String notes;

  Consulta({
    this.idconsulta,
    this.idperro,
    required this.perro,
    this.tipo = '',
    required this.fecha,
    this.coste = '',
    this.veterinario = '',
    this.diagnostico = '',
    this.notes = '',
  });

  factory Consulta.fromJson(Map<String, dynamic> json) {
    return Consulta(
      idconsulta: json['idconsulta'] != null ? int.tryParse(json['idconsulta'].toString()) : null,
      idperro: json['idperro'] != null ? int.tryParse(json['idperro'].toString()) : null,
      perro: json['perro'] ?? json['nombre'] ?? '',
      tipo: json['tipo'] ?? '',
      fecha: json['fecha'] != null
          ? DateTime.tryParse(json['fecha'].toString()) ?? DateTime.now()
          : DateTime.now(),
      coste: json['coste']?.toString() ?? '',
      veterinario: json['veterinario'] ?? '',
      diagnostico: json['diagnostico'] ?? '',
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idconsulta': idconsulta,
      'idperro': idperro,
      'perro': perro,
      'tipo': tipo,
      'fecha': fecha.toIso8601String(),
      'coste': coste,
      'veterinario': veterinario,
      'diagnostico': diagnostico,
      'notes': notes,
    };
  }
}
