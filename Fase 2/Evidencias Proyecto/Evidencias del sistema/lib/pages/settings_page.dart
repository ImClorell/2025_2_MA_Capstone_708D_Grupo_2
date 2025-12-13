import 'package:flutter/material.dart';
import 'package:agendai/services/ajustes_service.dart';
import 'package:agendai/services/auth_service.dart';

class SettingsPage extends StatefulWidget {
  final bool? isDarkMode;
  final VoidCallback? onToggleTheme;

  const SettingsPage({
    super.key,
    this.isDarkMode,
    this.onToggleTheme,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _service = AjustesService();
  final _auth = AuthService();

  String? _zonaHoraria;
  String? _idioma;
  bool _notificaciones = true;
  String? _posponerPor = "00:10:00";
  int? _horasLaborales = 8;

  bool _cargando = true;

  final List<String> _zonas = [
    "UTC-03:00",
    "UTC",
    "GMT",
    "CET",
    "EST",
    "America/Argentina/Buenos_Aires",
  ];

  /// Leemos SIEMPRE del tema actual
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final data = await _service.obtener();

    if (data != null) {
      setState(() {
        _zonaHoraria = data["zona_horaria"];
        _idioma = data["idioma"];
        _notificaciones = data["notificaciones"] ?? true;
        _posponerPor = data["posponer_por"];
        _horasLaborales = data["horas_laborales"];
      });
    } else {
      // Default solicitado: UTC-03:00
      _zonaHoraria = "UTC-03:00";
    }

    setState(() => _cargando = false);
  }

  Future<void> _guardar() async {
    await _service.upsert(
      zonaHoraria: _zonaHoraria ?? "UTC-03:00",
      idioma: _idioma,
      notificaciones: _notificaciones,
      posponerPor: _posponerPor,
      horasLaborales: _horasLaborales,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Ajustes guardados")),
    );
  }

  Future<void> _cerrarSesion() async {
    try {
      await _auth.signOut();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sesión cerrada")),
      );
      // AuthGate se encarga de mandarte al login
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al cerrar sesión: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Validar valor existente en la lista de zonas horarias
    final zonaInicial =
        _zonas.contains(_zonaHoraria) ? _zonaHoraria : _zonas.first;

    // 🚦 Textos dinámicos para el switch de tema
    final String tituloTema =
        _isDark ? "Activar modo claro" : "Activar modo oscuro";
    final String subtituloTema = _isDark
        ? "Cambia la app a tema claro"
        : "Cambia la app a tema oscuro";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajustes"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // TEMA OSCURO / CLARO (dinámico)
          if (widget.onToggleTheme != null) ...[
            SwitchListTile(
              value: _isDark,
              onChanged: (value) {
                widget.onToggleTheme?.call();
              },
              title: Text(tituloTema),
              subtitle: Text(subtituloTema),
            ),
            const SizedBox(height: 16),
          ],

          // ZONA HORARIA
          DropdownButtonFormField<String>(
            initialValue: zonaInicial,
            decoration: const InputDecoration(labelText: "Zona horaria"),
            items: _zonas
                .map((z) => DropdownMenuItem(value: z, child: Text(z)))
                .toList(),
            onChanged: (v) => setState(() => _zonaHoraria = v),
          ),

          const SizedBox(height: 16),

          // IDIOMA
          DropdownButtonFormField<String>(
            initialValue: _idioma ?? "es",
            decoration: const InputDecoration(labelText: "Idioma"),
            items: const [
              DropdownMenuItem(value: "es", child: Text("Español")),
              DropdownMenuItem(value: "en", child: Text("Inglés")),
            ],
            onChanged: (v) => setState(() => _idioma = v),
          ),

          const SizedBox(height: 16),

          // NOTIFICACIONES
          SwitchListTile(
            value: _notificaciones,
            onChanged: (v) => setState(() => _notificaciones = v),
            title: const Text("Notificaciones activas"),
          ),

          const SizedBox(height: 16),

          // POSPONER POR
          DropdownButtonFormField<String>(
            initialValue: _posponerPor,
            decoration: const InputDecoration(labelText: "Posponer por"),
            items: const [
              DropdownMenuItem(value: "00:05:00", child: Text("5 minutos")),
              DropdownMenuItem(value: "00:10:00", child: Text("10 minutos")),
              DropdownMenuItem(value: "00:15:00", child: Text("15 minutos")),
              DropdownMenuItem(value: "00:30:00", child: Text("30 minutos")),
            ],
            onChanged: (v) => setState(() => _posponerPor = v),
          ),

          const SizedBox(height: 16),

          // HORAS LABORALES
          DropdownButtonFormField<int>(
            initialValue: _horasLaborales ?? 8,
            decoration:
                const InputDecoration(labelText: "Horas laborales diarias"),
            items: const [
              DropdownMenuItem(value: 6, child: Text("6 horas")),
              DropdownMenuItem(value: 7, child: Text("7 horas")),
              DropdownMenuItem(value: 8, child: Text("8 horas")),
              DropdownMenuItem(value: 9, child: Text("9 horas")),
            ],
            onChanged: (v) => setState(() => _horasLaborales = v),
          ),

          const SizedBox(height: 32),

          // BOTÓN GUARDAR
          ElevatedButton(
            onPressed: _guardar,
            child: const Text("Guardar"),
          ),

          const SizedBox(height: 16),

          // 🔴 BOTÓN CERRAR SESIÓN
          ElevatedButton.icon(
            onPressed: _cerrarSesion,
            icon: const Icon(Icons.logout),
            label: const Text("Cerrar sesión"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
