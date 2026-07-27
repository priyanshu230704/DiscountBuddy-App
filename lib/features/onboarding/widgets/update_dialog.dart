import 'package:flutter/material.dart';
import 'package:discount_buddy/features/onboarding/models/app_version_info.dart';
import 'package:discount_buddy/features/onboarding/widgets/optional_update_sheet.dart';

/// @deprecated Use [OptionalUpdateSheet] or [AppUpdatePage] instead.
class UpdateDialog {
  UpdateDialog._();

  static Future<void> show(BuildContext context, AppVersionInfo versionInfo) {
    return OptionalUpdateSheet.show(context, versionInfo);
  }
}
