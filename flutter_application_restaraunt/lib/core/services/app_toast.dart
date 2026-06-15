import 'package:flutter/material.dart';

import 'error_messages.dart';

enum AppToastType { success, error, info }

class AppToast {
  AppToast._();

  static OverlayEntry? _current;

  static void success(BuildContext context, String message) =>
      _show(context, message, AppToastType.success);

  static void error(BuildContext context, String message) =>
      _show(context, message, AppToastType.error);

  static void info(BuildContext context, String message) =>
      _show(context, message, AppToastType.info);

  static void fromError(BuildContext context, Object? error, {String? prefix}) {
    final msg = friendlyError(error);
    _show(context, prefix == null ? msg : '$prefix: $msg', AppToastType.error);
  }

  static void _show(
    BuildContext context,
    String message,
    AppToastType type, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _current?.remove();
    _current = null;

    final entry = OverlayEntry(
      builder: (ctx) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        onDismissed: () {
          _current?.remove();
          _current = null;
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final AppToastType type;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();

    Future.delayed(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (!mounted) return;
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  ({Color bg, Color fg, IconData icon}) _style(ThemeData theme) {
    final scheme = theme.colorScheme;
    switch (widget.type) {
      case AppToastType.success:
        return (bg: scheme.primary, fg: scheme.onPrimary, icon: Icons.check_circle_outline);
      case AppToastType.error:
        return (bg: scheme.error, fg: scheme.onError, icon: Icons.error_outline);
      case AppToastType.info:
        return (
          bg: scheme.surfaceContainerHighest,
          fg: scheme.onSurface,
          icon: Icons.info_outline,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final s = _style(theme);
    final maxWidth = media.size.width < 480 ? media.size.width - 32 : 420.0;

    return Positioned(
      top: media.padding.top + 16,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: _dismiss,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: s.bg,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(s.icon, color: s.fg, size: 22),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              widget.message,
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(color: s.fg),

                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
