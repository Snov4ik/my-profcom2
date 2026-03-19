import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:my_profkom/models/discount.dart';
import 'package:my_profkom/models/student.dart';

/// Service that works with a real Google Sheet via a deployed Apps Script web app.
class GoogleSheetsService {
  GoogleSheetsService._();

  static final GoogleSheetsService instance = GoogleSheetsService._();

  static const String spreadsheetId =
      '14f89dShxut0tEiBOOwiRLiBtKIspmTr1WryYQ5fSryA';

  static const String _discountsSpreadsheetId =
      '1UTmATaW0O9O0K00u6ydIImmAkEhiUdUodoYo0lEHAls';

  /// URL of the deployed Google Apps Script web app.
  static const String _scriptUrl =
      'https://script.google.com/macros/s/AKfycbyzXgyXGecgn9fFp-l5lSc4POshnBi2WuwO3p3_IeFvPk0RZ_SZ_kqjggi_gsjRMyISrA/exec';

  /// Maps Google Sheet Ukrainian column labels to Student model field names.
  static const Map<String, String> _columnMapping = {
    'ID': 'id',
    'Ваш повний Піб': 'fullName',
    'Номер залікової книжки': 'recordBookNumber',
    'Де ви навчаєтесь?': 'universityPlace',
    'Курс навчання': 'studyCourse',
    'Код і номер групи(наприклад РМ-404)': 'groupCode',
    'Ваша форма навчання': 'studyForm',
    'Варіант сплати профвнесків': 'paymentVariant',
    'Ваш номер телефону': 'phoneNumber',
    'Ваш телеграм': 'telegram',
    'Пароль': 'password',
    'Профвнесок': 'membershipPaid',
    // Fallbacks if headers are in English
    'id': 'id',
    'fullName': 'fullName',
    'recordBookNumber': 'recordBookNumber',
    'universityPlace': 'universityPlace',
    'studyCourse': 'studyCourse',
    'groupCode': 'groupCode',
    'studyForm': 'studyForm',
    'paymentVariant': 'paymentVariant',
    'phoneNumber': 'phoneNumber',
    'telegram': 'telegram',
    'password': 'password',
    'uniqueCode': 'uniqueCode',
    'membershipPaid': 'membershipPaid',
  };

  static String _hashPassword(String plain) {
    final bytes = utf8.encode(plain);
    return sha256.convert(bytes).toString();
  }

  // ---------- READ via public gviz JSON feed ----------

  Future<List<Student>> _fetchAllStudents() async {
    final url = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$spreadsheetId/gviz/tq?tqx=out:json',
    );

    final http.Response response;
    try {
      response = await http.get(url).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw NetworkException('Немає підключення до інтернету');
    }

    if (response.statusCode != 200) {
      throw SheetUnavailableException(
          'Google Sheets недоступна (${response.statusCode})');
    }

    final body = response.body;
    final jsonStart = body.indexOf('{');
    final jsonEnd = body.lastIndexOf('}');
    if (jsonStart < 0 || jsonEnd < 0) {
      throw SheetUnavailableException('Невірний формат відповіді');
    }
    final jsonStr = body.substring(jsonStart, jsonEnd + 1);
    final data = json.decode(jsonStr) as Map<String, dynamic>;

    final table = data['table'] as Map<String, dynamic>;
    final rawLabels = (table['cols'] as List)
        .map((c) => (c as Map<String, dynamic>)['label']?.toString() ?? '')
        .toList();
    // Map Ukrainian column labels → English field names
    final fields = rawLabels
        .map((label) => _columnMapping[label] ?? label)
        .toList();
    final rows = table['rows'] as List? ?? [];

