
part of 'cart_screen.dart';

@RoutePage()
class CartCommentScreen extends StatefulWidget {
  const CartCommentScreen({super.key});

  @override
  State<CartCommentScreen> createState() => _CartCommentScreenState();
}

class _CartCommentScreenState extends State<CartCommentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _commentController = TextEditingController();

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _prefillFromProfile();
  }

  Future<void> _prefillFromProfile() async {
    try {
      final profile = await GetIt.I<AbstractProfileRepository>().getProfile();
      if (!mounted) return;
      final name = [profile.firstName, profile.lastName]
          .where((e) => e != null && e!.isNotEmpty)
          .join(' ');
      if (_nameController.text.isEmpty && name.isNotEmpty) {
        _nameController.text = name;
      }
      if (_phoneController.text.isEmpty &&
          (profile.phone?.isNotEmpty ?? false)) {

        final digits = profile.phone!.replaceAll(RegExp(r'\D'), '');
        final local = (digits.length == 11 &&
                (digits.startsWith('7') || digits.startsWith('8')))
            ? digits.substring(1)
            : digits;
        _phoneController.value = _phoneFormatter.formatEditUpdate(
          const TextEditingValue(),
          TextEditingValue(text: local),
        );
      }
    } catch (_) {

    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<CartBloc>().add(
            SetCheckoutDetails(
              customerName: _nameController.text.trim(),
              customerPhone: _phoneController.text.trim(),
              comment: _commentController.text.trim(),
            ),
          );
      AutoTabsRouter.of(context).setActiveIndex(2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Text(
              'Контактные данные',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Имя*',
                hintText: 'Введите ваше имя',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Пожалуйста, введите ваше имя';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Номер телефона*',
                hintText: '+7 (999) 123-45-67',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [_phoneFormatter],
              validator: (value) {
                if (!_phoneFormatter.isFill()) {
                  return 'Пожалуйста, введите полный номер телефона';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'Комментарий к заказу',
                hintText: 'Например, "без лука"',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.comment_bank_outlined),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _continue,
                child: const Text('К выбору оплаты'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
