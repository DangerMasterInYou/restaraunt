import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_restaraunt/core/services/alert_dialog.dart';
import 'package:flutter_application_restaraunt/core/services/app_toast.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '/core/router/router.dart';
import '/features/users/client/favorites/favorites_screen.dart';
import 'promotions_sheet.dart';

const String kRestaurantPhone = '+7 (900) 390-72-05';
const String kRestaurantAddress = 'Ханты-Мансийск, ул. Калинина, 22';

void _copyPhone(BuildContext context) {
  Clipboard.setData(const ClipboardData(text: kRestaurantPhone));
  AppToast.info(context, 'Номер скопирован');
}

Widget _logo(BuildContext context) {
  final color = Theme.of(context).colorScheme.primary;
  return SvgPicture.asset(
    'assets/svg/logo.svg',
    fit: BoxFit.contain,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
}

PreferredSizeWidget buildNarrowAppBar(BuildContext context) {
  final theme = Theme.of(context);

  return AppBar(
    automaticallyImplyLeading: true,
    titleSpacing: 0,
    leading: Padding(
      padding: const EdgeInsets.all(10.0),
      child: _logo(context),
    ),
    title: Text('Донер-кебаб', style: theme.textTheme.titleMedium),
    actions: [
      IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.local_offer, size: 24),
        onPressed: () => showPromotionsSheet(context),
        tooltip: 'Акции',
      ),
      IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.bookmark_border, size: 24),
        onPressed: () => FavoritesScreen.open(context),
        tooltip: 'Избранное',
      ),
      IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.receipt_long, size: 24),
        onPressed: () => context.router.push(const OrdersRoute()),
        tooltip: 'Заказы',
      ),
      IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.person, size: 24),
        onPressed: () => context.router.push(const ProfileRoute()),
        tooltip: 'Профиль',
      ),
      IconButton(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        constraints: const BoxConstraints(),
        icon: const Icon(Icons.info_outline, size: 24),
        tooltip: 'Адрес и телефон',
        onPressed: () => showMyAlertDialog(
          context,
          title: 'Контактная информация',
          content: '$kRestaurantAddress\n $kRestaurantPhone',
        ),
      ),
      const SizedBox(width: 4),
    ],
  );
}

PreferredSizeWidget buildWideAppBar(BuildContext context) {
  final theme = Theme.of(context);

  return AppBar(
    automaticallyImplyLeading: false,
    centerTitle: false,
    titleSpacing: 0,
    leading: Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: SizedBox(height: 40, width: 40, child: _logo(context)),
    ),
    title: Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                foregroundColor: theme.colorScheme.onSurface,
              ),
              icon: Icon(Icons.location_city,
                  color: theme.colorScheme.primary, size: 24),
              label: Text(
                kRestaurantAddress,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
              onPressed: null,
            ),
          ),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => showPromotionsSheet(context),
        child: Text('Акции', style: theme.textTheme.titleLarge),
      ),
      const SizedBox(width: 20),
      TextButton.icon(
        onPressed: () => _copyPhone(context),
        icon: const Icon(Icons.copy, size: 16),
        label: Text(kRestaurantPhone, style: theme.textTheme.titleMedium),
      ),
      IconButton(
        icon: const Icon(Icons.bookmark_border),
        onPressed: () => FavoritesScreen.open(context),
        tooltip: 'Избранное',
      ),
      IconButton(
        icon: const Icon(Icons.receipt_long),
        onPressed: () => context.router.push(const OrdersRoute()),
        tooltip: 'Заказы',
      ),
      IconButton(
        icon: const Icon(Icons.person),
        onPressed: () => context.router.push(const ProfileRoute()),
        tooltip: 'Профиль',
      ),
      const SizedBox(width: 16),
    ],
  );
}
