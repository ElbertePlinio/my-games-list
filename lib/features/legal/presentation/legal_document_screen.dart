import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:picklog/core/utils/l10n_extensions.dart';
import 'package:picklog/features/legal/legal_document.dart';

/// Renders a [LegalDocument] (Privacy Policy or Terms of Service) from a
/// locale-specific placeholder asset.
///
/// The long-form body is loaded from `assets/legal/*.md` via [rootBundle]
/// instead of being hard-coded, so the legal text stays trivially replaceable
/// (issue #26) and never becomes an inline `Text('...')` literal that the
/// hardcoded-string CI guard would flag. Only the localized title and the DRAFT
/// banner come through `context.l10n`.
class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});

  final LegalDocument document;

  String _title(BuildContext context) => switch (document) {
    LegalDocument.privacyPolicy => context.l10n.privacyPolicyTitle,
    LegalDocument.terms => context.l10n.termsTitle,
  };

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;

    return Scaffold(
      appBar: AppBar(title: Text(_title(context)), centerTitle: true),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: rootBundle.loadString(document.assetFor(languageCode)),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text(context.l10n.legalLoadError));
            }
            return _LegalDocumentBody(content: snapshot.data!);
          },
        ),
      ),
    );
  }
}

class _LegalDocumentBody extends StatelessWidget {
  const _LegalDocumentBody({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _DraftBanner(),
            const SizedBox(height: 16),
            ..._renderBlocks(theme),
          ],
        ),
      ),
    );
  }

  /// Lightweight renderer for the placeholder markdown: `#`/`##` lines become
  /// headings and everything else is body text. This is intentionally minimal —
  /// it avoids adding a markdown dependency for placeholder content. When the
  /// real documents land (issue #26) this can be revisited.
  List<Widget> _renderBlocks(ThemeData theme) {
    final lines = content.split('\n');
    final widgets = <Widget>[];

    for (final line in lines) {
      final trimmed = line.trimRight();
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 8));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Text(
              trimmed.substring(3),
              style: theme.textTheme.titleMedium,
            ),
          ),
        );
      } else if (trimmed.startsWith('# ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              trimmed.substring(2),
              style: theme.textTheme.headlineSmall,
            ),
          ),
        );
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: theme.textTheme.bodyMedium),
                Expanded(
                  child: Text(
                    trimmed.substring(2),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        widgets.add(Text(trimmed, style: theme.textTheme.bodyMedium));
      }
    }

    return widgets;
  }
}

/// Visible reminder that the rendered text is placeholder content.
class _DraftBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.legalDraftBanner,
              style: TextStyle(color: colors.onSecondaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
