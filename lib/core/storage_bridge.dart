import 'package:flutter/services.dart';

/// Async proxy to the native Storage Access Framework bridge, which lets
/// the user pick (or clear) a persisted writeable folder, for example the
/// public Downloads/Talos folder.
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
