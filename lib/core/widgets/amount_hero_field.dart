import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

class AmountHeroField extends StatelessWidget {
  const AmountHeroField({
    super.key,
    required this.controller,
    required this.validator,
    this.fieldKey,
    this.caption = 'AMOUNT · EGP',
    this.autofocus = true,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final Key? fieldKey;
  final String caption;
  final bool autofocus;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          TextFormField(
            key: fieldKey,
            controller: controller,
            autofocus: autofocus,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: inputFormatters,
            style: theme.textTheme.headlineLarge?.copyWith(fontSize: 40),
            cursorColor: AppTheme.primaryEmerald,
            decoration: InputDecoration(
              hintText: '0.00',
              hintStyle: theme.textTheme.headlineLarge?.copyWith(
                fontSize: 40,
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.35,
                ),
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }
}
