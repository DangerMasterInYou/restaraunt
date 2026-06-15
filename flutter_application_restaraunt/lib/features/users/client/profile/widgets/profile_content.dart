
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/core/repositories/users/client/profile/profile.dart';
import '/core/services/app_toast.dart';
import '/features/theme/bloc/theme_bloc.dart';
import '../bloc/profile_bloc.dart';

class ProfileContent extends StatefulWidget {
  const ProfileContent({
    super.key,
    required this.profile,
    required this.profileBloc,
  });

  final ProfileResponse profile;
  final ProfileBloc profileBloc;

  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  bool _isEditing = false;

  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _birthdayController;

  final DateFormat _dateFormat = DateFormat('dd.MM.yyyy');
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void didUpdateWidget(covariant ProfileContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile.id != oldWidget.profile.id && !_isEditing) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    _firstNameController =
        TextEditingController(text: widget.profile.firstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.profile.lastName ?? '');
    _phoneController = TextEditingController();

    final rawPhone = widget.profile.phone ?? '';
    if (rawPhone.isNotEmpty) {
      final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
      final local = (digits.length == 11 &&
              (digits.startsWith('7') || digits.startsWith('8')))
          ? digits.substring(1)
          : digits;
      _phoneController.value = _phoneMaskFormatter.formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(text: local),
      );
    }
    _birthdayController = TextEditingController(
        text: widget.profile.birthday != null
            ? _dateFormat.format(widget.profile.birthday!)
            : '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  void _toggleEditState() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) _initializeControllers();
    });
  }

  void _saveProfile() {

    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (_phoneController.text.isNotEmpty && phoneDigits.length < 11) {
      AppToast.error(context, 'Введите полный номер телефона');
      return;
    }

    DateTime? birthdayDate;
    if (_birthdayController.text.isNotEmpty) {
      try {
        birthdayDate = _dateFormat.parse(_birthdayController.text);
      } catch (e) {
        AppToast.error(context, 'Неверный формат даты. Используйте ДД.ММ.ГГГГ');
        return;
      }
    }

    final patchDto = ProfilePatchDTO(
      firstName: _firstNameController.text != (widget.profile.firstName ?? '')
          ? _firstNameController.text
          : null,
      lastName: _lastNameController.text != (widget.profile.lastName ?? '')
          ? _lastNameController.text
          : null,
      phone: _phoneController.text != (widget.profile.phone ?? '')
          ? _phoneController.text
          : null,
      birthday: birthdayDate?.toIso8601String() !=
              widget.profile.birthday?.toIso8601String()
          ? birthdayDate
          : null,
    );

    if (patchDto.toJson().isEmpty) {
      AppToast.info(context, 'Нет изменений для сохранения');
      _toggleEditState();
      return;
    }

    widget.profileBloc.add(UpdateProfile(patchDto: patchDto));
    setState(() => _isEditing = false);
  }

  void _confirmDeleteProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удаление профиля'),
        content: const Text(
            'Вы уверены, что хотите безвозвратно удалить свой профиль? Все ваши данные будут стерты.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();

              widget.profileBloc.add(const DeleteProfile());
            },
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      alignment: Alignment.center,
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Container(
            padding: EdgeInsets.all(screenWidth > 400 ? 24.0 : 16.0),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Личные данные',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _ThemeToggleTile(theme: theme),
                const SizedBox(height: 8),
                Divider(color: theme.dividerColor),
                _buildProfileField(
                  label: 'Имя',
                  icon: Icons.person_outline,
                  controller: _firstNameController,
                  isEditable: true,
                ),
                _buildProfileField(
                  label: 'Фамилия',
                  icon: Icons.person_outline,
                  controller: _lastNameController,
                  isEditable: true,
                ),
                _buildProfileField(
                  label: 'Email',
                  icon: Icons.email_outlined,
                  controller: TextEditingController(text: widget.profile.email),
                  isEditable: false,
                ),
                _buildProfileField(
                  label: 'Телефон',
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                  isEditable: true,
                  keyboardType: TextInputType.phone,
                  formatter: _phoneMaskFormatter,
                ),
                _buildProfileField(
                  label: 'Дата рождения',
                  icon: Icons.cake_outlined,
                  controller: _birthdayController,
                  isEditable: true,

                  onTap: _isEditing ? _selectDate : null,
                ),
                const SizedBox(height: 32),
                if (_isEditing) ...[
                  ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Сохранить',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _toggleEditState,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      foregroundColor: theme.colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Отмена'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: _toggleEditState,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Редактировать профиль',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _confirmDeleteProfile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Удалить профиль'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isEditable = false,
    TextInputType? keyboardType,
    MaskTextInputFormatter? formatter,
    Future<void> Function()? onTap,
  }) {
    final theme = Theme.of(context);
    final isReadOnly = !_isEditing || !isEditable;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: controller,
            readOnly: isReadOnly ||
                onTap != null,
            onTap: onTap,
            keyboardType: keyboardType,
            inputFormatters: formatter != null ? [formatter] : [],
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
            decoration: InputDecoration(
              filled: true,
              fillColor: isReadOnly
                  ? theme.colorScheme.surfaceContainerHighest
                  : theme.colorScheme.surfaceContainerHighest,
              prefixIcon: Icon(
                icon,
                color:
                    theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: isReadOnly
                  ? null
                  : OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: theme.colorScheme.primary, width: 1.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _dateFormat.tryParse(_birthdayController.text) ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('ru', 'RU'),
    );
    if (picked != null) {
      setState(() {
        _birthdayController.text = _dateFormat.format(picked);
      });
    }
  }
}

class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.read<ThemeBloc>().add(ToggleThemeEvent()),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  key: ValueKey(isDark),
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Тема оформления',
                        style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.w600)),
                    Text(
                      isDark ? 'Тёмная' : 'Светлая',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDark,
                onChanged: (_) =>
                    context.read<ThemeBloc>().add(ToggleThemeEvent()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
