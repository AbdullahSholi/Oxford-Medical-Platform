import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endTime;
  final TextStyle? style;
  final VoidCallback? onFinished;

  const CountdownTimer({
    super.key,
    required this.endTime,
    this.style,
    this.onFinished,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.endTime.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _remaining = widget.endTime.difference(DateTime.now());
        if (_remaining.isNegative) {
          _timer.cancel();
          widget.onFinished?.call();
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
    if (_remaining.isNegative) {
      return const Text('Ended', style: TextStyle(color: AppColors.textHint));
    }

    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTimeBox('${hours.toString().padLeft(2, '0')}'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text(':', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.flashSale)),
        ),
        _buildTimeBox('${minutes.toString().padLeft(2, '0')}'),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 2),
          child: Text(':', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.flashSale)),
        ),
        _buildTimeBox('${seconds.toString().padLeft(2, '0')}'),
      ],
    );
  }

  Widget _buildTimeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.flashSale,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
