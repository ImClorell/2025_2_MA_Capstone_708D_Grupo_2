import 'package:flutter/material.dart';
import 'package:agendai/services/notification_service.dart';

class TestNotificacionPage extends StatefulWidget {
  const TestNotificacionPage({super.key});

  @override
  State<TestNotificacionPage> createState() => _TestNotificacionPageState();
}

class _TestNotificacionPageState extends State<TestNotificacionPage> {
  DateTime _scheduled = DateTime.now().add(const Duration(minutes: 1));

  Future<void> _pickDateTime() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _scheduled,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (fecha == null) return;

    // Evitar usar context si se desmontó
    if (!mounted) return;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduled),
    );

    if (hora == null) return;

    if (!mounted) return;

    setState(() {
      _scheduled = DateTime(
        fecha.year,
        fecha.month,
        fecha.day,
        hora.hour,
        hora.minute,
      );
    });
  }

  Future<void> _probar() async {
    await NotificationService.schedule(
      id: 999,
      title: 'Prueba de notificación',
      body: 'Esto es un test local',
      scheduledUtc: _scheduled.toUtc(),
    );

    // Evitar usar context después de un await
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notificación programada")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Probar Notificaciones")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Programada para:",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(_scheduled.toLocal().toString().substring(0, 16)),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _pickDateTime,
              child: const Text("Cambiar fecha y hora"),
            ),

            ElevatedButton(
              onPressed: _probar,
              child: const Text("Programar prueba"),
            ),
          ],
        ),
      ),
    );
  }
}
