import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Adds the Inter font license (SIL OFL 1.1) to the app's licenses page.
/// The file is only read when that page is opened.
void registerDesignSystemLicenses() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString(
      'packages/design_system/fonts/OFL.txt',
    );
    yield LicenseEntryWithLineBreaks(const ['Inter font'], license);
  });
}
