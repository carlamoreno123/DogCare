class Tratamiento {
  int idTratamiento;
  int idPerro;
  String tratamiento;
  String dosis;
  int veces_dia;
  DateTime fecha_inicio;
  DateTime fecha_fin;
  String razon;
  bool activo;
  String notas;

  Tratamiento({
    required this.idTratamiento,
    required this.idPerro,
    required this.tratamiento,
    required this.dosis,
    required this.veces_dia,
    required this.fecha_inicio,
    required this.fecha_fin,
    required this.razon,
    this.activo = true,
    this.notas = "",
  });

  // De JSON
 factory Tratamiento.fromJson(Map<String, dynamic> json) {
  return Tratamiento(
    idTratamiento: int.tryParse(json['idtratamiento']?.toString() ?? '') ?? 0,
    idPerro: int.tryParse(json['idperro']?.toString() ?? '') ?? 0,
    tratamiento: json['tratamiento']?.toString() ?? '',
    dosis: json['dosis']?.toString() ?? '',
    veces_dia: int.tryParse(json['vecesDia']?.toString() ?? json['veces_dia']?.toString() ?? '') ?? 0,
    fecha_inicio: DateTime.tryParse(json['fechaInicio']?.toString() ?? json['fecha_inicio']?.toString() ?? '') ?? DateTime.now(),
    fecha_fin: DateTime.tryParse(json['fechaFin']?.toString() ?? json['fecha_fin']?.toString() ?? '') ?? DateTime.now(),
    razon: json['razon']?.toString() ?? '',
    notas: json['notas']?.toString() ?? '',
    activo: json['activo'] == 1 || json['activo'] == true || json['activo']?.toString() == '1',
  );
}


  // A JSON
  Map<String, dynamic> toJson() {
    return {
      'idtratamiento': idTratamiento,
      'idperro': idPerro,
      'tratamiento': tratamiento,
      'dosis': dosis,
      'veces_dia': veces_dia,
      'fecha_inicio': fecha_inicio.toIso8601String(),
      'fecha_fin': fecha_fin.toIso8601String(),
      'razon': razon,
      'activo': activo ? 1 : 0,
      'notas': notas,
    };
  }
}
