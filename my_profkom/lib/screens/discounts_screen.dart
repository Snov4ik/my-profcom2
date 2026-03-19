import 'package:flutter/material.dart';
import 'package:my_profkom/models/discount.dart';
import 'package:my_profkom/models/student.dart';
import 'package:my_profkom/services/google_sheets_service.dart';

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
    if (discount.comment.trim().toLowerCase() == 'особистий промокод') {
      return widget.student.uniqueCode;
    }
    return discount.promoCode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Знижки від партнерів')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<PartnerDiscount>>(
          future: _discountsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message),
                    const SizedBox(height: 12),
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
              );
            }

            final discounts = snapshot.data ?? [];
            if (discounts.isEmpty) {
              return const Center(child: Text('Поки що немає активних знижок.'));
            }

            return ListView.separated(
              itemCount: discounts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = discounts[index];
                return ListTile(
                  title: Text(item.partnerName),
                  subtitle: Text(item.comment),
                  trailing: Text(_resolvePromoCode(item)),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
