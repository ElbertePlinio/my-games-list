import 'dart:js_interop';
import 'dart:ui';

import 'package:web/web.dart' as web;
import 'package:picklog/features/settings/services/account_export_saver.dart';

AccountExportSaver createAccountExportSaver() => _WebAccountExportSaver();

class _WebAccountExportSaver implements AccountExportSaver {
  @override
  Future<void> save({
    required String fileName,
    required String json,
    Rect? sharePositionOrigin,
  }) async {
    final blob = web.Blob(
      [json.toJS].toJS,
      web.BlobPropertyBag(type: 'application/json'),
    );
    final url = web.URL.createObjectURL(blob);

    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = fileName;
    anchor.click();

    web.URL.revokeObjectURL(url);
  }
}
