import 'package:flutter/material.dart';
import 'form_recordatorio_page.dart';
import '../../models/recordatorio.dart';
import '../../services/recordatorios_service.dart';

class DetalleRecordatorioPage extends StatelessWidget {
  final Recordatorio recordatorio;

  // static → no forma parte del estado de la instancia, permite constructor const
  static final RecordatoriosService _service = RecordatoriosService();

  const DetalleRecordatorioPage({super.key, required this.recordatorio});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorCard = isDark ? Colors.grey[900]! : Colors.grey[100]!;

    final local = recordatorio.programadoEn.toLocal();
    final fechaFormateada =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
    final horaFormateada = TimeOfDay.fromDateTime(local).format(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Recordatorio'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Card(
            color: colorCard,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 Título con ícono
                  Row(
                    children: const [
                      Icon(Icons.alarm, color: Colors.orangeAccent, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Recordatorio',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 🔹 Título principal
                  Text(
                    recordatorio.titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // 🔹 Mensaje / descripción
                  Text(
                    recordatorio.mensaje ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),

                  // 🔹 Fecha
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Fecha: $fechaFormateada',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 🔹 Hora
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          color: Colors.orangeAccent, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Hora: $horaFormateada',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 🔹 Tipo
                  Row(
                    children: [
                      const Icon(Icons.flag, color: Colors.amber, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Tipo: ${recordatorio.tipo}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 🔹 Estado
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Estado: ${recordatorio.estado}',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // 🔹 Programado el (usamos la misma fecha)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      'Programado el $fechaFormateada',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 🔹 Botones Editar / Eliminar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8C3C37),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        onPressed: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  FormRecordatorioPage(existente: recordatorio),
                            ),
                          );
                          if (!context.mounted) return;
                          if (result == true) {
                            Navigator.pop(context, true);
                          }
                        },
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.delete),
                        label: const Text('Eliminar'),
                        onPressed: () {
                          _confirmarEliminacion(context);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarEliminacion(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Recordatorio'),
        content:
            const Text('¿Seguro que deseas eliminar este recordatorio?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8C3C37),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _service.eliminar(recordatorio.id);

              if (!dialogContext.mounted) return;
              Navigator.pop(dialogContext); // cerrar diálogo

              if (!context.mounted) return;
              Navigator.pop(context, true); // volver a la lista

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Recordatorio eliminado')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
