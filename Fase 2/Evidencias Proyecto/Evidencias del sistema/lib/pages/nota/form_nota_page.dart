// lib/pages/nota/form_nota_page.dart
import 'package:flutter/material.dart';
import 'package:agendai/models/nota.dart';
import 'package:agendai/models/etiqueta.dart';
import 'package:agendai/services/notas_service.dart';
import 'package:agendai/services/etiquetas_service.dart';
import 'package:agendai/services/recordatorios_service.dart';
import 'package:agendai/services/rutinas_service.dart';

/// Paleta de colores suaves para etiquetas
const List<Color> kEtiquetaColors = [
  Color(0xFFEF9A9A), // Rojo suave
  Color(0xFFFFF59D), // Amarillo suave
  Color(0xFFA5D6A7), // Verde suave
  Color(0xFF90CAF9), // Azul suave
  Color(0xFFCE93D8), // Morado suave
  Color(0xFFFFCC80), // Naranjo suave
];

class FormNotaPage extends StatefulWidget {
  final Nota? nota;

  /// Lista compartida de etiquetas (se llena desde BD)
  static List<Map<String, dynamic>> etiquetasDisponibles = [];

  const FormNotaPage({super.key, this.nota});

  @override
  State<FormNotaPage> createState() => _FormNotaPageState();
}

class _FormNotaPageState extends State<FormNotaPage> {
  final _formKey = GlobalKey<FormState>();
  final _service = NotasService();
  final _etiquetasService = EtiquetasService();
  final _recordatoriosService = RecordatoriosService();
  final _rutinasService = RutinasService();

  late TextEditingController _tituloCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _detalleCtrl;

  String _etiqueta = '';
  String _prioridad = 'media';
  String _estado = 'activo';

  bool _agregarRecordatorio = false;
  DateTime? _fechaSeleccionada;
  TimeOfDay? _horaSeleccionada;

  bool _cargandoEtiquetas = true;

  @override
  void initState() {
    super.initState();

    final nota = widget.nota;

    _tituloCtrl = TextEditingController(text: nota?.titulo ?? '');
    _descripcionCtrl = TextEditingController(text: nota?.descripcion ?? '');
    _detalleCtrl = TextEditingController(text: nota?.detalle ?? '');

    _etiqueta = nota?.etiqueta ?? '';
    _prioridad = nota?.prioridad ?? 'media';
    _estado = nota?.estado ?? 'activo';

    if (nota?.venceEn != null) {
      _agregarRecordatorio = true;
      _fechaSeleccionada = nota!.venceEn;
      _horaSeleccionada =
          TimeOfDay(hour: nota.venceEn!.hour, minute: nota.venceEn!.minute);
    }

    _cargarEtiquetas();
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descripcionCtrl.dispose();
    _detalleCtrl.dispose();
    super.dispose();
  }

  String _normalizarNombre(String nombre) => nombre.trim().toLowerCase();

  /// Devuelve la lista de etiquetas sin duplicados por nombre
  List<Map<String, dynamic>> _etiquetasUnicas(List<Map<String, dynamic>> lista) {
    final Set<String> vistos = {};
    final List<Map<String, dynamic>> resultado = [];

    for (final e in lista) {
      final nombre = (e['nombre'] as String?) ?? '';
      final key = _normalizarNombre(nombre);
      if (key.isEmpty) continue;
      if (!vistos.contains(key)) {
        vistos.add(key);
        resultado.add(e);
      }
    }
    return resultado;
  }

  /// Devuelve el valor seguro para el Dropdown de etiqueta
  String? _dropdownValueForEtiqueta(List<Map<String, dynamic>> etiquetas) {
    if (_etiqueta.trim().isEmpty) return null;

    final matches =
        etiquetas.where((e) => (e['nombre'] as String?) == _etiqueta);

    if (matches.length == 1) {
      return _etiqueta;
    }

    // 0 o más de 1 coincidencia: no preseleccionamos nada
    return null;
  }