    final students = <Student>[];
    for (final row in rows) {
      final cells = (row as Map<String, dynamic>)['c'] as List;
      final map = <String, dynamic>{};
      for (var i = 0; i < fields.length && i < cells.length; i++) {
        final cell = cells[i];
        if (cell != null) {
          final cellMap = cell as Map<String, dynamic>;
          // Prefer formatted value (f) to avoid scientific notation for numbers
          map[fields[i]] = cellMap['f'] ?? cellMap['v'] ?? '';
        } else {
          map[fields[i]] = '';
        }
      }
      if (map['recordBookNumber']?.toString().trim().isNotEmpty ?? false) {
        students.add(Student.fromMap(map));
      }
    }
    return students;
  }

  // ---------- WRITE via Apps Script web app ----------

  Future<Map<String, dynamic>> _postToScript(
      Map<String, dynamic> payload) async {
    // Use GET with payload as query parameter.
    // Apps Script web apps redirect POST→GET which breaks on Flutter web.
    // GET requests follow redirects correctly in all platforms.
    final url = Uri.parse(_scriptUrl).replace(queryParameters: {
      'payload': json.encode(payload),
    });
    try {
      final response =
          await http.get(url).timeout(const Duration(seconds: 25));

      if (response.statusCode != 200) {
        throw NetworkException(
            'Сервер повернув помилку (${response.statusCode})');
      }

      final body = response.body;
      if (body.trimLeft().startsWith('<')) {
        throw NetworkException(
            'Сервер повернув HTML замість JSON. Перевірте деплой скрипта.');
      }

      return json.decode(body) as Map<String, dynamic>;
    } on http.ClientException {
      throw NetworkException('Немає підключення до інтернету');
    } catch (e) {
      if (e is GoogleSheetsException) rethrow;
      throw NetworkException('Помилка мережі: $e');
    }
  }

  // ---------- Public API ----------

  String _generateId() {
    final now = DateTime.now();
    final base = '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return 'PK$base';
  }

  /// Adds a new student record.
  Future<Student> addStudent(Student student) async {
    final existing = await _fetchAllStudents();
    if (existing.any((s) =>
        s.recordBookNumber.trim() == student.recordBookNumber.trim())) {
      throw UserAlreadyExistsException(
        'Студент з номером залікової ${student.recordBookNumber} вже існує',
      );
    }

    final id = _generateId();
    final hashedPw =
        student.password.isNotEmpty ? _hashPassword(student.password) : '';

    final newStudent = student.copyWith(id: id, password: hashedPw);

    try {
      await _postToScript({
        'action': 'addStudent',
        'data': newStudent.toMap(),
      });
    } catch (e) {
      if (e is GoogleSheetsException) rethrow;
      throw OperationFailedException('Не вдалося додати студента: $e');
    }

    return newStudent;
  }

  /// Finds a student by record book number.
  Future<Student?> findStudent(
      {String? recordBookNumber, String? uniqueCode}) async {
    final students = await _fetchAllStudents();

    if (recordBookNumber != null && recordBookNumber.trim().isNotEmpty) {
      for (final s in students) {
        if (s.recordBookNumber.trim() == recordBookNumber.trim()) {
          return s;
        }
      }
      throw UserNotFoundException('Студента з таким номером не знайдено');
    }

    if (uniqueCode != null && uniqueCode.trim().isNotEmpty) {
      for (final s in students) {
        if (s.uniqueCode.trim() == uniqueCode.trim()) {
          return s;
        }
      }
      throw UserNotFoundException('Студента з таким кодом не знайдено');
    }

    throw ArgumentError('Потрібно вказати recordBookNumber або uniqueCode');
  }

  /// Log in with record book number and password.
  Future<Student> login(String recordBookNumber, String password) async {
    final student = await findStudent(recordBookNumber: recordBookNumber);
    if (student == null) {
      throw UserNotFoundException('Студента не знайдено');
    }
    if (student.password.isEmpty) {
      throw PasswordNotSetException('Пароль ще не встановлено');
    }
    final hashed = _hashPassword(password);
    if (student.password != hashed) {
      throw WrongPasswordException('Невірний пароль');
    }
    return student;
  }

  /// Check if a student exists by record book (no password check).
  Future<Student> findByRecordBook(String recordBookNumber) async {
    final student = await findStudent(recordBookNumber: recordBookNumber);
    if (student == null) {
      throw UserNotFoundException('Студента з таким номером не знайдено');
    }
    return student;
  }

  /// Set password for an existing student. Also generates an ID if missing.
  Future<String> setPassword(
      String recordBookNumber, String newPassword) async {
    final hashed = _hashPassword(newPassword);
    final id = _generateId();
    try {
      await _postToScript({
        'action': 'setPassword',
        'recordBookNumber': recordBookNumber,
        'password': hashed,
        'id': id,
      });
    } catch (e) {
      if (e is GoogleSheetsException) rethrow;
      throw OperationFailedException('Не вдалося встановити пароль: $e');
    }
    return id;
  }

  /// Checks whether the student has paid membership.
  Future<bool> isMembershipPaid({required String recordBookNumber}) async {
    final student = await findStudent(recordBookNumber: recordBookNumber);
    return student?.membershipPaid ?? false;
  }

  /// Fetches partner discounts from the discounts Google Sheet.
  Future<List<PartnerDiscount>> fetchPartnerDiscounts() async {
    final url = Uri.parse(
      'https://docs.google.com/spreadsheets/d/$_discountsSpreadsheetId/gviz/tq?tqx=out:json',
    );

    final http.Response response;
    try {
      response = await http.get(url).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw NetworkException('Немає підключення до інтернету');
    }

    if (response.statusCode != 200) {
      throw SheetUnavailableException(
          'Google Sheets недоступна (${response.statusCode})');
    }

    final body = response.body;
    final jsonStart = body.indexOf('{');
    final jsonEnd = body.lastIndexOf('}');
    if (jsonStart < 0 || jsonEnd < 0) {
      throw SheetUnavailableException('Невірний формат відповіді');
    }
    final jsonStr = body.substring(jsonStart, jsonEnd + 1);
    final data = json.decode(jsonStr) as Map<String, dynamic>;

    final table = data['table'] as Map<String, dynamic>;
    final rawLabels = (table['cols'] as List)
        .map((c) => (c as Map<String, dynamic>)['label']?.toString() ?? '')
        .toList();
    final rows = table['rows'] as List? ?? [];

    final discounts = <PartnerDiscount>[];
    for (final row in rows) {
      final cells = (row as Map<String, dynamic>)['c'] as List;
      final values = <String>[];
      for (var i = 0; i < rawLabels.length && i < cells.length; i++) {
        final cell = cells[i];
        if (cell != null) {
          final cellMap = cell as Map<String, dynamic>;
          values.add((cellMap['f'] ?? cellMap['v'] ?? '').toString());
        } else {
          values.add('');
        }
      }

      // Map columns by header labels
      final map = <String, String>{};
      for (var i = 0; i < rawLabels.length && i < values.length; i++) {
        map[rawLabels[i].trim()] = values[i];
      }

      // Try to find partner name, promo code, and comment by known Ukrainian headers
      final partnerName = map['Назва партнера'] ?? map['Партнер'] ?? map['Назва'] ?? (values.isNotEmpty ? values[0] : '');
      final promoCode = map['Промокод'] ?? (values.length > 1 ? values[1] : '');
      final comment = map['Коментар'] ?? map['Опис'] ?? map['Знижка'] ?? (values.length > 2 ? values[2] : '');

      if (partnerName.trim().isNotEmpty) {
        discounts.add(PartnerDiscount(
          partnerName: partnerName,
          promoCode: promoCode,
          comment: comment,
        ));
      }
    }
    return discounts;
  }
}

// ---------- Exceptions ----------

class GoogleSheetsException implements Exception {
  final String message;
  GoogleSheetsException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends GoogleSheetsException {
  NetworkException(super.message);
}

class SheetUnavailableException extends GoogleSheetsException {
  SheetUnavailableException(super.message);
}

class UserNotFoundException extends GoogleSheetsException {
  UserNotFoundException(super.message);
}

class UserAlreadyExistsException extends GoogleSheetsException {
  UserAlreadyExistsException(super.message);
}

class DuplicateDataException extends GoogleSheetsException {
  DuplicateDataException(super.message);
}

class OperationFailedException extends GoogleSheetsException {
  OperationFailedException(super.message);
}

class PasswordNotSetException extends GoogleSheetsException {
  PasswordNotSetException(super.message);
}

class WrongPasswordException extends GoogleSheetsException {
  WrongPasswordException(super.message);
}
