import 'package:my_profkom/models/discount.dart';

/// Stub service for partner discounts.
///
/// In a real implementation this would query another Google Sheet (or API)
/// and return a list of active discounts.
class PartnerDiscountService {
  PartnerDiscountService._();

  static final PartnerDiscountService instance = PartnerDiscountService._();

  /// Returns current partner discounts.
  ///
  /// In a real app this would fetch rows from a Google Sheet.
  Future<List<PartnerDiscount>> fetchDiscounts() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));

    return const [
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
  }
}
