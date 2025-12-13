import '../core/supabase_client.dart';

class DashboardService {
  final _sb = Supa.client;

  Future<Map<String, dynamic>> resumenDelDia() async {
    final res = await _sb.from('resumen_del_dia').select().single();
    return res; // ← Cast innecesario eliminado
  }
}
