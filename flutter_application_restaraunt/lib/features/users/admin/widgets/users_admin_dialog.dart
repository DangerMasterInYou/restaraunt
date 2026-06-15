import 'package:flutter/material.dart';

import '/core/utils/responsive.dart';
import 'package:get_it/get_it.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '/core/repositories/users/admin/admin_management.dart';
import '/core/services/app_toast.dart';

const _roles = ['client', 'operator', 'admin'];

const _mainAdminEmail = 'imoddinov@gmail.com';

class UsersAdminDialog extends StatefulWidget {
  const UsersAdminDialog({super.key});

  @override
  State<UsersAdminDialog> createState() => _UsersAdminDialogState();
}

class _UsersAdminDialogState extends State<UsersAdminDialog> {
  final _repo = GetIt.I<AbstractAdminUsersRepository>();
  late Future<List<AdminUserDTO>> _future;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = _repo.getUsers();
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) setState(_reload);
    } catch (e) {
      if (mounted) {
        AppToast.fromError(context, e);
      }
    }
  }

  Future<void> _openForm([AdminUserDTO? user]) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _UserFormDialog(user: user),
    );
    if (data == null) return;
    if (user == null) {
      await _guard(() => _repo.createUser(data));
    } else {
      await _guard(() => _repo.updateUser(user.id, data));
    }
  }

  Future<void> _confirmDelete(AdminUserDTO u) async {
    final hard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Удалить ${u.email}?'),
        content: const Text(
            'Мягко — деактивация (можно восстановить). Безвозвратно — удаление.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Мягко')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Безвозвратно'),
          ),
        ],
      ),
    );
    if (hard == null) return;
    await _guard(() => _repo.deleteUser(u.id, hard: hard));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Пользователи', style: theme.textTheme.titleMedium),
          IconButton(
            tooltip: 'Создать пользователя',
            icon: const Icon(Icons.person_add),
            onPressed: () => _openForm(),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogBodyWidth(context, max: 540),
        height: dialogBodyHeight(context, max: 460),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                isDense: true,
                prefixIcon: const Icon(Icons.search),
                hintText: 'Поиск по email/имени/телефону',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<AdminUserDTO>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Ошибка: ${snap.error}'));
                  }
                  final users = (snap.data ?? []).where((u) {
                    if (_search.isEmpty) return true;
                    return u.email.toLowerCase().contains(_search) ||
                        u.fullName.toLowerCase().contains(_search) ||
                        (u.phone ?? '').toLowerCase().contains(_search);
                  }).toList();
                  if (users.isEmpty) {
                    return const Center(child: Text('Нет пользователей'));
                  }
                  return ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, i) {
                      final u = users[i];
                      final isMainAdmin =
                          u.email.toLowerCase() == _mainAdminEmail;
                      return Card(
                        child: ListTile(
                          onTap: () => _openForm(u),
                          title:
                              Text(u.fullName.isEmpty ? u.email : u.fullName),
                          subtitle: Text(
                            '${u.email} · ${u.role}'
                            '${u.isActive ? '' : ' · заблокирован'}'
                            '${isMainAdmin ? ' · главный' : ''}',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: isMainAdmin

                              ? Icon(Icons.verified_user,
                                  color: theme.colorScheme.primary)
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      tooltip: u.isActive
                                          ? 'Заблокировать'
                                          : 'Восстановить',
                                      icon: Icon(u.isActive
                                          ? Icons.lock_open
                                          : Icons.restore),
                                      onPressed: () => _guard(() =>
                                          _repo.setActive(u.id, !u.isActive)),
                                    ),
                                    IconButton(
                                      tooltip: 'Удалить',
                                      icon: Icon(Icons.delete,
                                          color: theme.colorScheme.error),
                                      onPressed: () => _confirmDelete(u),
                                    ),
                                  ],
                                ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Закрыть'),
        ),
      ],
    );
  }
}

class _UserFormDialog extends StatefulWidget {
  const _UserFormDialog({this.user});
  final AdminUserDTO? user;

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  late final TextEditingController _email =
      TextEditingController(text: widget.user?.email ?? '');
  late final TextEditingController _firstName =
      TextEditingController(text: widget.user?.firstName ?? '');
  late final TextEditingController _lastName =
      TextEditingController(text: widget.user?.lastName ?? '');
  late final TextEditingController _phone = TextEditingController();
  late String _role = widget.user?.role ?? 'client';
  late bool _isActive = widget.user?.isActive ?? true;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '+7 (###) ###-##-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool get _isEdit => widget.user != null;

  @override
  void initState() {
    super.initState();
    final raw = widget.user?.phone ?? '';
    if (raw.isNotEmpty) {
      final digits = raw.replaceAll(RegExp(r'\D'), '');
      final local = (digits.length == 11 &&
              (digits.startsWith('7') || digits.startsWith('8')))
          ? digits.substring(1)
          : digits;
      _phone.value = _phoneFormatter.formatEditUpdate(
        const TextEditingValue(),
        TextEditingValue(text: local),
      );
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _submit() {

    if (_email.text.trim().isEmpty) {
      AppToast.error(context, 'Укажите email');
      return;
    }
    final data = <String, dynamic>{
      'email': _email.text.trim(),
      'first_name':
          _firstName.text.trim().isEmpty ? null : _firstName.text.trim(),
      'last_name': _lastName.text.trim().isEmpty ? null : _lastName.text.trim(),
      'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      'role': _role,
      'is_active': _isActive,
    };
    Navigator.of(context).pop(data);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(_isEdit ? 'Редактировать пользователя' : 'Новый пользователь'),
      content: SizedBox(
        width: dialogBodyWidth(context, max: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _email,
                decoration: const InputDecoration(
                  labelText: 'Email',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              TextField(
                controller: _firstName,
                decoration: const InputDecoration(labelText: 'Имя'),
              ),
              TextField(
                controller: _lastName,
                decoration: const InputDecoration(labelText: 'Фамилия'),
              ),
              TextField(
                controller: _phone,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+7 (999) 123-45-67',
                ),
                keyboardType: TextInputType.phone,

                inputFormatters: [_phoneFormatter],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _roles.contains(_role) ? _role : 'client',
                borderRadius: BorderRadius.circular(12),
                decoration: const InputDecoration(labelText: 'Роль'),
                items: _roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) => setState(() => _role = v ?? 'client'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Активен'),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
              if (_isEdit && widget.user?.createdAt != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Создан: ${widget.user!.createdAt}',
                      style: Theme.of(context).textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(_isEdit ? 'Сохранить' : 'Создать'),
        ),
      ],
    );
  }
}
