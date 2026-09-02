import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/consent/bloc/consent_cubit.dart';
import 'package:picklog/features/consent/consent_category_l10n.dart';

/// First-run "Customize" sheet: a per-category switch list that returns the
/// chosen map to the caller on Save. It does not call the service directly so
/// nothing is collected until the user confirms.
class ConsentCustomizeSheet extends StatefulWidget {
  const ConsentCustomizeSheet({super.key});

  @override
  State<ConsentCustomizeSheet> createState() => _ConsentCustomizeSheetState();
}

class _ConsentCustomizeSheetState extends State<ConsentCustomizeSheet> {
  late final Map<ConsentCategory, bool> _choices;

  @override
  void initState() {
    super.initState();
    final state = context.read<ConsentCubit>().state;
    _choices = {
      for (final category in ConsentCategory.values)
        category: state.isGranted(category),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                context.l10n.consentCustomizeTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            for (final category in ConsentCategory.values)
              SwitchListTile(
                title: Text(category.localizedTitle(context)),
                subtitle: Text(category.localizedSubtitle(context)),
                value: _choices[category] ?? false,
                onChanged: (value) =>
                    setState(() => _choices[category] = value),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      // Returns null → no change, so the caller leaves consent
                      // untouched (an explicit dismissal for mouse/web users).
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(context.l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_choices),
                      child: Text(context.l10n.consentSave),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
