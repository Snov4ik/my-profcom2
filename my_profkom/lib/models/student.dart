class Student {
  final String fullName;
  final String recordBookNumber;
  final String universityPlace;
  final String studyCourse;
  final String groupCode;
  final String studyForm;
  final String paymentVariant;
  final String phoneNumber;
  final String telegram;
  final String uniqueCode;
  final bool membershipPaid;

  const Student({
    required this.fullName,
    required this.recordBookNumber,
    required this.universityPlace,
    required this.studyCourse,
    required this.groupCode,
    required this.studyForm,
    required this.paymentVariant,
    required this.phoneNumber,
    required this.telegram,
    required this.uniqueCode,
    required this.membershipPaid,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    // Google Sheets values tend to come as strings. Convert as needed.
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      final normalized = value.toString().trim().toLowerCase();
      return normalized == 'true' || normalized == 'yes' || normalized == '1';
    }

    return Student(
      fullName: map['fullName']?.toString() ?? '',
      recordBookNumber: map['recordBookNumber']?.toString() ?? '',
      universityPlace: map['universityPlace']?.toString() ?? '',
      studyCourse: map['studyCourse']?.toString() ?? '',
      groupCode: map['groupCode']?.toString() ?? '',
      studyForm: map['studyForm']?.toString() ?? '',
      paymentVariant: map['paymentVariant']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      telegram: map['telegram']?.toString() ?? '',
      uniqueCode: map['uniqueCode']?.toString() ?? '',
      membershipPaid: parseBool(map['membershipPaid']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'recordBookNumber': recordBookNumber,
      'universityPlace': universityPlace,
      'studyCourse': studyCourse,
      'groupCode': groupCode,
      'studyForm': studyForm,
      'paymentVariant': paymentVariant,
      'phoneNumber': phoneNumber,
      'telegram': telegram,
      'uniqueCode': uniqueCode,
      'membershipPaid': membershipPaid ? 'true' : 'false',
    };
  }
}
