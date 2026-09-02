import 'package:flutter/material.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';

/// A destructive, type-to-confirm dialog for permanent account deletion.
/// Pops with `true` only when the user types the localized confirmation word.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _confirmed = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value, String confirmWord) {
    final matches = value.trim().toUpperCase() == confirmWord.toUpperCase();
    if (matches != _confirmed) {
      setState(() => _confirmed = matches);
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmWord = context.l10n.deleteAccountConfirmWord;
    final errorColor = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: Text(context.l10n.deleteAccountDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.l10n.deleteAccountDialogBody),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            textCapitalization: TextCapitalization.characters,
            onChanged: (value) => _onChanged(value, confirmWord),
            decoration: InputDecoration(
              labelText: context.l10n.deleteAccountConfirmLabel(confirmWord),
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: _confirmed ? () => Navigator.of(context).pop(true) : null,
          style: TextButton.styleFrom(foregroundColor: errorColor),
          child: Text(context.l10n.deleteAccountConfirmButton),
        ),
      ],
    );
  }
}
