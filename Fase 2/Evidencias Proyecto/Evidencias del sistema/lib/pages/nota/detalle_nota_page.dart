// lib/pages/nota/detalle_nota_page.dart
import 'package:flutter/material.dart';
import 'package:agendai/models/nota.dart';
import 'package:agendai/services/notas_service.dart';
import 'form_nota_page.dart';

class DetalleNotaPage extends StatefulWidget {
  final Nota nota;

  const DetalleNotaPage({super.key, required this.nota});

  @override
  State<DetalleNotaPage> createState() => _DetalleNotaPageState();
}

class _DetalleNotaPageState extends State<DetalleNotaPage> {
  final _service = NotasService();

  Color _colorEtiqueta(String etiqueta, bool isDark) {
    if (etiqueta.isEmpty) {
      return isDark ? Colors.grey[800]! : Colors.grey[300]!;
    }

    try {
      final etiquetaEncontrada = FormNotaPage.etiquetasDisponibles.firstWhere(
        (e) => (e['nombre'] as String).toLowerCase().trim() ==
            etiqueta.toLowerCase().trim(),
        orElse: () => {},
      );

      if (etiquetaEncontrada.isNotEmpty &&
          etiquetaEncontrada['color'] != null) {
        return etiquetaEncontrada['color'] as Color;
      }
      return isDark ? Colors.grey[800]! : Colors.grey[300]!;
    } catch (_) {
      return isDark ? Colors.grey[800]! : Colors.grey[300]!;
    }
  }

  Color _colorPrioridad(String prioridad) {
    final p = prioridad.toLowerCase();
    if (p.contains('alta')) return Colors.redAccent;
    if (p.contains('media')) return Colors.orangeAccent;
    if (p.contains('baja')) return Colors.green;
    return Colors.grey;
  }

  String _capitalizar(String texto) {
    if (texto.isEmpty) return texto;
    return texto[0].toUpperCase() + texto.substring(1);
  }

  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin recordatorio';
    final d = fecha.toLocal();
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final anio = d.year.toString();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio - $h:$m';
  }

  String _formatFechaCorta(DateTime? fecha) {
    if (fecha == null) return '';
    final d = fecha.toLocal();
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final anio = d.year.toString();
    return '$dia/$mes/$anio';
  }

  Future<void> _confirmarEliminar() async {
    // Capturamos las dependencias de contexto ANTES del await
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar nota'),
        content: const Text('¿Seguro que deseas eliminar esta nota?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(dialogContext, false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _service.eliminar(widget.nota.id!);
      // Usamos navigator y messenger capturados, ya no accedemos a context aquí
      navigator.pop(true);
      messenger.showSnackBar(
        const SnackBar(content: Text('Nota eliminada')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error al eliminar la nota: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final nota = widget.nota;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorCard = isDark ? Colors.grey[900]! : Colors.grey[100]!;
    final colorTexto = isDark ? Colors.white : Colors.black87;
    final colorSub = isDark ? Colors.white70 : Colors.grey[700];

    final tieneDescripcion = (nota.descripcion ?? '').trim().isNotEmpty;
    final tieneDetalle = (nota.detalle ?? '').trim().isNotEmpty;
    final tieneEtiqueta = (nota.etiqueta ?? '').trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de nota'),
        centerTitle: true,
        backgroundColor: const Color(0xFF8C3C37),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: colorCard,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título + pin
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        nota.titulo,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: colorTexto,
                        ),
                      ),
                    ),
                    if (nota.fijada)
                      const Icon(
                        Icons.push_pin,
                        color: Colors.amber,
                        size: 20,
                      ),
                  ],
                ),
                const SizedBox(height: 6),

                // Fechas pequeña
                if (nota.creadoEn != null || nota.actualizadoEn != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      [
                        if (nota.creadoEn != null)
                          'Creada: ${_formatFechaCorta(nota.creadoEn)}',
                        if (nota.actualizadoEn != null)
                          'Actualizada: ${_formatFechaCorta(nota.actualizadoEn)}',
                      ].join('   •   '),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorSub,
                      ),
                    ),
                  ),

                const Divider(),

                // Descripción
                if (tieneDescripcion) ...[
                  Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorTexto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nota.descripcion!,
                    style: TextStyle(
                      fontSize: 15,
                      color: colorSub,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],

                // Detalle
                if (tieneDetalle) ...[
                  Text(
                    'Detalle',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorTexto,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nota.detalle!,
                    style: TextStyle(
                      fontSize: 15,
                      color: colorSub,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],

                // Etiqueta
                if (tieneEtiqueta) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.label_outline,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _colorEtiqueta(nota.etiqueta ?? '', isDark),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          nota.etiqueta!,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.grey[900],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],

                // Prioridad
                Row(
                  children: [
                    Icon(
                      Icons.flag,
                      color: _colorPrioridad(nota.prioridad),
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Prioridad: ${_capitalizar(nota.prioridad)}',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorSub,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Estado
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Estado: ${_capitalizar(nota.estado)}',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorSub,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Recordatorio
                Row(
                  children: [
                    const Icon(
                      Icons.access_time,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Recordatorio: ${_formatFecha(nota.venceEn)}',
                      style: TextStyle(
                        fontSize: 15,
                        color: colorSub,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Botones Editar / Eliminar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Editar
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8C3C37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar'),
                      onPressed: () async {
                        final navigator = Navigator.of(context);

                        final result = await navigator.push(
                          MaterialPageRoute(
                            builder: (_) => FormNotaPage(nota: nota),
                          ),
                        );

                        if (result == true) {
                          navigator.pop(true);
                        }
                      },
                    ),

                    // Eliminar
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: const Icon(Icons.delete),
                      label: const Text('Eliminar'),
                      onPressed: _confirmarEliminar,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
