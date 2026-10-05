import 'dart:convert';
import 'dart:io';

/// The real opening template, the one `make deploy-opening` publishes to
/// Firestore. Tests use it so the published data is the tested data.
Map<String, Object?> openingTemplateJson() =>
    jsonDecode(
          File('../../../firebase/opening-template.json').readAsStringSync(),
        )
        as Map<String, Object?>;
