// Publishes firebase/opening-template.json to Firestore (templates/opening):
// the accounts and first movements every new customer gets. Run it with
// `make deploy-opening` (or from apps/banking_app:
// `dart run tool/opening_template.dart`). `--project=<id>` picks another
// Firebase project, and `--dry-run` prints the request without sending it.
//
// It needs gcloud signed in with an account of the Firebase project
// (`gcloud auth login`): that IAM access is what may write the template,
// which the security rules keep read-only for the app.
import 'dart:convert';
import 'dart:io';

import 'package:accounts/opening_template.dart';

const _defaultProject = 'bi-digital-banking';
const _templateFile = '../../firebase/opening-template.json';

Future<void> main(List<String> args) async {
  final project = projectFrom(args);
  final json =
      jsonDecode(File(_templateFile).readAsStringSync())
          as Map<String, Object?>;
  // The app must be able to read it: fail here, not on a customer's phone.
  final template = OpeningTemplate.fromJson(json);
  final body = jsonEncode(firestoreDocument(json));
  if (args.contains('--dry-run')) {
    stdout.writeln(body);
    return;
  }

  final client = HttpClient();
  try {
    final request = await client.patchUrl(
      Uri.parse(
        'https://firestore.googleapis.com/v1/projects/$project'
        '/databases/(default)/documents/${OpeningTemplate.path}',
      ),
    );
    request.headers
      ..set(
        HttpHeaders.authorizationHeader,
        'Bearer ${await _accessToken(project)}',
      )
      ..set('X-Goog-User-Project', project)
      ..contentType = ContentType.json;
    request.write(body);
    final response = await request.close();
    final answer = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      stderr.writeln('Firestore answered ${response.statusCode}: $answer');
      exitCode = 1;
      return;
    }
    final movements = template.accounts.fold<int>(
      0,
      (total, account) => total + account.movements.length,
    );
    stdout.writeln(
      'Published ${OpeningTemplate.path} in $project: '
      '${template.accounts.length} '
      'accounts, $movements movements. New customers get it on their first '
      'sign-in; existing ones keep their data.',
    );
  } finally {
    client.close();
  }
}

/// The Firebase project to publish to: `--project=<id>`, or this repo's.
String projectFrom(List<String> args) {
  const flag = '--project=';
  for (final arg in args) {
    if (arg.startsWith(flag) && arg.length > flag.length) {
      return arg.substring(flag.length);
    }
  }
  return _defaultProject;
}

Future<String> _accessToken(String project) async {
  final result = await Process.run('gcloud', ['auth', 'print-access-token']);
  if (result.exitCode != 0) {
    throw StateError(
      'gcloud could not give an access token. Install gcloud and run '
      '`gcloud auth login` with an account of $project.\n${result.stderr}',
    );
  }
  return (result.stdout as String).trim();
}

/// A JSON object as a Firestore REST document (`{"fields": {...}}`).
Map<String, Object?> firestoreDocument(Map<String, Object?> json) => {
  'fields': {
    for (final MapEntry(:key, :value) in json.entries)
      key: firestoreValue(value),
  },
};

/// A JSON value in Firestore's REST format, where every value says its type.
Map<String, Object?> firestoreValue(Object? value) => switch (value) {
  null => {'nullValue': null},
  bool() => {'booleanValue': value},
  // 64-bit integers travel as text.
  int() => {'integerValue': '$value'},
  double() => {'doubleValue': value},
  String() => {'stringValue': value},
  List<Object?>() => {
    'arrayValue': {'values': value.map(firestoreValue).toList()},
  },
  Map<String, Object?>() => {'mapValue': firestoreDocument(value)},
  _ => throw ArgumentError.value(value, 'value', 'not a JSON value'),
};
