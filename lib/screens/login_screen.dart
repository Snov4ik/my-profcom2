import 'package:flutter/material.dart';
import 'package:my_profkom/services/google_sheets_service.dart';
import 'package:my_profkom/utils/app_routes.dart';
import 'package:my_profkom/utils/app_theme.dart';
import 'package:my_profkom/utils/error_ui.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recordBookController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _recordBookController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final recordBook = _recordBookController.text.trim();
      final password = _passwordController.text;

      final student = await GoogleSheetsService.instance.login(
        recordBook,
        password,
      );

      if (!mounted) return;

      final destination = student.membershipPaid
          ? AppRoutes.discounts
          : AppRoutes.waiting;
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
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: const Text('Користувача не знайдено'),
            content: const Text('Здається, ви ще не вступили в профспілку.'),
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
    } on PasswordNotSetException catch (_) {
      if (!mounted) return;
      showErrorSnackBar(
          context, 'Пароль ще не встановлено. Натисніть "Немає пароля"');
    } on WrongPasswordException catch (_) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Невірний пароль');
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(flex: 2),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.yellow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.people_alt_rounded,
                    size: 28, color: AppColors.dark),
              ),
              const SizedBox(height: 24),
              const Text(
                'Профспілка КНЕУ вітає',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Увійдіть за номером залікової книжки',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.dark.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 36),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _recordBookController,
                      decoration: const InputDecoration(
                        labelText: 'Номер залікової книжки',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Поле не може бути порожнім';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Пароль',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.dark.withValues(alpha: 0.4),
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введіть пароль';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _handleLogin(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
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
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.setPassword);
                  },
                  child: const Text('Немає пароля?'),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed(AppRoutes.register);
                  },
                  child: const Text('Ще не вступили в профспілку?'),
                ),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
