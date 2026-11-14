import 'dart:io';

import 'package:flutter/services.dart';

/// Async proxy to the native Storage Access Framework and download-folder
/// bridge. Talos can write downloads to the public Downloads/Talos folder
/// (the default), into a user-picked SAF tree, or into app-private storage.
class TalosStorageBridge {
  const TalosStorageBridge._();

  static const MethodChannel _channel = MethodChannel('id.nekonaru.talos/storage');

  /// Open the system folder picker and persist the URI grant. Returns the
  /// URI string, or null/empty when cancelled or on an unexpected platform.
  static Future<String?> pickDownloadsTree() async {
    try {
      final result = await _channel.invokeMethod<String>('pickTree');
      return (result != null && result.isNotEmpty) ? result : null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Read the currently persisted tree URI, if any. Empty string means unset.
  static Future<String?> treeUri() async {
    try {
      return await _channel.invokeMethod<String>('getTreeUri');
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Forget the persisted tree, so downloads fall back to app-private storage.
  static Future<bool> clearTree() async {
    try {
      await _channel.invokeMethod<void>('clearTree');
      return true;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Save a local file into the public Downloads/Talos folder. API 29+ uses a
  /// MediaStore insert and needs no permission; API 24-28 writes the path
  /// directly and needs WRITE_EXTERNAL_STORAGE. Returns the content or file
  /// URI of the saved document, or null on any failure.
  static Future<String?> saveToDownloads(String localPath, String displayName) async {
    try {
      final result = await _channel.invokeMethod<String>(
        'saveToDownloads',
        {'localPath': localPath, 'displayName': displayName},
      );
      return (result != null && result.isNotEmpty) ? result : null;
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Platform SDK integer (for example 29 or 33). Returns -1 off Android.
  static Future<int> androidSdkInt() async {
    if (!Platform.isAndroid) return -1;
    try {
      return await _channel.invokeMethod<int>('androidSdkInt') ?? -1;
    } on PlatformException {
      return -1;
    } on MissingPluginException {
      return -1;
    }
  }

  /// Ask once per install for the permissions Talos needs: POST_NOTIFICATIONS
  /// on API 33+, WRITE_EXTERNAL_STORAGE on API 24-28. Best effort.
  static Future<void> requestFirstLaunchPermissions() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<String>('requestFirstLaunchPermissions');
    } on PlatformException {
      // Best effort; downloads work either way.
    } on MissingPluginException {
      // Not an Android host.
    }
  }

  /// Open a content or file URI with the default app for its type. Returns
  /// true when an app took the intent.
  static Future<bool> openUri(String uri) async {
    try {
      return await _channel.invokeMethod<bool>('openUri', {'uri': uri}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Share a content or file URI through the Android share sheet. Returns
  /// true when the share sheet was shown.
  static Future<bool> shareUri(String uri) async {
    try {
      return await _channel.invokeMethod<bool>('shareUri', {'uri': uri}) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Copy a file into the persisted tree. Returns the new content URI or
  /// null on any failure.
  static Future<String?> copyToTree(String localPath, String displayName) async {
    try {
      return await _channel.invokeMethod<String>(
        'copyToTree',
        {'localPath': localPath, 'displayName': displayName},
      );
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  /// Delete a file by display name inside the persisted tree.
  static Future<bool> deleteInTree(String displayName) async {
    try {
      return await _channel.invokeMethod<bool>(
        'deleteInTree',
        {'displayName': displayName},
      ) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Delete a document by its content URI (no tree walk required).
  static Future<bool> deleteUri(String uriString) async {
    try {
      return await _channel.invokeMethod<bool>(
        'deleteUri',
        {'uri': uriString},
      ) ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
