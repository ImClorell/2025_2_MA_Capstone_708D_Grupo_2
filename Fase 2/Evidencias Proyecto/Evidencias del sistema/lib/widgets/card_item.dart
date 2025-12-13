import 'package:flutter/material.dart';

class CardItem extends StatelessWidget {
  final String titulo;
  final String? contenido;
  final String? extra;

  const CardItem({
    super.key,
    required this.titulo,
    this.contenido,
    this.extra,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(titulo),
        subtitle: Text(contenido ?? ''),
        trailing: extra != null ? Text(extra!) : null,
      ),
    );
  }
}
