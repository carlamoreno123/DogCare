class Aviso {
  int idAviso;
  int idPerro;
  String titulo;
  String descripcion;
  DateTime fechaRecordatorio;
  bool completado;

  Aviso({
    required this.idAviso,
    required this.idPerro,
    required this.titulo,
    required this.descripcion,
    required this.fechaRecordatorio,
    required this.completado,
  });

  factory Aviso.fromJson(Map<String, dynamic> json) {
    return Aviso(
      idAviso: json['IdAviso'] != null ? int.parse(json['IdAviso'].toString()) : 0,
      idPerro: json['idperro'] != null ? int.parse(json['idperro'].toString()) : 0,
      titulo: json['titulo'] ?? '',
      descripcion: json['descripcion'] ?? '',
      fechaRecordatorio: json['fechaRecordatorio'] != null
          ? DateTime.parse(json['fechaRecordatorio'])
          : DateTime.now(),
      completado: json['completado'] != null && json['completado'].toString() == '1',
    );
  }
}
