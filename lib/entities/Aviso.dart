class Aviso {
   int idAviso; 
  String titulo;
  String descripcion;
  DateTime fechaRecordatorio;
  bool completado;
  int idPerro;

  Aviso({ 
    required this.idAviso,
    required this.titulo,
    required this.descripcion,
    required this.fechaRecordatorio,
    required this.completado,
    required this.idPerro,
  });

  factory Aviso.fromJson(Map<String, dynamic> json) => Aviso(
        idAviso: json['idAviso'],
        titulo: json['titulo'],
        descripcion: json['descripcion'],
        fechaRecordatorio: DateTime.parse(json['fechaRecordatorio']),
        completado: json['completado'] == 1,
        idPerro: json['idperro'],
      );
}
  