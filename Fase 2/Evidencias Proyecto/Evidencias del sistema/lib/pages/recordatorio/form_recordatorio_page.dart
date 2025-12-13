import 'package:flutter/material.dart';
import 'package:agendai/models/nota.dart';
import 'package:agendai/models/recordatorio.dart';
import 'package:agendai/models/rutina.dart';
import 'package:agendai/services/notification_service.dart';
import 'package:agendai/services/notas_service.dart';
import 'package:agendai/services/recordatorios_service.dart';
import 'package:agendai/services/rutinas_service.dart';

class FormRecordatorioPage extends StatefulWidget {
  final Recordatorio? existente;

  const FormRecordatorioPage({super.key, this.existente});

  @override
  State<FormRecordatorioPage> createState() => _FormRecordatorioPageState();
}

class _FormRecordatorioPageState extends State<FormRecordatorioPage> {
  final _formKey = GlobalKey<FormState>();
  final _tituloCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();

  // Fecha y hora combinadas
  DateTime _fechaHora = DateTime.now().add(const Duration(hours: 1));

  // Tipo se sigue usando internamente, pero ya no se muestra
  String _tipo = 'personal';

  // Nuevos: prioridad y estado (como en la imagen)
  String _prioridad = 'media'; // baja / media / alta
  String _estado = 'activo'; // activo / pendiente / completado

  final _service = RecordatoriosService();
  final _notasService = NotasService();
  final _rutinasService = RutinasService();

  static const int _prealertMinutes = 15;

  @override
  void initState() {
    super.initState();

    final r = widget.existente;
    if (r != null) {
      _tituloCtrl.text = r.titulo;
      _descripcionCtrl.text = r.mensaje ?? '';
      _tipo = r.tipo;
      _fechaHora = r.programadoEn.toLocal();

      if (r.prioridad != null && r.prioridad!.isNotEmpty) {
        _prioridad = r.prioridad!.toLowerCase();
      }
      if (r.estado.isNotEmpty) {
        _estado = r.estado.toLowerCase();
      }
    } else {
      _prioridad = 'media';
      _estado = 'activo';
    }
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    super.dispose();
  }

  // Helpers de formato
  String _formatearFecha(DateTime fecha) {
    final f = fecha.toLocal();
    final dd = f.day.toString().padLeft(2, '0');
    final mm = f.month.toString().padLeft(2, '0');
    final yyyy = f.year.toString();
    return '$dd/$mm/$yyyy';
  }

  String _formatearHora(BuildContext context, DateTime fecha) {
    final t = TimeOfDay.fromDateTime(fecha.toLocal());
    return t.format(context);
  }

