import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../domain/wallet_entity.dart';
import 'wallet_cubit.dart';
import 'wallet_icons.dart';

abstract final class _S {
  static const newWallet = 'New wallet';
  static const editWallet = 'Edit wallet';
  static const nameLabel = 'Wallet name';
  static const nameHint = 'e.g. Bank, On-Hand, Cash';
  static const nameRequired = 'Please enter a wallet name';
  static const iconLabel = 'Icon';
  static const create = 'Create wallet';
  static const save = 'Save changes';
  static const genericError = 'Could not save the wallet. Please try again.';
}

const int _maxNameLength = 40;

/// Name kept for existing callers; opens a bottom sheet instead of a dialog.
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
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
  late final TextEditingController _nameController = TextEditingController(
    text: widget.wallet?.name ?? '',
  );
  late String _selectedIconKey = WalletIcons.normalize(widget.wallet?.iconKey);

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
        ? await cubit.editWallet(
            id: existing.id,
            name: name,
            iconKey: _selectedIconKey,
          )
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
    final accent = WalletIcons.color(_selectedIconKey);

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
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      WalletIcons.icon(_selectedIconKey),
                      size: 28,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      _isEditing ? _S.editWallet : _S.newWallet,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: _maxNameLength,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: _S.nameLabel,
                  hintText: _S.nameHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? _S.nameRequired
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                _S.iconLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final key in WalletIcons.keys)
                    _IconOption(
                      iconKey: key,
                      selected: key == _selectedIconKey,
                      onTap: () => setState(() => _selectedIconKey = key),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                _ErrorNote(message: _error ?? ''),
              ],
              const SizedBox(height: 22),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
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

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: colors.onErrorContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.onErrorContainer,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ],
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
    final spec = WalletIcons.spec(iconKey);

    return Semantics(
      button: true,
      selected: selected,
      label: spec.label,
      onTap: onTap,
      excludeSemantics: true,
      child: Tooltip(
        message: spec.label,
        child: Material(
          color: selected ? spec.color : spec.color.withValues(alpha: 0.12),
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 54,
              height: 54,
              child: Icon(
                spec.icon,
                color: selected ? Colors.white : spec.color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
