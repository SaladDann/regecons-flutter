import 'package:sqflite/sqflite.dart';
import '../../../models/gestion_obras/obra.dart';

class ObraDao {
  final Database db;

  ObraDao(this.db);

  Future<int> insert(Obra obra) async {
    return await db.insert('obras', obra.toMap());
  }

  Future<int> update(Obra obra) async {
    return await db.update(
      'obras',
      obra.toMap(),
      where: 'id_obra = ?',
      whereArgs: [obra.idObra],
    );
  }

  Future<int> delete(int idObra) async {
    return await db.delete('obras', where: 'id_obra = ?', whereArgs: [idObra]);
  }

  Future<List<Obra>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query('obras');
    return List.generate(maps.length, (i) => Obra.fromMap(maps[i]));
  }

  Future<List<Obra>> getByEstado(String estado) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'obras',
      where: 'estado = ?',
      whereArgs: [estado],
    );
    return List.generate(maps.length, (i) => Obra.fromMap(maps[i]));
  }

  Future<List<Obra>> getActivas() async {
    return await getByEstado('ACTIVA');
  }

  Future<Obra?> getById(int idObra) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'obras',
      where: 'id_obra = ?',
      whereArgs: [idObra],
    );
    if (maps.isNotEmpty) {
      return Obra.fromMap(maps.first);
    }
    return null;
  }

  Future<double> calcularPorcentajeAvance(int idObra) async {
    final actividades = await db.query(
      'actividades',
      where: 'id_obra = ?',
      whereArgs: [idObra],
    );

    if (actividades.isEmpty) return 0.0;

    final total = actividades.length;
    final completadas = actividades
        .where((a) => a['estado'] == 'FINALIZADA')
        .length;

    return (completadas / total) * 100.0;
  }

  Future<int> count() async {
    final result = await db.rawQuery('SELECT COUNT(*) FROM obras');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<List<Obra>> search(String query) async {
    final searchTerm = '%$query%';

    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT * FROM obras
    WHERE nombre LIKE ?
       OR descripcion LIKE ?
       OR cliente LIKE ?
       OR direccion LIKE ?
    ORDER BY fecha_inicio DESC
  ''', [searchTerm, searchTerm, searchTerm, searchTerm]);

    return List.generate(maps.length, (i) => Obra.fromMap(maps[i]));
  }

}
