class Student {
  final String id;
  final String fullName;
  final String recordBookNumber;
  final String universityPlace;
  final String studyCourse;
  final String groupCode;
  final String studyForm;
  final String paymentVariant;
  final String phoneNumber;
  final String telegram;
  final String password;
  final String uniqueCode;
  final bool membershipPaid;

  const Student({
    required this.id,
    required this.fullName,
    required this.recordBookNumber,
    required this.universityPlace,
    required this.studyCourse,
    required this.groupCode,
    required this.studyForm,
    required this.paymentVariant,
    required this.phoneNumber,
    required this.telegram,
    required this.password,
    required this.uniqueCode,
    required this.membershipPaid,
  });

  factory Student.fromMap(Map<String, dynamic> map) {
    bool parseBool(dynamic value) {
      if (value == null) return false;
      if (value is bool) return value;
      final normalized = value.toString().trim().toLowerCase();
      return normalized == 'true' || normalized == 'yes' || normalized == '1';
    }

    return Student(
      id: map['id']?.toString() ?? '',
      fullName: map['fullName']?.toString() ?? '',
      recordBookNumber: map['recordBookNumber']?.toString() ?? '',
      universityPlace: map['universityPlace']?.toString() ?? '',
      studyCourse: map['studyCourse']?.toString() ?? '',
      groupCode: map['groupCode']?.toString() ?? '',
      studyForm: map['studyForm']?.toString() ?? '',
      paymentVariant: map['paymentVariant']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString() ?? '',
      telegram: map['telegram']?.toString() ?? '',
      password: map['password']?.toString() ?? '',
      uniqueCode: map['uniqueCode']?.toString() ?? '',
      membershipPaid: parseBool(map['membershipPaid']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'recordBookNumber': recordBookNumber,
      'universityPlace': universityPlace,
      'studyCourse': studyCourse,
      'groupCode': groupCode,
      'studyForm': studyForm,
      'paymentVariant': paymentVariant,
      'phoneNumber': phoneNumber,
      'telegram': telegram,
      'password': password,
      'uniqueCode': uniqueCode,
      'membershipPaid': membershipPaid ? 'true' : 'false',
    };
  }

  Student copyWith({
    String? id,
    String? fullName,
    String? recordBookNumber,
    String? universityPlace,
    String? studyCourse,
    String? groupCode,
    String? studyForm,
    String? paymentVariant,
    String? phoneNumber,
    String? telegram,
    String? password,
    String? uniqueCode,
    bool? membershipPaid,
  }) {
    return Student(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      recordBookNumber: recordBookNumber ?? this.recordBookNumber,
      universityPlace: universityPlace ?? this.universityPlace,
      studyCourse: studyCourse ?? this.studyCourse,
      groupCode: groupCode ?? this.groupCode,
      studyForm: studyForm ?? this.studyForm,
      paymentVariant: paymentVariant ?? this.paymentVariant,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      telegram: telegram ?? this.telegram,
      password: password ?? this.password,
      uniqueCode: uniqueCode ?? this.uniqueCode,
      membershipPaid: membershipPaid ?? this.membershipPaid,
    );
  }
}
