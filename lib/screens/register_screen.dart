import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_profkom/models/student.dart';
import 'package:my_profkom/services/google_sheets_service.dart';
import 'package:my_profkom/utils/app_routes.dart';
import 'package:my_profkom/utils/app_theme.dart';
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
  final _groupController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  String? _selectedFaculty;
  String? _selectedCourse;
  String? _selectedStudyForm;
  String? _selectedPaymentVariant;

  bool _agreePersonalData = false;
  bool _agreePayFees = false;
  bool _agreeRegulation = false;

  bool _isSubmitting = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  static const List<String> _faculties = [
    'МЕІМ',
    'ФМ',
    'ФЕТАУ',
    'ІІТЕ',
    'ФУПСТАП',
    'ОПМ',
    'ФФ',
    'ЮІ',
    'ЕК',
    'КІСІТ',
  ];

  static const List<String> _courses = ['1', '2', '3', '4', '5', '6'];

  static const List<String> _studyForms = ['Бюджет', 'Контракт'];

  static const List<String> _paymentOptionsAll = [
    '1 місяць — 20 грн',
    '6 місяців — 120 грн',
    '1 рік — 240 грн',
  ];

  static const String _paymentBudgetOnly =
      '1% зі стипендії кожного місяця';

  List<String> get _paymentOptions {
    if (_selectedStudyForm == 'Бюджет') {
      return [..._paymentOptionsAll, _paymentBudgetOnly];
    }
    return _paymentOptionsAll;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _recordBookController.dispose();
    _groupController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool get _requiresDirectPayment {
    return _selectedPaymentVariant != null &&
        _selectedPaymentVariant != _paymentBudgetOnly;
  }

  static const String _paymentQrUrl =
      'https://bank.gov.ua/qr/QkNECjAwMgoyClVDVAoKz9DO1NHPssvKwCDPz87RwCAgys3F0yCyzMXNsiDCwMTYzMAgw8XS3MzAzcAKVUExMTMwNTI5OTAwMDAwMjYwMDAwMTUwMDM2NzUKVUFICjIyODczNTg1CgoKCg==';

  Future<bool> _showPaymentDialog() async {
    bool confirmed = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool paid = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Сплатити профвнесок',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Оберіть посилання нижче для оплати профвнеску ($_selectedPaymentVariant):',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse(_paymentQrUrl);
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.yellow.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.yellow, width: 1.5),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.payment_rounded, color: AppColors.dark),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Перейти до оплати',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.dark,
                              ),
                            ),
                          ),
                          Icon(Icons.open_in_new, size: 18, color: AppColors.brown),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: paid,
                          onChanged: (v) => setDialogState(() => paid = v ?? false),
                          activeColor: AppColors.yellow,
                          checkColor: AppColors.dark,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Я сплатив профвнесок',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    confirmed = false;
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('Скасувати'),
                ),
                ElevatedButton(
                  onPressed: paid
                      ? () {
                          confirmed = true;
                          Navigator.of(ctx).pop();
                        }
                      : null,
                  child: const Text('Підтвердити'),
                ),
              ],
            );
          },
        );
      },
    );
    return confirmed;
  }

  Future<void> _onSubmit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    if (_selectedFaculty == null ||
        _selectedCourse == null ||
        _selectedStudyForm == null ||
        _selectedPaymentVariant == null) {
      showErrorSnackBar(context, 'Оберіть усі обов\'язкові поля');
      return;
    }
    if (!_agreePersonalData || !_agreePayFees || !_agreeRegulation) {
      showErrorSnackBar(context, 'Необхідно погодитись з усіма умовами');
      return;
    }

    // Show payment dialog for direct payment options
    if (_requiresDirectPayment) {
      final paid = await _showPaymentDialog();
      if (!paid) return;
    }

    setState(() => _isSubmitting = true);

    final student = Student(
      id: '',
      fullName: _fullNameController.text.trim(),
      recordBookNumber: _recordBookController.text.trim(),
      universityPlace: _selectedFaculty!,
      studyCourse: _selectedCourse!,
      groupCode: _groupController.text.trim(),
      studyForm: _selectedStudyForm!,
      paymentVariant: _selectedPaymentVariant!,
      phoneNumber: _phoneController.text.trim(),
      telegram: _telegramController.text.trim(),
      password: _passwordController.text,
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

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? 'Оберіть значення' : null,
      dropdownColor: AppColors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _buildCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required Widget label,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.yellow,
              checkColor: AppColors.dark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: label),
        ],
      ),
    );
  }

  Future<void> _openRegulationLink() async {
    final uri = Uri.parse(
      'https://drive.google.com/file/d/1-zM0qIdkoeoqN6TKg3CrYo7dQfnuVypB/view?usp=sharing',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Реєстрація')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Створіть обліковий запис',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Заповніть дані для вступу до профспілки',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.dark.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Повне ПІБ'),
                  validator: _notEmptyValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _recordBookController,
                  decoration: const InputDecoration(
                      labelText: 'Номер залікової книжки'),
                  validator: (v) {
                    if (v == null || v.trim().length < 4) {
                      return 'Мінімум 4 символи';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                _buildDropdown(
                  label: 'Факультет / інститут',
                  value: _selectedFaculty,
                  items: _faculties,
                  onChanged: (v) => setState(() => _selectedFaculty = v),
                ),
                const SizedBox(height: 14),
                _buildDropdown(
                  label: 'Курс',
                  value: _selectedCourse,
                  items: _courses,
                  onChanged: (v) => setState(() => _selectedCourse = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _groupController,
                  decoration:
                      const InputDecoration(labelText: 'Код і номер групи'),
                  validator: _notEmptyValidator,
                ),
                const SizedBox(height: 14),
                _buildDropdown(
                  label: 'Форма навчання',
                  value: _selectedStudyForm,
                  items: _studyForms,
                  onChanged: (v) => setState(() {
                    _selectedStudyForm = v;
                    // Reset payment if switching away from Бюджет
                    // and the selected option is budget-only
                    if (v != 'Бюджет' &&
                        _selectedPaymentVariant == _paymentBudgetOnly) {
                      _selectedPaymentVariant = null;
                    }
                  }),
                ),
                const SizedBox(height: 14),
                _buildDropdown(
                  label: 'Варіант сплати профвнесків',
                  value: _selectedPaymentVariant,
                  items: _paymentOptions,
                  onChanged: (v) =>
                      setState(() => _selectedPaymentVariant = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  decoration:
                      const InputDecoration(labelText: 'Номер телефону (+380...)'),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Поле не може бути порожнім';
                    }
                    if (!v.trim().startsWith('+380')) {
                      return 'Номер має починатися з +380';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _telegramController,
                  decoration: const InputDecoration(labelText: 'Telegram'),
                  validator: _notEmptyValidator,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Пароль',
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
                    if (v == null || v.length < 6) {
                      return 'Пароль має бути не менше 6 символів';
                    }
                    if (RegExp(r'[а-яА-ЯіІїЇєЄґҐ]').hasMatch(v)) {
                      return 'Пароль не може містити кирилицю';
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
                    if (v == null || v.isEmpty) {
                      return 'Підтвердіть пароль';
                    }
                    if (v != _passwordController.text) {
                      return 'Паролі не збігаються';
                    }
                    return null;
                  },
                ),

                // — Checkboxes —
                const SizedBox(height: 24),
                _buildCheckbox(
                  value: _agreePersonalData,
                  onChanged: (v) =>
                      setState(() => _agreePersonalData = v ?? false),
                  label: const Text(
                    'Даю згоду на обробку персональних даних',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
                _buildCheckbox(
                  value: _agreePayFees,
                  onChanged: (v) =>
                      setState(() => _agreePayFees = v ?? false),
                  label: const Text(
                    'Я зобов\'язуюсь сплачувати профвнески',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                const SizedBox(height: 6),
                _buildCheckbox(
                  value: _agreeRegulation,
                  onChanged: (v) =>
                      setState(() => _agreeRegulation = v ?? false),
                  label: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 13),
                      children: [
                        const TextSpan(
                          text:
                              'Я підтверджую, що ознайомився з ',
                        ),
                        TextSpan(
                          text:
                              'положенням Про порядок постановки на облік членів та збору членських профспілкових внесків',
                          style: const TextStyle(
                            color: AppColors.brown,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _openRegulationLink,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 28),
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
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
