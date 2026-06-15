import 'dart:async';
import 'package:flutter/material.dart';

class CountdownTimerWidget extends StatefulWidget {
  final DateTime blockUntil;
  final VoidCallback? onTimerEnd;

  const CountdownTimerWidget({super.key, required this.blockUntil, this.onTimerEnd});

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _timeLeft = widget.blockUntil.difference(DateTime.now());
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeLeft = widget.blockUntil.difference(DateTime.now());
        if (_timeLeft.isNegative) {
          _timer.cancel();
          if (widget.onTimerEnd != null) {
            Future.delayed(const Duration(seconds: 1), widget.onTimerEnd);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_timeLeft.isNegative) {
      return Text(
        'Можно попробовать снова.',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.green),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      'Повторная попытка через: ${_timeLeft.inMinutes.toString().padLeft(2, '0')}:${(_timeLeft.inSeconds % 60).toString().padLeft(2, '0')}',
      style: theme.textTheme.bodySmall?.copyWith(color: Colors.red),
      textAlign: TextAlign.center,
    );
  }
}