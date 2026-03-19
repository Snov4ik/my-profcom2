import 'package:flutter/material.dart';
import 'package:my_profkom/services/google_sheets_service.dart';
import 'package:my_profkom/utils/app_routes.dart';
import 'package:my_profkom/utils/error_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recordBookController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _recordBookController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final recordBook = _recordBookController.text.trim();
      final student = await GoogleSheetsService.instance.findStudent(
        recordBookNumber: recordBook,
      );

      if (!mounted) return;

      final destination =
          (student?.membershipPaid ?? false) ? AppRoutes.discounts : AppRoutes.waiting;
      Navigator.of(context).pushReplacementNamed(
        destination,
        arguments: student,
      );
    } on UserNotFoundException catch (_) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Користувача не знайдено'),
            content: const Text('Здається, ви ще не зареєструвалися.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Спробувати ще раз'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushNamed(AppRoutes.register);
                },
                child: const Text('Зареєструватися'),
              ),
            ],
          );
        },
      );
    } on NetworkException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.message);
    } on SheetUnavailableException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Сталася помилка під час входу: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вхід')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Вхід до профспілки',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Введіть номер залікової книжки або ваш унікальний код.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _recordBookController,
                decoration: const InputDecoration(
                  labelText: 'Номер залікової книжки',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Поле не може бути порожнім';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _handleLogin(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Увійти'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.register);
              },
              child: const Text('Ще не зареєстровані?'),
            ),
          ],
        ),
      ),
    );
  }
}
