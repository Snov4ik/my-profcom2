import 'package:flutter/material.dart';
import 'package:my_profkom/models/student.dart';
import 'package:my_profkom/services/google_sheets_service.dart';
import 'package:my_profkom/utils/app_routes.dart';
import 'package:my_profkom/utils/error_ui.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _recordBookController = TextEditingController();
  final _universityController = TextEditingController();
  final _courseController = TextEditingController();
  final _groupController = TextEditingController();
  final _studyFormController = TextEditingController();
  final _paymentVariantController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _recordBookController.dispose();
    _universityController.dispose();
    _courseController.dispose();
    _groupController.dispose();
    _studyFormController.dispose();
    _paymentVariantController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    super.dispose();
  }

  Future<void> _onSubmit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final student = Student(
      fullName: _fullNameController.text.trim(),
      recordBookNumber: _recordBookController.text.trim(),
      universityPlace: _universityController.text.trim(),
      studyCourse: _courseController.text.trim(),
      groupCode: _groupController.text.trim(),
      studyForm: _studyFormController.text.trim(),
      paymentVariant: _paymentVariantController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      telegram: _telegramController.text.trim(),
      uniqueCode: '',
      membershipPaid: false,
    );

    try {
      await GoogleSheetsService.instance.addStudent(student);

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        AppRoutes.waiting,
        arguments: student,
      );
    } on UserAlreadyExistsException catch (e) {
      showErrorDialog(context, 'Студент уже існує', e.message);
    } on DuplicateDataException catch (e) {
      showErrorDialog(context, 'Конфлікт даних', e.message);
    } on NetworkException catch (e) {
      showErrorSnackBar(context, e.message);
    } on SheetUnavailableException catch (e) {
      showErrorSnackBar(context, e.message);
    } catch (e) {
      showErrorSnackBar(context, 'Помилка під час реєстрації: $e');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String? _notEmptyValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Поле не може бути порожнім';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Реєстрація')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const Text(
                  'Заповніть інформацію для реєстрації в профспілці',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Ваш повний ПІБ',
                  ),
                  validator: _notEmptyValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _recordBookController,
                  decoration: const InputDecoration(
                    labelText: 'Номер залікової книжки',
                  ),
                  validator: _notEmptyValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _universityController,
                  decoration: const InputDecoration(
                    labelText: 'Де ви навчаєтесь',
                  ),
                  validator: _notEmptyValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _courseController,
                  decoration: const InputDecoration(
                    labelText: 'Курс навчання',
                  ),
                  validator: _notEmptyValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _groupController,
                  decoration: const InputDecoration(
                    labelText: 'Код і номер групи',
                  ),
                  validator: _notEmptyValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _studyFormController,
                  decoration: const InputDecoration(
                    labelText: 'Ваша форма навчання',
                  ),
                  validator: _notEmptyValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paymentVariantController,
                  decoration: const InputDecoration(
                    labelText: 'Варіант сплати профвнесків',
                  ),
                  validator: _notEmptyValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Ваш номер телефону',
                  ),
                  keyboardType: TextInputType.phone,
                  validator: _notEmptyValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telegramController,
                  decoration: const InputDecoration(
                    labelText: 'Ваш Telegram',
                  ),
                  validator: _notEmptyValidator,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _onSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Зареєструватися'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
