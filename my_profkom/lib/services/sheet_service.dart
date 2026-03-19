import 'package:my_profkom/models/student.dart';

/// Stub service that prepares data for writing into Google Sheets.
///
/// In a real implementation this service would call the Google Sheets API
/// to append/scan rows. This stub keeps an in-memory list for local flow.
class SheetService {
  SheetService._();

  static final SheetService instance = SheetService._();

  final List<Student> _students = [];

  /// Prepare a map for a new row in Google Sheets.
  ///
  /// The returned map keys should match the column headers used in the sheet.
  Map<String, dynamic> prepareStudentRow(Student student) {
    return student.toMap();
  }

  /// Adds the student to the local store and simulates an append to Sheets.
  Future<void> addStudent(Student student) async {
    _students.add(student);
    await appendStudentRow(student);
  }

  /// Returns a student by record book number (or null if not found).
  Future<Student?> findStudentByRecordBook(String recordBookNumber) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    for (final student in _students) {
      if (student.recordBookNumber.trim() == recordBookNumber.trim()) {
        return student;
      }
    }
    return null;
  }

  /// Returns a student by unique code (or null if not found).
  Future<Student?> findStudentByUniqueCode(String uniqueCode) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    for (final student in _students) {
      if (student.uniqueCode.trim() == uniqueCode.trim()) {
        return student;
      }
    }
    return null;
  }

  /// Placeholder for actual append call.
  ///
  /// Replace this with real network logic to insert into Google Sheets.
  Future<void> appendStudentRow(Student student) async {
    final row = prepareStudentRow(student);

    // TODO: Use Google Sheets API / Firebase / REST endpoint to persist.
    // This is a stub so the app structure is prepared.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    // ignore: avoid_print
    print('Prepared row for Google Sheets: $row');
  }
}
