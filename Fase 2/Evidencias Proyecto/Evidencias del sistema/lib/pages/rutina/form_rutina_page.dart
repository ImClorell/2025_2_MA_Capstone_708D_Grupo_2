import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:agendai/models/rutina.dart';
import 'package:agendai/services/notification_service.dart';
import 'package:agendai/services/notas_service.dart';
import 'package:agendai/services/recordatorios_service.dart';
import 'package:agendai/services/rutinas_service.dart';

class FormRutinaPage extends StatefulWidget {
  final Rutina? existente;

  const FormRutinaPage({super.key, this.existente});

  @override
  State<FormRutinaPage> createState() => _FormRutinaPageState();
}

class _FormRutinaPageState extends State<FormRutinaPage> {
  final _formKey = GlobalKey<FormState>();

  // Campos visuales (UI)
  String nombre = '';
  String detalle = '';
  String frecuencia = 'Diaria'; // Texto bonito para la UI
  String estado = 'Activa';     // Texto bonito para la UI

  // Siempre habrá recordatorio: fecha + hora obligatorias
  DateTime? fechaRecordatorio;
  TimeOfDay? horaRecordatorio;

  // Lista base de frecuencias
  final List<String> frecuencias = [
    'Diaria',
    'Semanal',
    '3 veces por semana',
    'Lunes a Viernes',
    'Mensual',
  ];

  // Días de la semana para la opción "3 veces por semana"
  final List<Map<String, String>> _diasSemana = const [
    {'key': 'lunes', 'label': 'Lun'},
    {'key': 'martes', 'label': 'Mar'},
    {'key': 'miércoles', 'label': 'Mié'},
    {'key': 'jueves', 'label': 'Jue'},
    {'key': 'viernes', 'label': 'Vie'},
    {'key': 'sábado', 'label': 'Sáb'},
    {'key': 'domingo', 'label': 'Dom'},
  ];

  // Días seleccionados cuando frecuencia = "3 veces por semana"
  List<String> _diasSeleccionados = [];

  // Día del mes cuando frecuencia = "Mensual"
  int? _diaMensual;

  final _service = RutinasService();
  final _notasService = NotasService();
  final _recordatoriosService = RecordatoriosService();

  static const int _prealertMinutes = 15;

