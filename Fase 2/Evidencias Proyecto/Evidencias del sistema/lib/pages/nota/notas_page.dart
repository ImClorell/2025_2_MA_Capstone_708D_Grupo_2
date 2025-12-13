import 'package:flutter/material.dart';
import 'package:agendai/models/nota.dart';
import 'package:agendai/services/notas_service.dart';
import 'form_nota_page.dart';
import 'detalle_nota_page.dart';

class NotasPage extends StatefulWidget {
  const NotasPage({super.key});

  @override
  State<NotasPage> createState() => _NotasPageState();
}

class _NotasPageState extends State<NotasPage> {
  final _service = NotasService();

  Future<void> _refresh() async {
    setState(() {});
  }

  Future<void> _abrirDetalle(Nota nota) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DetalleNotaPage(nota: nota)),
    );
    if (result == true) _refresh();
  }

  Future<void> _crearNota() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FormNotaPage()),
    );
    if (result == true) _refresh();
  }

  // Color dinámico para etiqueta según FormNotaPage
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
      } else {
        return isDark ? Colors.grey[800]! : Colors.grey[300]!;
      }
    } catch (_) {
      return isDark ? Colors.grey[800]! : Colors.grey[300]!;
    }
  }

  // Formato fecha (usa venceEn de la nota)
  String _formatFecha(DateTime? fecha) {
    if (fecha == null) return 'Sin recordatorio';

    final d = fecha;
    final dia = d.day.toString().padLeft(2, "0");
    final mes = d.month.toString().padLeft(2, "0");
    final anio = d.year.toString();
    final h = d.hour.toString().padLeft(2, "0");
    final min = d.minute.toString().padLeft(2, "0");

    return "$dia/$mes/$anio - $h:$min";
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final colorCard = isDark ? Colors.grey[900]! : Colors.grey[100]!;
    final colorTitulo = isDark ? Colors.white : Colors.black;
    final colorSubtitulo = isDark ? Colors.white70 : Colors.grey[800];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8C3C37),
        foregroundColor: Colors.white,
        onPressed: _crearNota,
        label: const Text('Nueva Nota'),
        icon: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<Nota>>(
        future: _service.listar(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notas = snapshot.data!;
          if (notas.isEmpty) {
            return const Center(child: Text('No hay notas registradas.'));
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: notas.length,
              itemBuilder: (context, index) {
                final nota = notas[index];

                final etiqueta = nota.etiqueta ?? '';
                final descripcion = nota.descripcion ?? '';

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    color: colorCard,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      leading: const Icon(
                        Icons.note_alt_outlined,
                        color: Colors.redAccent,
                        size: 26,
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título
                          Text(
                            nota.titulo,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorTitulo,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Etiqueta (Chip con color dinámico, null-safe)
                          if (etiqueta.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _colorEtiqueta(etiqueta, isDark),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                etiqueta,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white
                                      : Colors.grey[900],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 6),

                          // Descripción (null-safe)
                          if (descripcion.trim().isNotEmpty)
                            Text(
                              descripcion,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: colorSubtitulo),
                            ),

                          const SizedBox(height: 8),

                          // Prioridad y estado
                          Row(
                            children: [
                              const Icon(
                                Icons.flag,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                nota.prioridad,
                                style: TextStyle(color: colorSubtitulo),
                              ),
                              const SizedBox(width: 12),
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                nota.estado,
                                style: TextStyle(color: colorSubtitulo),
                              ),
                            ],
                          ),

                          const SizedBox(height: 4),

                          // Fecha de vencimiento
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatFecha(nota.venceEn),
                                style: TextStyle(color: colorSubtitulo),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => _abrirDetalle(nota),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
