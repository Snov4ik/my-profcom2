import 'package:flutter/material.dart';
import 'package:my_profkom/services/google_sheets_service.dart';
import 'package:my_profkom/utils/app_routes.dart';
import 'package:my_profkom/utils/app_theme.dart';
import 'package:my_profkom/utils/error_ui.dart';

class SetPasswordScreen extends StatefulWidget {
  const SetPasswordScreen({super.key});

  @override
  State<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends State<SetPasswordScreen> {
  final _recordBookController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _studentFound = false;
  String _studentName = '';
  String _foundRecordBook = '';
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _recordBookController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _searchStudent() async {
    final rb = _recordBookController.text.trim();
    if (rb.isEmpty) {
      showErrorSnackBar(context, 'Введіть номер залікової книжки');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final student = await GoogleSheetsService.instance.findByRecordBook(rb);
      if (!mounted) return;

      if (student.password.isNotEmpty) {
        showErrorSnackBar(context, 'Пароль вже встановлено для цього акаунту');
        return;
      }

      setState(() {
        _studentFound = true;
        _studentName = student.fullName;
        _foundRecordBook = rb;
      });
    } on UserNotFoundException catch (_) {
      if (!mounted) return;
      showErrorSnackBar(
          context, 'Студента з таким номером залікової не знайдено');
    } on NetworkException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Помилка: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final studentId = await GoogleSheetsService.instance.setPassword(
        _foundRecordBook,
        _passwordController.text,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Пароль встановлено'),
          content:
              const Text('Тепер ви можете увійти з вашим новим паролем.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              },
              child: const Text('Увійти'),
            ),
          ],
        ),
      );
    } on OperationFailedException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.message);
    } on NetworkException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.message);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, 'Помилка: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Встановити пароль')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: _studentFound ? _buildSetPasswordForm() : _buildSearchForm(),
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Перевірка акаунту',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Введіть номер залікової книжки для пошуку',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.dark.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 32),
        TextFormField(
          controller: _recordBookController,
          decoration: const InputDecoration(
            labelText: 'Номер залікової книжки',
          ),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _searchStudent(),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _searchStudent,
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Знайти'),
          ),
        ),
      ],
    );
  }

  Widget _buildSetPasswordForm() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          const SizedBox(height: 16),
          const Text(
            'Встановити пароль',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Акаунт знайдено',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.dark.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.yellow.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: AppColors.yellow.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: AppColors.dark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _studentName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Новий пароль',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure1
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
                onPressed: () =>
                    setState(() => _obscure1 = !_obscure1),
              ),
            ),
            obscureText: _obscure1,
            validator: (v) {
              if (v == null || v.length < 4) {
                return 'Пароль має бути не менше 4 символів';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Підтвердіть пароль',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure2
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.dark.withValues(alpha: 0.4),
                ),
                onPressed: () =>
                    setState(() => _obscure2 = !_obscure2),
              ),
            ),
            obscureText: _obscure2,
            validator: (v) {
              if (v != _passwordController.text) {
                return 'Паролі не збігаються';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _setPassword,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Встановити пароль'),
            ),
          ),
        ],
      ),
    );
  }
}
