import 'package:flutter/material.dart';
import 'package:agendai/core/supabase_client.dart';

import 'package:agendai/models/nota.dart';
import 'package:agendai/models/recordatorio.dart';
import 'package:agendai/models/rutina.dart';

import 'package:agendai/services/notas_service.dart';
import 'package:agendai/services/recordatorios_service.dart';
import 'package:agendai/services/rutinas_service.dart';

import 'package:agendai/pages/nota/detalle_nota_page.dart';
import 'package:agendai/pages/nota/form_nota_page.dart';
import 'package:agendai/pages/recordatorio/detalle_recordatorio_page.dart';
import 'package:agendai/pages/rutina/detalle_rutina_page.dart';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> {
  bool _cargando = true;
  String? _error;

  final _notasService = NotasService();
  final _recordatoriosService = RecordatoriosService();
  final _rutinasService = RutinasService();

  List<Nota> _notas = [];
  List<Recordatorio> _recordatorios = [];
  List<Rutina> _rutinas = [];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  /// Carga notas, recordatorios y rutinas en paralelo
  Future<void> _cargarDatos() async {
    final stopwatch = Stopwatch()..start();
    debugPrint('[InicioPage] Cargando datos...');

    try {
      final resultados = await Future.wait([
        _notasService.listar(),
        _recordatoriosService.listar(),      // <- ahora trae TODOS los recordatorios del usuario
        _rutinasService.listar(),
      ]);

      stopwatch.stop();
      debugPrint(
        '[InicioPage] Datos cargados en ${stopwatch.elapsedMilliseconds} ms',
      );

      setState(() {
        _notas = resultados[0] as List<Nota>;
        _recordatorios = resultados[1] as List<Recordatorio>;
        _rutinas = resultados[2] as List<Rutina>;
        _cargando = false;
        _error = null;
      });
    } catch (e) {
      stopwatch.stop();
      debugPrint(
        '[InicioPage] Error al cargar (tardó ${stopwatch.elapsedMilliseconds} ms): $e',
      );

      setState(() {
        _error = 'Error al cargar datos: $e';
        _cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorTexto = isDark ? Colors.white : Colors.black87;
    final colorSub = isDark ? Colors.white70 : Colors.grey[700]!;
    final colorPanel = isDark ? Colors.grey[900]! : Colors.grey[100]!;

    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Resumen Diario'),
          centerTitle: true,
          backgroundColor: const Color(0xFF8C3C37),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final hoy = DateTime.now();

    // Recordatorios de HOY (programadoEn = hoy) y estado activo/pendiente
    final recordatoriosHoy = _recordatorios.where((r) {
      final d = r.programadoEn.toLocal();
      final mismoDia =
          d.year == hoy.year && d.month == hoy.month && d.day == hoy.day;

      final estado = r.estado.toLowerCase();
      final esActivoOPendiente =
          estado == 'activo' || estado == 'pendiente';

      return mismoDia && esActivoOPendiente;
    }).toList();

    // Rutinas del día según frecuencia
    final rutinasHoy = _rutinas.where((r) {
      final freq = (r.frecuencia ?? '').toLowerCase();

      if (freq.contains('diaria')) return true;

      final dias = {
        1: 'lunes',
        2: 'martes',
        3: 'miércoles',
        4: 'jueves',
        5: 'viernes',
        6: 'sábado',
        7: 'domingo',
      };

      final nombreDia = dias[hoy.weekday] ?? '';

      if (freq.contains('lunes a viernes')) {
        return hoy.weekday >= 1 && hoy.weekday <= 5;
      }

      if (freq.contains(nombreDia)) return true;

      if (freq.contains('3 veces por semana')) return true;

      return false;
    }).toList();

    final notasRecientes = _notas.take(3).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen Diario'),
        centerTitle: true,
        backgroundColor: const Color(0xFF8C3C37),
      ),
      body: RefreshIndicator(
        onRefresh: _cargarDatos,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Saludo
            Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0xFF8C3C37),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "¡${_prefijoSaludo()} ${_saludoSegunHora()}, ${_nombreUsuario()}!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorTexto,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // Panel de resumen
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _tarjetaResumen(
                  Icons.note_alt,
                  "Notas",
                  _notas.length,
                  Colors.redAccent,
                ),
                _tarjetaResumen(
                  Icons.alarm,
                  "Recordatorios",
                  recordatoriosHoy.length,
                  Colors.orangeAccent,
                ),
                _tarjetaResumen(
                  Icons.repeat,
                  "Rutinas",
                  rutinasHoy.length,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Próximos Recordatorios
            _bloqueSeccion(
              titulo: "Próximos Recordatorios",
              icono: Icons.alarm,
              color: Colors.orangeAccent,
              contenido: recordatoriosHoy.isEmpty
                  ? _textoVacio("No tienes recordatorios hoy.", colorSub)
                  : Column(
                      children: recordatoriosHoy
                          .map(
                            (r) => _tarjetaMini(
                              context,
                              titulo: r.titulo,
                              subtitulo: _subtituloRecordatorio(r),
                              icono: Icons.access_time,
                              colorIcono: Colors.orangeAccent,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetalleRecordatorioPage(
                                            recordatorio: r),
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 22),

            // Notas recientes
            _bloqueSeccion(
              titulo: "Notas Recientes",
              icono: Icons.note_alt_outlined,
              color: Colors.redAccent,
              contenido: notasRecientes.isEmpty
                  ? _textoVacio("No hay notas registradas.", colorSub)
                  : Column(
                      children: notasRecientes
                          .map(
                            (n) => _tarjetaNota(
                              context,
                              nota: n,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetalleNotaPage(nota: n),
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 22),

            // Rutinas del día
            _bloqueSeccion(
              titulo: "Rutinas del Día",
              icono: Icons.repeat,
              color: Colors.green,
              contenido: rutinasHoy.isEmpty
                  ? _textoVacio("No tienes rutinas hoy.", colorSub)
                  : Column(
                      children: rutinasHoy
                          .map(
                            (r) => _tarjetaMini(
                              context,
                              titulo: r.nombre,
                              subtitulo: r.descripcion ?? '',
                              icono: Icons.repeat,
                              colorIcono: Colors.green,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DetalleRutinaPage(rutina: r),
                                  ),
                                );
                              },
                            ),
                          )
                          .toList(),
                    ),
            ),
            const SizedBox(height: 30),

            // Frase motivacional
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorPanel,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  const Icon(Icons.emoji_objects,
                      color: Colors.amber, size: 30),
                  const SizedBox(height: 10),
                  Text(
                    "“El progreso no se mide en velocidad, sino en constancia.”",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: colorSub,
                      fontSize: 15,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------- Helpers UI ----------

  Widget _tarjetaResumen(
      IconData icono, String titulo, int cantidad, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icono, color: color, size: 28),
            const SizedBox(height: 4),
            Text(
              "$cantidad",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: color,
              ),
            ),
            Text(
              titulo,
              style: TextStyle(
                color: color.withValues(alpha: 0.8),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bloqueSeccion({
    required String titulo,
    required IconData icono,
    required Color color,
    required Widget contenido,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: color),
            const SizedBox(width: 6),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        contenido,
      ],
    );
  }

  Widget _tarjetaMini(
    BuildContext context, {
    required String titulo,
    required String subtitulo,
    required IconData icono,
    required Color colorIcono,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorIcono.withValues(alpha: 0.15),
          child: Icon(icono, color: colorIcono),
        ),
        title:
            Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(
          subtitulo,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Color _colorEtiqueta(String etiqueta, bool isDark) {
    if (etiqueta.isEmpty) {
      return isDark ? Colors.grey[800]! : Colors.grey[300]!;
    }

    try {
      final etiquetaEncontrada = FormNotaPage.etiquetasDisponibles.firstWhere(
        (e) =>
            (e['nombre'] as String).toLowerCase().trim() ==
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

  Widget _tarjetaNota(
    BuildContext context, {
    required Nota nota,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorFondo = isDark ? Colors.grey[900]! : Colors.white;

    final subtitulo = (nota.descripcion?.trim().isNotEmpty == true)
        ? nota.descripcion!.trim()
        : (nota.detalle?.trim().isNotEmpty == true)
            ? nota.detalle!.trim()
            : 'Sin descripción';

    final etiqueta = (nota.etiqueta ?? '').trim();
    final etiquetaColor = _colorEtiqueta(etiqueta, isDark);

    String fechaVence = '';
    if (nota.venceEn != null) {
      final d = nota.venceEn!.toLocal();
      final dia = d.day.toString().padLeft(2, '0');
      final mes = d.month.toString().padLeft(2, '0');
      final anio = d.year.toString();
      final h = d.hour.toString().padLeft(2, '0');
      final m = d.minute.toString().padLeft(2, '0');
      fechaVence = '$dia/$mes/$anio • $h:$m';
    }

    Color colorPrioridad() {
      final p = nota.prioridad.toLowerCase();
      if (p.contains('alta')) return Colors.redAccent;
      if (p.contains('media')) return Colors.orangeAccent;
      if (p.contains('baja')) return Colors.green;
      return Colors.grey;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 10),
      color: colorFondo,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nota.titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (etiqueta.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: etiquetaColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    etiqueta,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[900],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                subtitulo,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (fechaVence.isNotEmpty) ...[
                    const Icon(
                      Icons.access_time,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      fechaVence,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const Spacer(),
                  ] else
                    const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorPrioridad().withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      nota.prioridad,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorPrioridad(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _textoVacio(String texto, Color colorSub) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Text(
        texto,
        style: TextStyle(
          color: colorSub,
          fontSize: 13,
        ),
      ),
    );
  }

  // ---------- Helpers de datos/saludo ----------

  String _subtituloRecordatorio(Recordatorio r) {
    final d = r.programadoEn.toLocal();
    final dia = d.day.toString().padLeft(2, '0');
    final mes = d.month.toString().padLeft(2, '0');
    final anio = d.year.toString();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$dia/$mes/$anio  •  $h:$m';
  }

  String _saludoSegunHora() {
    final hora = DateTime.now().hour;
    if (hora < 12) return "días";
    if (hora < 19) return "tardes";
    return "noches";
  }

  String _prefijoSaludo() {
    final h = DateTime.now().hour;
    return h < 12 ? 'Buenos' : 'Buenas';
  }

  String _nombreUsuario() {
    final u = Supa.client.auth.currentUser;
    final metaName = (u?.userMetadata?['full_name'] as String?)?.trim();
    if (metaName != null && metaName.isNotEmpty) {
      return metaName;
    }

    final email = u?.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }

    return 'Usuario';
  }
}
