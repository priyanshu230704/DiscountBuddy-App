import 'package:flutter/material.dart';
import '../models/app_version_info.dart';
import 'optional_update_sheet.dart';

/// @deprecated Use [OptionalUpdateSheet] or [AppUpdatePage] instead.
class UpdateDialog {
  UpdateDialog._();

  static Future<void> show(BuildContext context, AppVersionInfo versionInfo) {
    return OptionalUpdateSheet.show(context, versionInfo);
  }
}
