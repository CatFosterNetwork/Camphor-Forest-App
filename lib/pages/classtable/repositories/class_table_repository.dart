import '../models/class_table.dart';

abstract interface class ClassTableRepository {
  Future<ClassTable> fetchRemote(String xnm, String xqm);
  Future<ClassTable?> loadLocal(String xnm, String xqm);
  Future<void> saveLocal(String xnm, String xqm, ClassTable data);
  Future<void> clearLocal(String xnm, String xqm);
}
