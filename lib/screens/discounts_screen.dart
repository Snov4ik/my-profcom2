import 'package:flutter/material.dart';
import 'package:my_profkom/models/discount.dart';
import 'package:my_profkom/models/student.dart';
import 'package:my_profkom/services/google_sheets_service.dart';
import 'package:my_profkom/utils/app_theme.dart';

class DiscountsScreen extends StatefulWidget {
  const DiscountsScreen({super.key, required this.student});

  final Student student;

  @override
  State<DiscountsScreen> createState() => _DiscountsScreenState();
}

class _DiscountsScreenState extends State<DiscountsScreen> {
  late Future<List<PartnerDiscount>> _discountsFuture;

  @override
  void initState() {
    super.initState();
    _discountsFuture = GoogleSheetsService.instance.fetchPartnerDiscounts();
  }

  String _resolvePromoCode(PartnerDiscount discount) {
    final code = discount.promoCode.trim().toLowerCase();
    if (code == 'ваш особистий id' || code == 'id') {
      final studentId = widget.student.id.trim();
      return studentId.isNotEmpty ? studentId : discount.promoCode;
    }
    return discount.promoCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Знижки')),
      body: FutureBuilder<List<PartnerDiscount>>(
        future: _discountsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.yellow),
            );
          }

          if (snapshot.hasError) {
            final error = snapshot.error;
            String message;
            if (error is NetworkException || error is SheetUnavailableException) {
              message = error.toString();
            } else {
              message = 'Помилка при завантаженні знижок';
            }

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.dark.withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.dark.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _discountsFuture =
                              GoogleSheetsService.instance.fetchPartnerDiscounts();
                        });
                      },
                      child: const Text('Спробувати ще раз'),
                    ),
                  ],
                ),
              ),
            );
          }

          final discounts = snapshot.data ?? [];
          if (discounts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_offer_outlined, size: 48, color: AppColors.dark.withValues(alpha: 0.3)),
                  const SizedBox(height: 12),
                  Text(
                    'Поки що немає активних знижок',
                    style: TextStyle(color: AppColors.dark.withValues(alpha: 0.5)),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: discounts.length,
            itemBuilder: (context, index) {
              final item = discounts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEEEEEA)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.local_offer_rounded, size: 22, color: AppColors.brown),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.partnerName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.dark,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.comment,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.dark.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.yellow,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _resolvePromoCode(item),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: AppColors.dark,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