  Future<void> _cargarEtiquetas() async {
    try {
      final lista = await _etiquetasService.listar();

      List<Map<String, dynamic>> base;
      if (lista.isEmpty) {
        // Defaults si la tabla esta vacía (usando la paleta suave)
        base = [
          {'nombre': 'Salud', 'color': kEtiquetaColors[2]}, // Verde suave
          {'nombre': 'Trabajo', 'color': kEtiquetaColors[3]}, // Azul suave
          {'nombre': 'Estudio', 'color': kEtiquetaColors[4]}, // Morado suave
          {'nombre': 'Personal', 'color': kEtiquetaColors[0]}, // Rojo suave
        ];
      } else {
        base = lista
            .map<Map<String, dynamic>>(
              (Etiqueta e) => {
                'nombre': e.nombre,
                'color': e.color,
              },
            )
            .toList();
      }

      // Quitamos duplicados por nombre
      base = _etiquetasUnicas(base);

      // Si la nota tiene etiqueta y no está en la lista, la añadimos
      if (_etiqueta.trim().isNotEmpty &&
          !base.any((e) =>
              _normalizarNombre(e['nombre'] as String) ==
              _normalizarNombre(_etiqueta))) {
        base.add({
          'nombre': _etiqueta.trim(),
          'color': kEtiquetaColors[3], // Azul suave por defecto
        });
      }

      if (!mounted) return;
      setState(() {
        FormNotaPage.etiquetasDisponibles = base;
        _cargandoEtiquetas = false;
      });
    } catch (_) {
      if (!mounted) return;
      // Si falla BD, al menos dejamos algunos defaults con la misma paleta
      setState(() {
        if (FormNotaPage.etiquetasDisponibles.isEmpty) {
          FormNotaPage.etiquetasDisponibles = [
            {'nombre': 'Salud', 'color': kEtiquetaColors[2]},
            {'nombre': 'Trabajo', 'color': kEtiquetaColors[3]},
            {'nombre': 'Estudio', 'color': kEtiquetaColors[4]},
            {'nombre': 'Personal', 'color': kEtiquetaColors[0]},
          ];
        }
        FormNotaPage.etiquetasDisponibles =
            _etiquetasUnicas(FormNotaPage.etiquetasDisponibles);
        _cargandoEtiquetas = false;
      });
    }
  }

