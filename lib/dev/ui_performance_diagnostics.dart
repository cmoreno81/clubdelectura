import 'package:flutter/widgets.dart';

/// Enables rebuild timeline events only in debug builds and only when requested.
///
/// Run with `--dart-define=CLUBREADS_PROFILE_REBUILDS=true` and inspect the
/// resulting build events in DevTools. Production and profile builds are not
/// affected because the configuration lives inside an assertion.
void configureUiPerformanceDiagnostics() {
  assert(() {
    if (const bool.fromEnvironment('CLUBREADS_PROFILE_REBUILDS')) {
      debugProfileBuildsEnabled = true;
      debugPrint('ClubReads: rebuild profiling enabled');
    }
    if (const bool.fromEnvironment('CLUBREADS_PRINT_REBUILDS')) {
      debugPrintRebuildDirtyWidgets = true;
    }
    return true;
  }());
}
