import 'dart:math' as math;

import 'package:flutter/widgets.dart';

double dialogBodyWidth(
  BuildContext context, {
  double max = 560,
  double margin = 48,
}) {
  final available = MediaQuery.sizeOf(context).width - margin;
  return math.min(max, available < 0 ? 0 : available);
}

double dialogBodyHeight(
  BuildContext context, {
  double max = 560,
  double factor = 0.8,
}) {
  return math.min(max, MediaQuery.sizeOf(context).height * factor);
}