  Future<void> _seleccionarFecha() async {
    final fechaInicial = _fechaSeleccionada ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: fechaInicial,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _fechaSeleccionada = picked;
    });
  }

  Future<void> _seleccionarHora() async {
    final horaInicial =
        _horaSeleccionada ?? TimeOfDay.fromDateTime(DateTime.now());
    final picked = await showTimePicker(
      context: context,
      initialTime: horaInicial,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _horaSeleccionada = picked;
    });
  }

  DateTime? _combinarFechaHora() {
    if (!_agregarRecordatorio ||
        _fechaSeleccionada == null ||
        _horaSeleccionada == null) {
      return null;
    }
    return DateTime(
      _fechaSeleccionada!.year,
      _fechaSeleccionada!.month,
      _fechaSeleccionada!.day,
      _horaSeleccionada!.hour,
      _horaSeleccionada!.minute,
    );
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

    // Otras notas con recordatorio
    final notas = await _service.listar();
    for (final n in notas) {
      if (widget.nota != null && n.id == widget.nota!.id) continue;
      if (n.venceEn != null && _mismoMinuto(n.venceEn!, fechaHora)) {
        conflictos.add('Nota: ${n.titulo}');
      }
    }

    // Recordatorios
    final recordatorios = await _recordatoriosService.listar();
    for (final r in recordatorios) {
      if (_mismoMinuto(r.programadoEn, fechaHora)) {
        conflictos.add('Recordatorio: ${r.titulo}');
      }
    }

    // Rutinas
    final rutinas = await _rutinasService.listar();
    for (final r in rutinas) {
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

  String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin fecha seleccionada';
    return '${fecha.day.toString().padLeft(2, '0')}/'
        '${fecha.month.toString().padLeft(2, '0')}/'
        '${fecha.year}';
  }

  String _formatearHora(TimeOfDay? hora) {
    if (hora == null) return 'Sin hora seleccionada';
    final h = hora.hour.toString().padLeft(2, '0');
    final m = hora.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _guardarNota() async {
    if (!_formKey.currentState!.validate()) return;

    final venceEn = _combinarFechaHora();

    if (venceEn != null) {
      final colisiones = await _buscarColisiones(venceEn);
      if (colisiones.isNotEmpty) {
        final continuar = await _mostrarAdvertenciaColisiones(colisiones);
        if (continuar != true) return;
      }
    }

    final nuevaNota = Nota(
      id: widget.nota?.id,
      // usuarioId se asigna en el servicio con el usuario logeado
      titulo: _tituloCtrl.text.trim(),
      descripcion: _descripcionCtrl.text.trim().isEmpty
          ? null
          : _descripcionCtrl.text.trim(),
      detalle: _detalleCtrl.text.trim().isEmpty
          ? null
          : _detalleCtrl.text.trim(),
      etiqueta: _etiqueta.isEmpty ? null : _etiqueta,
      prioridad: _prioridad,
      estado: _estado,
      venceEn: venceEn,
      fijada: widget.nota?.fijada ?? false,
      creadoEn: widget.nota?.creadoEn,
      actualizadoEn: DateTime.now(),
    );

    try {
      if (widget.nota == null) {
        await _service.crear(nuevaNota);
      } else {
        await _service.actualizar(nuevaNota);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.nota == null
                ? 'Nota guardada exitosamente'
                : 'Nota actualizada',
          ),
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar la nota: $e'),
        ),
      );
    }
  }

  Future<void> _mostrarDialogoNuevaEtiqueta() async {
    String nuevaEtiqueta = '';
    Color colorSeleccionado = kEtiquetaColors[3]; // Azul suave por defecto

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Nueva etiqueta'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration:
                    const InputDecoration(labelText: 'Nombre de etiqueta'),
                onChanged: (value) => nuevaEtiqueta = value,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Color>(
                decoration: const InputDecoration(labelText: 'Color'),
                initialValue: colorSeleccionado,
                items: kEtiquetaColors
                    .map(
                      (c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black.withValues(alpha: 0.12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '#${c.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      colorSeleccionado = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(dialogContext),
            ),
            ElevatedButton(
              child: const Text('Guardar'),
              onPressed: () async {
                final nombre = nuevaEtiqueta.trim();
                if (nombre.isEmpty) {
                  Navigator.pop(dialogContext);
                  return;
                }

                final key = _normalizarNombre(nombre);

                try {
                  final creada = await _etiquetasService.crear(
                    nombre: nombre,
                    color: colorSeleccionado,
                  );

                  if (!mounted) return;
                  setState(() {
                    // quitamos cualquier etiqueta con ese nombre
                    FormNotaPage.etiquetasDisponibles.removeWhere(
                      (e) =>
                          _normalizarNombre(e['nombre'] as String) == key,
                    );

                    FormNotaPage.etiquetasDisponibles.add({
                      'nombre': creada.nombre,
                      'color': creada.color,
                    });

                    FormNotaPage.etiquetasDisponibles =
                        _etiquetasUnicas(FormNotaPage.etiquetasDisponibles);

                    _etiqueta = creada.nombre;
                  });
                } catch (e) {
                  debugPrint('Error al crear etiqueta en Supabase: $e');

                  if (!mounted) return;
                  // si falla BD, al menos la guardamos local
                  setState(() {
                    FormNotaPage.etiquetasDisponibles.removeWhere(
                      (ex) =>
                          _normalizarNombre(ex['nombre'] as String) == key,
                    );

                    FormNotaPage.etiquetasDisponibles.add({
                      'nombre': nombre,
                      'color': colorSeleccionado,
                    });

                    FormNotaPage.etiquetasDisponibles =
                        _etiquetasUnicas(FormNotaPage.etiquetasDisponibles);

                    _etiqueta = nombre;
                  });
                }

                if (!mounted) return;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.nota != null;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorCard = isDark ? Colors.grey[900]! : Colors.grey[100]!;

    // Lista local sin duplicados
    final etiquetas = _etiquetasUnicas(FormNotaPage.etiquetasDisponibles);

    // Calcula un value seguro para el dropdown de etiqueta
    final String? valueDropdown = _dropdownValueForEtiqueta(etiquetas);

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar nota' : 'Nueva nota'),
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
                  // Titulo
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El título es obligatorio';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Descripcion
                  TextFormField(
                    controller: _descripcionCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detalle
                  TextFormField(
                    controller: _detalleCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Detalle',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Etiqueta
                  if (_cargandoEtiquetas)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: valueDropdown,
                      decoration: const InputDecoration(
                        labelText: 'Etiqueta',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14, // más alto para que no se corte el chip
                        ),
                      ),
                      items: [
                        ...etiquetas.map((e) {
                          return DropdownMenuItem<String>(
                            value: e['nombre'] as String,
                            // Chip para la lista desplegable
                            child: _EtiquetaPreview(
                              nombre: e['nombre'] as String,
                              color: e['color'] as Color,
                            ),
                          );
                        }),
                        const DropdownMenuItem<String>(
                          value: 'nueva',
                          child: Row(
                            children: [
                              Icon(Icons.add),
                              SizedBox(width: 6),
                              Text('Agregar nueva etiqueta'),
                            ],
                          ),
                        ),
                      ],
                      // Cómo se ve el valor seleccionado cuando el dropdown está cerrado
                      selectedItemBuilder: (context) {
                        final nombres = [
                          ...etiquetas.map((e) => e['nombre'] as String),
                          'nueva',
                        ];

                        return nombres.map<Widget>((nombre) {
                          if (nombre == 'nueva') {
                            return const Text('Agregar nueva etiqueta');
                          }

                          final color = etiquetas
                              .firstWhere(
                                  (e) => e['nombre'] == nombre)['color']
                              as Color;

                          // Vista más simple: punto + texto, sin chip alto
                          return Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(nombre),
                            ],
                          );
                        }).toList();
                      },
                      onChanged: (value) async {
                        if (value == 'nueva') {
                          await _mostrarDialogoNuevaEtiqueta();
                        } else if (value != null) {
                          setState(() => _etiqueta = value);
                        }
                      },
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
                      DropdownMenuItem(value: 'baja', child: Text('Baja')),
                      DropdownMenuItem(value: 'media', child: Text('Media')),
                      DropdownMenuItem(value: 'alta', child: Text('Alta')),
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
                          value: 'activo', child: Text('Activo')),
                      DropdownMenuItem(
                          value: 'completada', child: Text('Completada')),
                      DropdownMenuItem(
                          value: 'archivada', child: Text('Archivada')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _estado = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Switch recordatorio
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Agregar recordatorio'),
                    value: _agregarRecordatorio,
                    onChanged: (value) {
                      setState(() => _agregarRecordatorio = value);
                    },
                  ),
                  const SizedBox(height: 8),

                  if (_agregarRecordatorio) ...[
                    Row(
                      children: [
                        const Icon(Icons.date_range,
                            color: Colors.teal, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Fecha: ${_formatearFecha(_fechaSeleccionada)}',
                          ),
                        ),
                        TextButton(
                          onPressed: _seleccionarFecha,
                          child: const Text('Seleccionar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            color: Colors.orangeAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hora: ${_formatearHora(_horaSeleccionada)}',
                          ),
                        ),
                        TextButton(
                          onPressed: _seleccionarHora,
                          child: const Text('Seleccionar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Boton guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8C3C37),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.save),
                      label: Text(
                          esEdicion ? 'Actualizar nota' : 'Guardar nota'),
                      onPressed: _guardarNota,
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

/// Widget para mostrar una etiqueta como “chip” bonito
class _EtiquetaPreview extends StatelessWidget {
  final String nombre;
  final Color color;

  const _EtiquetaPreview({
    required this.nombre,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bg = Color.alphaBlend(
      color.withValues(alpha: 0.15),
      isDark ? Colors.grey[850]! : Colors.white,
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 4, // más bajo para que no se corte en el campo
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            nombre,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
