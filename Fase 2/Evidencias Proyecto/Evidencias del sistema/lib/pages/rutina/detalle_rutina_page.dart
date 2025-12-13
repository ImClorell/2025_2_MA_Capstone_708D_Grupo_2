import 'package:flutter/material.dart';
import 'form_rutina_page.dart';
import '../../models/rutina.dart';
import '../../services/rutinas_service.dart';

class DetalleRutinaPage extends StatelessWidget {
  final Rutina rutina;

  const DetalleRutinaPage({super.key, required this.rutina});

  String _formatearFecha(DateTime fecha) =>
      '${fecha.day.toString().padLeft(2, '0')}/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorCard = isDark ? Colors.grey[900]! : Colors.grey[100]!;

    // Reconstruimos "recordatorio" a partir de tu modelo:
    // fechaInicio (DateTime?) + hora (String "HH:mm")
    DateTime? fechaRec;
    TimeOfDay? horaRec;

    if (rutina.fechaInicio != null &&
        rutina.hora != null &&
        rutina.hora!.contains(':')) {
      try {
        final partes = rutina.hora!.split(':');
        final h = int.parse(partes[0]);
        final m = int.parse(partes[1]);
        fechaRec = rutina.fechaInicio;
        horaRec = TimeOfDay(hour: h, minute: m);
      } catch (_) {
        fechaRec = null;
        horaRec = null;
      }
    }

    final String? fechaTexto =
        fechaRec != null ? _formatearFecha(fechaRec) : null;
    final String? horaTexto = horaRec?.format(context);

    // Texto para frecuencia y estado (mostramos lo guardado)
    final String frecuenciaTexto = rutina.frecuencia ?? '-';
    final String estadoTexto = rutina.estado;

    // "Creado el": usamos fechaInicio como aproximación
    final String creadaTexto = rutina.fechaInicio != null
        ? _formatearFecha(rutina.fechaInicio!)
        : '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de Rutina'),
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
                  // Encabezado
                  Row(
                    children: const [
                      Icon(Icons.repeat, color: Colors.green, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Rutina',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Nombre
                  Text(
                    rutina.nombre,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Descripción / detalle
                  Text(
                    rutina.descripcion ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const Divider(height: 24),

                  // Frecuencia
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          color: Colors.blueAccent, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Frecuencia: $frecuenciaTexto',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Estado
                  Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Estado: $estadoTexto',
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),

                  // 🔔 Bloque de recordatorio (solo si existe fecha+hora)
                  if (fechaTexto != null && horaTexto != null) ...[
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        Icon(Icons.alarm,
                            color: Colors.orangeAccent, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Recordatorio',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.event,
                            size: 18, color: Colors.redAccent),
                        const SizedBox(width: 6),
                        Text('Fecha: $fechaTexto'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 18, color: Colors.orangeAccent),
                        const SizedBox(width: 6),
                        Text('Hora: $horaTexto'),
                      ],
                    ),
                  ],

                  const Divider(height: 24),

                  // Fecha creación
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      'Creado el $creadaTexto',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 20),

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
                              horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                        onPressed: () async {
                          // 👇 Capturamos el navigator ANTES del await
                          final navigator = Navigator.of(context);

                          final result = await navigator.push(
                            MaterialPageRoute(
                              builder: (_) =>
                                  FormRutinaPage(existente: rutina),
                            ),
                          );

                          if (!navigator.mounted) return;
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
                              horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.delete),
                        label: const Text('Eliminar'),
                        onPressed: () => _confirmarEliminacion(context),
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
    final service = RutinasService();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar Rutina'),
        content: const Text(
          '¿Seguro que deseas eliminar esta rutina permanentemente?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8C3C37),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              // No usamos await para no tener el warning de use_build_context_synchronously
              service.eliminar(rutina.id);
              Navigator.pop(context); // cerrar diálogo
              Navigator.pop(context, true); // volver a la lista
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Rutina eliminada')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
