import 'package:flutter/material.dart';

enum CartStep {
  items,
  address,
  payment,
}

class CartProgressIndicator extends StatelessWidget {
  final CartStep currentStep;

  const CartProgressIndicator({
    super.key,
    required this.currentStep,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
      child: Row(
        children: [
          _buildStepIndicator(
            context: context,
            step: CartStep.items,
            currentStep: currentStep,
            label: 'Корзина',
            isFirst: true,
          ),

          _buildConnectingLine(
            context: context,
            isActive: currentStep == CartStep.address || currentStep == CartStep.payment,
          ),

          _buildStepIndicator(
            context: context,
            step: CartStep.address,
            currentStep: currentStep,
            label: 'Комментарий',
          ),
          _buildConnectingLine(
            context: context,
            isActive: currentStep == CartStep.payment,
          ),
          _buildStepIndicator(
            context: context,
            step: CartStep.payment,
            currentStep: currentStep,
            label: 'Оплата',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator({
    required BuildContext context,
    required CartStep step,
    required CartStep currentStep,
    required String label,
    bool isFirst = false,
    bool isLast = false,
  }) {
    final theme = Theme.of(context);
    final isCompleted = step.index < currentStep.index;
    final isActive = step == currentStep || isCompleted;

    final activeBg = theme.colorScheme.primary;
    final activeFg = theme.colorScheme.onPrimary;
    final inactiveBg = theme.colorScheme.surfaceContainerHighest;
    final inactiveFg = theme.colorScheme.onSurface.withValues(alpha: 0.5);

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isActive ? activeBg : inactiveBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isCompleted
                  ? Icon(Icons.check, color: activeFg, size: 22)
                  : Text(
                      '${step.index + 1}',
                      style: TextStyle(
                        color: isActive ? activeFg : inactiveFg,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isActive
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectingLine({
    required BuildContext context,
    required bool isActive,
  }) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        height: 2,
        color: isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.2),
      ),
    );
  }
}