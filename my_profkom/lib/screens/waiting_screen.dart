import 'dart:async';

import 'package:flutter/material.dart';
import 'package:my_profkom/models/student.dart';
import 'package:my_profkom/screens/discounts_screen.dart';
import 'package:my_profkom/services/google_sheets_service.dart';
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
      appBar: AppBar(title: const Text('Очікування перевірки')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            const Icon(Icons.hourglass_top, size: 64),
            const SizedBox(height: 24),
            const Text(
              'Зачекайте, перевіряємо, чи ви сплатили профвнесок',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ваш унікальний код: ${_student.uniqueCode}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            if (_isChecking) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 12),
              const Text(
                'Перевіряємо статус...',
                textAlign: TextAlign.center,
              ),
            ],
            const Spacer(),
            ElevatedButton(
              onPressed: _checkStatus,
              child: const Text('Оновити статус'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('Повернутися на початок'),
            ),
          ],
        ),
      ),
    );
  }
}
