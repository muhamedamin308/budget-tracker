import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../domain/security_settings.dart';
import 'security_cubit.dart';

void showSecuritySettingsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => BlocProvider.value(
      value: context.read<SecurityCubit>(),
      child: const _SecuritySettingsSheet(),
    ),
  );
}

class _SecuritySettingsSheet extends StatelessWidget {
  const _SecuritySettingsSheet();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SecurityCubit, SecurityState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Biometrics & Security',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Protect your personal finances from unauthorized access when your phone is unlocked.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeTrackColor: AppTheme.primaryEmerald,
                title: const Text('Biometric Lock', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(state.canCheckBiometrics
                    ? 'Require Fingerprint, Face ID, or PIN'
                    : 'Not supported on this device'),
                value: state.isBiometricEnabled,
                onChanged: state.canCheckBiometrics
                    ? (val) => context.read<SecurityCubit>().setBiometricEnabled(val)
                    : null,
              ),
              if (state.isBiometricEnabled) ...[
                const Divider(height: 32),
                const Text(
                  'Auto-Lock Delay',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 8),
                RadioGroup<AutoLockTimeout>(
                  groupValue: state.timeout,
                  onChanged: (val) {
                    if (val != null) {
                      context.read<SecurityCubit>().setTimeout(val);
                    }
                  },
                  child: Column(
                    children: [
                      for (final timeout in AutoLockTimeout.values)
                        RadioListTile<AutoLockTimeout>(
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppTheme.primaryEmerald,
                          title: Text(timeout.label),
                          value: timeout,
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
