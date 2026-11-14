import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../domain/wallet_entity.dart';
import 'wallet_cubit.dart';

abstract final class _S {
  static const newWallet = 'New wallet';
  static const editWallet = 'Edit wallet';
  static const nameLabel = 'Wallet name';
  static const nameHint = 'e.g. Bank, On-Hand, Cash';
  static const nameRequired = 'Please enter a wallet name';
  static const iconLabel = 'Icon';
  static const create = 'Create';
  static const save = 'Save';
  static const genericError = 'Could not save the wallet. Please try again.';
}

const int _maxNameLength = 40;

const _availableIcons = [
  'wallet',
  'bank',
  'smartphone',
  'credit_card',
  'savings',
  'cash',
  'vault',
  'briefcase',
];

String _labelFor(String key) => key
    .split('_')
    .map((part) => part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
    .join(' ');

/// Name kept for existing callers; now opens a bottom sheet instead of a dialog.
Future<void> showWalletFormDialog(
    BuildContext context, {
      WalletEntity? wallet,
    }) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider.value(
      value: context.read<WalletCubit>(),
      child: _WalletFormSheet(wallet: wallet),
    ),
  );
}

class _WalletFormSheet extends StatefulWidget {
  const _WalletFormSheet({this.wallet});

  final WalletEntity? wallet;

  @override
  State<_WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends State<_WalletFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController =
  TextEditingController(text: widget.wallet?.name ?? '');
  late String _selectedIconKey = widget.wallet?.iconKey ?? _availableIcons.first;

  bool _submitting = false;
  String? _error;

  bool get _isEditing => widget.wallet != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<WalletCubit>();
    final name = _nameController.text.trim();
    final existing = widget.wallet;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final success = existing != null
        ? await cubit.editWallet(id: existing.id, name: name, iconKey: _selectedIconKey)
        : await cubit.createWallet(name: name, iconKey: _selectedIconKey);

    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _submitting = false;
      _error = cubit.state.errorMessage ?? _S.genericError;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEditing ? _S.editWallet : _S.newWallet,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: _maxNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: _S.nameLabel,
                  hintText: _S.nameHint,
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                (value == null || value.trim().isEmpty) ? _S.nameRequired : null,
              ),
              const SizedBox(height: 8),
              Text(
                _S.iconLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final iconKey in _availableIcons)
                    _IconOption(
                      iconKey: iconKey,
                      selected: iconKey == _selectedIconKey,
                      onTap: () => setState(() => _selectedIconKey = iconKey),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: _submitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Text(_isEditing ? _S.save : _S.create),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconOption extends StatelessWidget {
  const _IconOption({
    required this.iconKey,
    required this.selected,
    required this.onTap,
  });

  final String iconKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final label = _labelFor(iconKey);

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: Material(
          color: selected ? AppTheme.primaryEmerald : scheme.surfaceContainerHighest,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                CategoryIcons.getIcon(iconKey),
                color: selected ? Colors.white : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}