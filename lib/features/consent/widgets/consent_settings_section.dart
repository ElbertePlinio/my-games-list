import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:picklog/core/services/consent/consent_category.dart';
import 'package:picklog/features/consent/bloc/consent_cubit.dart';
import 'package:picklog/features/consent/bloc/consent_state.dart';
import 'package:picklog/features/consent/consent_category_l10n.dart';

/// Per-category consent toggles for the Settings screen.
///
/// Each switch reflects the live [ConsentCubit] state and flips the matching
/// [ConsentService] category immediately, which enables/disables its collector.
class ConsentSettingsSection extends StatelessWidget {
  const ConsentSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    // No section header/subtitle of its own: this card sits directly under the
    // "Privacy & data" section so the two read as one privacy area rather than
    // two competing ones.
    return Card(
      child: BlocBuilder<ConsentCubit, ConsentState>(
        builder: (context, state) {
          const categories = ConsentCategory.values;
          return Column(
            children: [
              for (var i = 0; i < categories.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                SwitchListTile(
                  title: Text(categories[i].localizedTitle(context)),
                  subtitle: Text(categories[i].localizedSubtitle(context)),
                  value: state.isGranted(categories[i]),
                  onChanged: (value) => context
                      .read<ConsentCubit>()
                      .setCategory(categories[i], granted: value),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
