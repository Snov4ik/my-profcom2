import 'package:my_profkom/models/discount.dart';
import 'package:my_profkom/models/student.dart';

/// A service class that encapsulates all Google Sheets interactions.
///
/// This is a scaffold prepared for real Google Sheets API integration.
/// It currently uses an in-memory stub for quick local development.
///
/// To connect to real Sheets, replace the stub methods with actual HTTP
/// requests or use the `googleapis` package with proper credentials.
class GoogleSheetsService {
  GoogleSheetsService._();

  static final GoogleSheetsService instance = GoogleSheetsService._();

  // Spreadsheet IDs (Google Sheets) used in the app.
  // Replace these IDs with your own if you use different sheets.
  static const String studentsSpreadsheetId =
      '1IOUrhm1jzuGRiMEAlCFEzUi424sLqK5ALmqmudcO8lY';
  static const String discountsSpreadsheetId =
      '1UTmATaW0O9O0K00u6ydIImmAkEhiUdUodoYo0lEHAls';

  // Sheet (tab) names.
  // Update these values to match your sheet tab names.
  static const String studentsSheetName = 'students';
  static const String discountsSheetName = 'discounts';

  /// Simulates common error conditions so UI can be tested.
  ///
  /// In a real implementation these would be replaced by actual network
  /// failures / API response errors.
  bool simulateNoInternet = false;
  bool simulateSheetUnavailable = false;

  /// Stub storage for students.
  ///
  /// In a real sheet this would be populated from the “реєстр студентів”.
  final List<Student> _students = [
    Student(
      fullName: 'Іванов Іван Іванович',
      recordBookNumber: '123456',
      universityPlace: 'КНУ ім. Шевченка',
      studyCourse: '2',
      groupCode: 'КН-21',
      studyForm: 'денна',
      paymentVariant: 'разово',
      phoneNumber: '+380501234567',
      telegram: '@ivanov',
      uniqueCode: 'INV12345',
      membershipPaid: false,
    ),
  ];

  /// Stub storage for partner discounts.
  final List<PartnerDiscount> _partnerDiscounts = const [
    PartnerDiscount(
      partnerName: 'CoffePoint',
      promoCode: 'COFFEE10',
      comment: 'Знижка для студентів',
    ),
    PartnerDiscount(
      partnerName: 'BookHub',
      promoCode: 'BOOK20',
      comment: 'Особистий промокод',
    ),
    PartnerDiscount(
      partnerName: 'GymFit',
      promoCode: 'FIT15',
      comment: 'Постійна знижка',
    ),
  ];

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Adds a new student record to the students sheet.
  Future<void> addStudent(Student student) async {
    _simulateNetworkConditions();

    if (_students.any((s) => s.recordBookNumber.trim() == student.recordBookNumber.trim())) {
      throw UserAlreadyExistsException(
        'Студент з цим номером залікової книжки вже існує',
      );
    }

    if (_students.any((s) => s.uniqueCode.trim().isNotEmpty &&
        s.uniqueCode.trim() == student.uniqueCode.trim() &&
        student.uniqueCode.trim().isNotEmpty)) {
      throw DuplicateDataException(
        'Унікальний код вже використовується іншим студентом',
      );
    }

    _students.add(student);
    await _simulateNetworkLatency();
  }

  /// Finds a student by record book number or unique code.
  ///
  /// If both parameters are provided, checks recordBookNumber first.
  Future<Student?> findStudent({String? recordBookNumber, String? uniqueCode}) async {
    _simulateNetworkConditions();
    await _simulateNetworkLatency();

    Student? findByRecordBook(String value) {
      for (final student in _students) {
        if (student.recordBookNumber.trim() == value.trim()) {
          return student;
        }
      }
      return null;
    }

    Student? findByUniqueCode(String value) {
      for (final student in _students) {
        if (student.uniqueCode.trim() == value.trim()) {
          return student;
        }
      }
      return null;
    }

    if (recordBookNumber != null && recordBookNumber.trim().isNotEmpty) {
      final found = findByRecordBook(recordBookNumber);
      if (found != null) return found;
      throw UserNotFoundException('Студента з таким номером не знайдено');
    }

    if (uniqueCode != null && uniqueCode.trim().isNotEmpty) {
      final found = findByUniqueCode(uniqueCode);
      if (found != null) return found;
      throw UserNotFoundException('Студента з таким унікальним кодом не знайдено');
    }

    throw ArgumentError('Потрібно вказати recordBookNumber або uniqueCode');
  }

  /// Checks whether the student has paid membership by looking at the sheet.
  Future<bool> isMembershipPaid({required String recordBookNumber}) async {
    final student = await findStudent(recordBookNumber: recordBookNumber);
    return student?.membershipPaid ?? false;
  }

  /// Fetches partner discounts from the second sheet.
  Future<List<PartnerDiscount>> fetchPartnerDiscounts() async {
    _simulateNetworkConditions();
    await _simulateNetworkLatency();
    return List<PartnerDiscount>.from(_partnerDiscounts);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _simulateNetworkConditions() {
    if (simulateNoInternet) {
      throw NetworkException('Немає підключення до інтернету');
    }
    if (simulateSheetUnavailable) {
      throw SheetUnavailableException('Google Sheets недоступна');
    }
  }

  Future<void> _simulateNetworkLatency() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
}

/// Опис найпоширеніших помилок, які можуть статися при роботі з таблицями.
class GoogleSheetsException implements Exception {
  final String message;
  GoogleSheetsException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends GoogleSheetsException {
  NetworkException(String message) : super(message);
}

class SheetUnavailableException extends GoogleSheetsException {
  SheetUnavailableException(String message) : super(message);
}

class UserNotFoundException extends GoogleSheetsException {
  UserNotFoundException(String message) : super(message);
}

class UserAlreadyExistsException extends GoogleSheetsException {
  UserAlreadyExistsException(String message) : super(message);
}

class DuplicateDataException extends GoogleSheetsException {
  DuplicateDataException(String message) : super(message);
}

class OperationFailedException extends GoogleSheetsException {
  OperationFailedException(String message) : super(message);
}
