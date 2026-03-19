import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_profkom/models/student.dart';
import 'package:my_profkom/screens/discounts_screen.dart';
import 'package:my_profkom/services/google_sheets_service.dart';
import 'package:my_profkom/utils/app_theme.dart';
import 'package:my_profkom/utils/error_ui.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key, required this.student});

  final Student student;

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen> {
  late Student _student;
  Timer? _refreshTimer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _scheduleRefresh();
    _checkStatus();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _scheduleRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkStatus();
    });
  }

  Future<void> _checkStatus() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final latest = await GoogleSheetsService.instance
          .findStudent(recordBookNumber: _student.recordBookNumber);

      if (!mounted) return;

      if (latest == null) {
        showErrorSnackBar(context, 'Користувача не знайдено');
        return;
      }

      if (latest.membershipPaid) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => DiscountsScreen(student: latest),
          ),
        );
        return;
      }

      setState(() {
        _student = latest;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.message);
    } on SheetUnavailableException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.message);
    } on UserNotFoundException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Помилка під час перевірки статусу: $e');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Очікування')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          children: [
            const Spacer(flex: 2),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.hourglass_top_rounded, size: 40, color: AppColors.brown),
            ),
            const SizedBox(height: 28),
            const Text(
              'Перевіряємо оплату',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: AppColors.dark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Зачекайте, поки ми підтвердимо сплату профвнеску',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.dark.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 28),
            if (_isChecking)
              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.yellow,
                ),
              ),
            const Spacer(flex: 2),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isChecking ? null : _checkStatus,
                child: const Text('Оновити статус'),
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Повернутися на початок'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