  Future<void> _pickFecha() async {
    final fechaInicial = _fechaHora;
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _fechaHora = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _fechaHora.hour,
        _fechaHora.minute,
      );
    });
  }

  Future<void> _pickHora() async {
    final horaInicial = TimeOfDay.fromDateTime(_fechaHora);
    final picked = await showTimePicker(
      context: context,
      initialTime: horaInicial,
    );

    if (picked == null || !mounted) return;

    setState(() {
      _fechaHora = DateTime(
        _fechaHora.year,
        _fechaHora.month,
        _fechaHora.day,
        picked.hour,
        picked.minute,
      );
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final colisiones = await _buscarColisiones(_fechaHora);
    if (colisiones.isNotEmpty) {
      final continuar = await _mostrarAdvertenciaColisiones(colisiones);
      if (continuar != true) return;
    }

    final nuevo = Recordatorio(
      id: widget.existente?.id ?? 0,
      usuarioId: "", // se completa en el servicio si hace falta
      tipo: _tipo,
      estado: _estado, // ahora usamos el valor elegido
      titulo: _tituloCtrl.text.trim(),
      mensaje: _descripcionCtrl.text.trim().isEmpty
          ? null
          : _descripcionCtrl.text.trim(),
      programadoEn: _fechaHora.toUtc(),
      tz: NotificationService.defaultTimeZone,
      notaId: widget.existente?.notaId,
      rutinaId: widget.existente?.rutinaId,
      prioridad: _prioridad,
    );

    try {
      // Guardar en Supabase (o donde lo maneje tu servicio)
      if (widget.existente == null) {
        await _service.crear(nuevo);
      } else {
        await _service.actualizar(widget.existente!.id, nuevo);
      }

      // Programar notificación local
      await NotificationService.schedule(
        id: widget.existente?.id ??
            DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: _tituloCtrl.text.trim().isEmpty
            ? 'Recordatorio'
            : _tituloCtrl.text.trim(),
        body: _descripcionCtrl.text.trim().isEmpty
            ? null
            : _descripcionCtrl.text.trim(),
        scheduledUtc: _fechaHora.toUtc(),
        prealertMinutes: _prealertMinutes,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.existente == null
                ? 'Recordatorio guardado'
                : 'Recordatorio actualizado',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e, stack) {
      // Aquí ves el error real (incluido el CHECK constraint de estado)
      debugPrint('Error al guardar recordatorio: $e');
      debugPrint(stack.toString());

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar el recordatorio: $e'),
        ),
      );
    }
  }

  bool _mismoMinuto(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year &&
        la.month == lb.month &&
        la.day == lb.day &&
        la.hour == lb.hour &&
        la.minute == lb.minute;
  }

  Future<List<String>> _buscarColisiones(DateTime fechaHora) async {
    final List<String> conflictos = [];

    // Recordatorios existentes
    final recordatorios = await _service.listar();
    for (final r in recordatorios) {
      if (widget.existente != null && r.id == widget.existente!.id) continue;
      if (_mismoMinuto(r.programadoEn, fechaHora)) {
        conflictos.add('Recordatorio: ${r.titulo}');
      }
    }

    // Notas con vencimiento
    final notas = await _notasService.listar();
    for (final Nota n in notas) {
      if (n.venceEn != null && _mismoMinuto(n.venceEn!, fechaHora)) {
        conflictos.add('Nota: ${n.titulo}');
      }
    }

    // Rutinas (primer ocurrencia)
    final rutinas = await _rutinasService.listar();
    for (final Rutina r in rutinas) {
      if (r.fechaInicio != null && r.hora != null && r.hora!.contains(':')) {
        final partes = r.hora!.split(':');
        final h = int.tryParse(partes[0]) ?? 0;
        final m = int.tryParse(partes[1]) ?? 0;
        final fechaRutina = DateTime(
          r.fechaInicio!.year,
          r.fechaInicio!.month,
          r.fechaInicio!.day,
          h,
          m,
        );
        if (_mismoMinuto(fechaRutina, fechaHora)) {
          conflictos.add('Rutina: ${r.nombre}');
        }
      }
    }

    return conflictos;
  }

  Future<bool?> _mostrarAdvertenciaColisiones(List<String> colisiones) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Advertencia de horario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Hay elementos en el mismo horario. ¿Quieres continuar?'),
            const SizedBox(height: 8),
            ...colisiones.map((c) => Text('• $c')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.existente != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorCard = isDark ? Colors.grey[900]! : Colors.grey[100]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          esEdicion ? 'Editar Recordatorio' : 'Nuevo Recordatorio',
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF8C3C37),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: colorCard,
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'El título es obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descripcionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fecha
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 24, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Fecha: ${_formatearFecha(_fechaHora)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: _pickFecha,
                        child: const Text(
                          'Cambiar',
                          style: TextStyle(color: Color(0xFF8C3C37)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Hora
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 24, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hora: ${_formatearHora(context, _fechaHora)}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: _pickHora,
                        child: const Text(
                          'Cambiar',
                          style: TextStyle(color: Color(0xFF8C3C37)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Prioridad
                  DropdownButtonFormField<String>(
                    initialValue: _prioridad,
                    decoration: const InputDecoration(
                      labelText: 'Prioridad',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'baja',
                        child: Text('Baja'),
                      ),
                      DropdownMenuItem(
                        value: 'media',
                        child: Text('Media'),
                      ),
                      DropdownMenuItem(
                        value: 'alta',
                        child: Text('Alta'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _prioridad = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Estado
                  DropdownButtonFormField<String>(
                    initialValue: _estado,
                    decoration: const InputDecoration(
                      labelText: 'Estado',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'activo',
                        child: Text('Activo'),
                      ),
                      DropdownMenuItem(
                        value: 'pendiente',
                        child: Text('Pendiente'),
                      ),
                      DropdownMenuItem(
                        value: 'completado',
                        child: Text('Completado'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _estado = value);
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Botón guardar / actualizar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8C3C37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: Text(esEdicion ? 'Actualizar' : 'Guardar'),
                      onPressed: _guardar,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