  @override
  void initState() {
    super.initState();

    final r = widget.existente;
    if (r != null) {
      // Nombre y detalle (descripcion en el modelo)
      nombre = r.nombre;
      detalle = r.descripcion ?? '';

      // Mapear frecuencia de BD → UI
      if (r.frecuencia != null && r.frecuencia!.trim().isNotEmpty) {
        final f = r.frecuencia!.trim().toLowerCase();
        if (f == 'diaria') {
          frecuencia = 'Diaria';
        } else if (f == 'semanal') {
          frecuencia = 'Semanal';
        } else if (f == 'mensual') {
          frecuencia = 'Mensual';
        } else if (f == '3_veces_por_semana') {
          frecuencia = '3 veces por semana';
        } else if (f == 'lunes_a_viernes') {
          frecuencia = 'Lunes a Viernes';
        } else {
          frecuencia = r.frecuencia!;
        }
        if (!frecuencias.contains(frecuencia)) {
          frecuencias.add(frecuencia);
        }
      }

      // Si es "3 veces por semana", cargamos los días desde reglaPersonalizada
      if (frecuencia == '3 veces por semana' &&
          r.reglaPersonalizada != null &&
          r.reglaPersonalizada!.trim().isNotEmpty) {
        _diasSeleccionados = r.reglaPersonalizada!
            .split(',')
            .map((d) => d.trim().toLowerCase())
            .where((d) => d.isNotEmpty)
            .toList();
      }

      // Si es "Mensual", interpretamos reglaPersonalizada como número de día
      if (frecuencia == 'Mensual' &&
          r.reglaPersonalizada != null &&
          r.reglaPersonalizada!.trim().isNotEmpty) {
        _diaMensual = int.tryParse(r.reglaPersonalizada!.trim());
      }

      // Mapear estado de BD → UI
      if (r.estado.trim().isNotEmpty) {
        final e = r.estado.trim().toLowerCase();
        // Leemos tanto "activo" como "activa" para que al editar no falle
        if (e == 'activa' || e == 'activo') {
          estado = 'Activa';
        } else if (e == 'completada' || e == 'completado' || e == 'completo') {
          estado = 'Completada';
        } else if (e == 'archivada' || e == 'archivado') {
          estado = 'Archivada';
        }
      }

      // Reconstruir fecha / hora de recordatorio a partir de fechaInicio + hora ("HH:mm")
      if (r.fechaInicio != null && r.hora != null && r.hora!.contains(':')) {
        try {
          final partes = r.hora!.split(':');
          final h = int.parse(partes[0]);
          final m = int.parse(partes[1]);

          fechaRecordatorio = r.fechaInicio;
          horaRecordatorio = TimeOfDay(hour: h, minute: m);
        } catch (_) {
          fechaRecordatorio = DateTime.now().add(const Duration(days: 1));
          horaRecordatorio = const TimeOfDay(hour: 9, minute: 0);
        }
      } else {
        // Valores por defecto si la rutina no tenía programación
        fechaRecordatorio = DateTime.now().add(const Duration(days: 1));
        horaRecordatorio = const TimeOfDay(hour: 9, minute: 0);
      }
    } else {
      // Nueva rutina: sugerimos mañana a las 9:00 AM
      fechaRecordatorio = DateTime.now().add(const Duration(days: 1));
      horaRecordatorio = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  String formatFecha(DateTime? fecha) {
    if (fecha == null) return 'No seleccionada';
    return DateFormat('dd/MM/yyyy').format(fecha);
  }

  String formatHora(TimeOfDay? hora) {
    if (hora == null) return 'No seleccionada';
    return hora.format(context);
  }

  Future<void> _seleccionarFecha() async {
    final seleccion = await showDatePicker(
      context: context,
      initialDate: fechaRecordatorio ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (seleccion != null) {
      setState(() => fechaRecordatorio = seleccion);
    }
  }

  Future<void> _seleccionarHora() async {
    final seleccion = await showTimePicker(
      context: context,
      initialTime: horaRecordatorio ?? TimeOfDay.now(),
    );
    if (seleccion != null) {
      setState(() => horaRecordatorio = seleccion);
    }
  }

  // Selector visual de día del mes usando calendario
  Future<void> _seleccionarDiaMensual() async {
    final ahora = DateTime.now();
    final initial = DateTime(
      ahora.year,
      ahora.month,
      _diaMensual != null && _diaMensual! >= 1 && _diaMensual! <= 31
          ? _diaMensual!
          : ahora.day,
    );

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(ahora.year, ahora.month, 1),
      lastDate: DateTime(
        ahora.year,
        ahora.month,
        DateUtils.getDaysInMonth(ahora.year, ahora.month),
      ),
      helpText: 'Elige un día del mes',
    );

    if (picked != null) {
      setState(() {
        _diaMensual = picked.day;
      });
    }
  }

  // Convierte frecuencia "bonita" → valor para BD
  String _frecuenciaParaBD(String fUi) {
    switch (fUi) {
      case 'Diaria':
        return 'diaria';
      case 'Semanal':
        return 'semanal';
      case 'Mensual':
        return 'mensual';
      case '3 veces por semana':
        return '3_veces_por_semana';
      case 'Lunes a Viernes':
        return 'lunes_a_viernes';
      default:
        return fUi.toLowerCase();
    }
  }

  // Convierte estado "bonito" → valor para BD (CORREGIDO AQUI)
  String _estadoParaBD(String eUi) {
    switch (eUi) {
      case 'Activa':
        return 'activo'; // <-- CORREGIDO: Se envía 'activo' (masculino)
      case 'Completada':
        return 'completado'; // <-- CORREGIDO: Se envía 'completado'
      case 'Archivada':
        return 'archivado'; // <-- CORREGIDO: Se envía 'archivado'
      default:
        return eUi.toLowerCase();
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

    final recordatorios = await _recordatoriosService.listar();
    for (final r in recordatorios) {
      if (r.programadoEn != null && _mismoMinuto(r.programadoEn, fechaHora)) {
        conflictos.add('Recordatorio: ${r.titulo}');
      } 
    }

    final notas = await _notasService.listar();
    for (final n in notas) {
      if (n.venceEn != null && _mismoMinuto(n.venceEn!, fechaHora)) {
        conflictos.add('Nota: ${n.titulo}');
      }
    }

    final rutinas = await _service.listar();
    for (final r in rutinas) {
      if (widget.existente != null && r.id == widget.existente!.id) continue;
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final esEdicion = widget.existente != null;

    // Validación especial para 3 veces por semana
    if (frecuencia == '3 veces por semana' && _diasSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un día para la frecuencia.'),
        ),
      );
      return;
    }

    // Validación especial para Mensual
    if (frecuencia == 'Mensual' &&
        (_diaMensual == null || _diaMensual! < 1 || _diaMensual! > 31)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un día del mes válido.'),
        ),
      );
      return;
    }

    // Validar que siempre haya fecha y hora de recordatorio
    if (fechaRecordatorio == null || horaRecordatorio == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona fecha y hora para el recordatorio.'),
        ),
      );
      return;
    }

    // Pasar fecha/hora de recordatorio a tu modelo: fechaInicio + hora (String "HH:mm")
    final fechaInicio = DateTime(
      fechaRecordatorio!.year,
      fechaRecordatorio!.month,
      fechaRecordatorio!.day,
    );
    final horaStr =
        '${horaRecordatorio!.hour.toString().padLeft(2, '0')}:${horaRecordatorio!.minute.toString().padLeft(2, '0')}';
    final fechaProgramada = DateTime(
      fechaRecordatorio!.year,
      fechaRecordatorio!.month,
      fechaRecordatorio!.day,
      horaRecordatorio!.hour,
      horaRecordatorio!.minute,
    );

    final colisiones = await _buscarColisiones(fechaProgramada);
    if (colisiones.isNotEmpty) {
      final continuar = await _mostrarAdvertenciaColisiones(colisiones);
      if (continuar != true) return;
    }

    // Regla personalizada:
    String? reglaPersonalizada;
    if (frecuencia == '3 veces por semana' && _diasSeleccionados.isNotEmpty) {
      reglaPersonalizada = _diasSeleccionados.join(',');
    } else if (frecuencia == 'Mensual' && _diaMensual != null) {
      reglaPersonalizada = _diaMensual.toString();
    } else {
      reglaPersonalizada =
          esEdicion ? widget.existente?.reglaPersonalizada : null;
    }

    final nuevaRutina = Rutina(
      id: widget.existente?.id ?? 0,
      usuarioId: widget.existente?.usuarioId ?? '',
      nombre: nombre,
      descripcion: detalle,
      prioridad: widget.existente?.prioridad ?? 'media',
      estado: _estadoParaBD(estado), // Aquí se usará el valor corregido
      fechaInicio: fechaInicio,
      hora: horaStr,
      frecuencia: _frecuenciaParaBD(frecuencia),
      reglaPersonalizada: reglaPersonalizada,
    );

    // 1) Guardar/actualizar en la BD con try/catch
    try {
      if (esEdicion) {
        await _service.actualizar(widget.existente!.id, nuevaRutina);
      } else {
        await _service.crear(nuevaRutina);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la rutina en la base de datos: $e'),
        ),
      );
      return;
    }

    // 2) Programar notificación con su propio try/catch
    try {
      await NotificationService.schedule(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title: esEdicion ? 'Rutina actualizada' : 'Nueva rutina programada',
        body:
            'Rutina "$nombre" programada para ${DateFormat('dd/MM/yyyy HH:mm').format(fechaProgramada)}',
        scheduledUtc: fechaProgramada.toUtc(),
        prealertMinutes: _prealertMinutes,
      );
    } catch (e) {
      // Solo logueamos el error y avisamos; la rutina ya está guardada
      if (kDebugMode) {
        debugPrint('Error al programar la notificación de la rutina: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La rutina se guardó, pero hubo un problema al programar el recordatorio.',
            ),
          ),
        );
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          esEdicion ? 'Rutina actualizada' : 'Rutina creada correctamente',
        ),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final bool esEdicion = widget.existente != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar Rutina' : 'Nueva Rutina'),
        centerTitle: true,
        backgroundColor: const Color(0xFF8C3C37),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Nombre
              TextFormField(
                initialValue: nombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la rutina',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => nombre = value,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese un nombre' : null,
              ),
              const SizedBox(height: 16),

              // Detalle / descripción
              TextFormField(
                initialValue: detalle,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Detalle o descripción',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => detalle = value,
              ),
              const SizedBox(height: 16),

              // Frecuencia
              DropdownButtonFormField<String>(
                initialValue:
                    frecuencias.contains(frecuencia) ? frecuencia : null,
                decoration: const InputDecoration(
                  labelText: 'Frecuencia',
                  border: OutlineInputBorder(),
                ),
                items: frecuencias
                    .map(
                      (f) => DropdownMenuItem<String>(
                        value: f,
                        child: Text(f),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    frecuencia = value ?? frecuencia;
                    if (frecuencia != '3 veces por semana') {
                      _diasSeleccionados = [];
                    }
                    if (frecuencia != 'Mensual') {
                      _diaMensual = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 12),

              // Selección de días cuando frecuencia = "3 veces por semana"
              if (frecuencia == '3 veces por semana') ...[
                const Text(
                  'Selecciona hasta 3 días de la semana:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _diasSemana.map((d) {
                    final key = d['key']!;
                    final label = d['label']!;
                    final selected = _diasSeleccionados.contains(key);
                    return FilterChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (value) {
                        setState(() {
                          if (value) {
                            if (!_diasSeleccionados.contains(key)) {
                              if (_diasSeleccionados.length >= 3) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Solo puedes seleccionar hasta 3 días.',
                                    ),
                                  ),
                                );
                              } else {
                                _diasSeleccionados.add(key);
                              }
                            }
                          } else {
                            _diasSeleccionados.remove(key);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Selección de día del mes cuando frecuencia = "Mensual"
              if (frecuencia == 'Mensual') ...[
                const Text(
                  'Día del mes en que se repetirá la rutina:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Card(
                  elevation: 1,
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: Text(
                      _diaMensual == null
                          ? 'Ningún día seleccionado'
                          : 'Día $_diaMensual de cada mes',
                    ),
                    trailing: TextButton(
                      onPressed: _seleccionarDiaMensual,
                      child: const Text('Elegir día'),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Estado
              DropdownButtonFormField<String>(
                initialValue: estado,
                decoration: const InputDecoration(
                  labelText: 'Estado',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Activa', child: Text('Activa')),
                  DropdownMenuItem(
                      value: 'Completada', child: Text('Completada')),
                  DropdownMenuItem(
                      value: 'Archivada', child: Text('Archivada')),
                ],
                onChanged: (value) =>
                    setState(() => estado = value ?? 'Activa'),
              ),

              const SizedBox(height: 24),

              const Text(
                'Recordatorio de la rutina',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),

              // Fecha (siempre visible)
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text('Fecha: ${formatFecha(fechaRecordatorio)}'),
                trailing: TextButton(
                  onPressed: _seleccionarFecha,
                  child: const Text('Seleccionar'),
                ),
              ),

              // Hora (siempre visible)
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text('Hora: ${formatHora(horaRecordatorio)}'),
                trailing: TextButton(
                  onPressed: _seleccionarHora,
                  child: const Text('Seleccionar'),
                ),
              ),

              const SizedBox(height: 24),

              // Botón guardar
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label:
                    Text(esEdicion ? 'Actualizar Rutina' : 'Guardar Rutina'),
                onPressed: _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8C3C37),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
