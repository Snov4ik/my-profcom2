class PartnerDiscount {
  final String partnerName;
  final String promoCode;
  final String comment;

  const PartnerDiscount({
    required this.partnerName,
    required this.promoCode,
    required this.comment,
  });

  factory PartnerDiscount.fromMap(Map<String, dynamic> map) {
    return PartnerDiscount(
      partnerName: map['partnerName']?.toString() ?? '',
      promoCode: map['promoCode']?.toString() ?? '',
      comment: map['comment']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'partnerName': partnerName,
      'promoCode': promoCode,
      'comment': comment,
    };
  }
}
