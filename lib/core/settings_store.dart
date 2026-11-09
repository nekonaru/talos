import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'secure_file.dart';
import 'theme.dart';

/// Test-friendly shape for settings. Everything persists to one JSON file
/// in the application support directory.
class TalosSettings {
  TalosSettings({
    this.themeMode = 'system',
    this.accent = 'bronze',
    this.downloadFolder,
    this.filenameTemplate = '%(title)s.%(ext)s',
    this.defaultMaxHeight = 0,
    this.defaultAudioFormat = 'mp3',
    this.defaultAudioBitrate = '192',
    this.proxy = '',
    this.rateLimit = '',
    this.useAria2 = false,
    this.concurrentFragments = 4,
    this.embedSubtitles = true,
    this.embedMetadata = true,
    this.ffmpegPath = '',
    this.sponsorBlockEnabled = false,
    this.sponsorBlockCategories = 'sponsor',
    this.cookiesPath = '',
    this.subtitleLanguage = 'en',
    this.privateMode = false,
  });

  factory TalosSettings.fromJson(Map<String, dynamic> json) {
    return TalosSettings(
      themeMode: json['themeMode'] as String? ?? 'system',
      accent: json['accent'] as String? ?? 'bronze',
      downloadFolder: json['downloadFolder'] as String?,
      filenameTemplate: json['filenameTemplate'] as String? ?? '%(title)s.%(ext)s',
      defaultMaxHeight: (json['defaultMaxHeight'] as num?)?.toInt() ?? 0,
      defaultAudioFormat: json['defaultAudioFormat'] as String? ?? 'mp3',
      defaultAudioBitrate: json['defaultAudioBitrate'] as String? ?? '192',
      proxy: json['proxy'] as String? ?? '',
      rateLimit: json['rateLimit'] as String? ?? '',
      useAria2: json['useAria2'] as bool? ?? false,
      concurrentFragments: (json['concurrentFragments'] as num?)?.toInt() ?? 4,
      embedSubtitles: json['embedSubtitles'] as bool? ?? true,
      embedMetadata: json['embedMetadata'] as bool? ?? true,
      ffmpegPath: json['ffmpegPath'] as String? ?? '',
      sponsorBlockEnabled: json['sponsorBlockEnabled'] as bool? ?? false,
      sponsorBlockCategories: json['sponsorBlockCategories'] as String? ?? 'sponsor',
      cookiesPath: json['cookiesPath'] as String? ?? '',
      subtitleLanguage: json['subtitleLanguage'] as String? ?? 'en',
      privateMode: json['privateMode'] as bool? ?? false,
    );
  }

  String themeMode;
  String accent;
  String? downloadFolder;
  String filenameTemplate;
  int defaultMaxHeight;
  String defaultAudioFormat;
  String defaultAudioBitrate;
  String proxy;
  String rateLimit;
  bool useAria2;
  int concurrentFragments;
  bool embedSubtitles;
  bool embedMetadata;
  String ffmpegPath;
  bool sponsorBlockEnabled;
  String sponsorBlockCategories;
  String cookiesPath;
  String subtitleLanguage;
  bool privateMode;

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'accent': accent,
        'downloadFolder': downloadFolder,
        'filenameTemplate': filenameTemplate,
        'defaultMaxHeight': defaultMaxHeight,
        'defaultAudioFormat': defaultAudioFormat,
        'defaultAudioBitrate': defaultAudioBitrate,
        'proxy': proxy,
        'rateLimit': rateLimit,
        'useAria2': useAria2,
        'concurrentFragments': concurrentFragments,
        'embedSubtitles': embedSubtitles,
        'embedMetadata': embedMetadata,
        'ffmpegPath': ffmpegPath,
        'sponsorBlockEnabled': sponsorBlockEnabled,
        'sponsorBlockCategories': sponsorBlockCategories,
        'cookiesPath': cookiesPath,
        'subtitleLanguage': subtitleLanguage,
        'privateMode': privateMode,
      };

  ThemeMode get theme => switch (themeMode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  TalosAccent get accentValue => TalosAccent.values.firstWhere(
        (a) => a.name == accent,
        orElse: () => TalosAccent.bronze,
      );

  TalosSettings copyWith({
    String? themeMode,
    String? accent,
    String? downloadFolder,
    bool clearDownloadFolder = false,
    String? filenameTemplate,
    int? defaultMaxHeight,
    String? defaultAudioFormat,
    String? defaultAudioBitrate,
    String? proxy,
    String? rateLimit,
    bool? useAria2,
    int? concurrentFragments,
    bool? embedSubtitles,
    bool? embedMetadata,
    String? ffmpegPath,
    bool? sponsorBlockEnabled,
    String? sponsorBlockCategories,
    String? cookiesPath,
    String? subtitleLanguage,
    bool? privateMode,
  }) {
    return TalosSettings(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      downloadFolder: clearDownloadFolder ? null : (downloadFolder ?? this.downloadFolder),
      filenameTemplate: filenameTemplate ?? this.filenameTemplate,
      defaultMaxHeight: defaultMaxHeight ?? this.defaultMaxHeight,
      defaultAudioFormat: defaultAudioFormat ?? this.defaultAudioFormat,
      defaultAudioBitrate: defaultAudioBitrate ?? this.defaultAudioBitrate,
      proxy: proxy ?? this.proxy,
      rateLimit: rateLimit ?? this.rateLimit,
      useAria2: useAria2 ?? this.useAria2,
      concurrentFragments: concurrentFragments ?? this.concurrentFragments,
      embedSubtitles: embedSubtitles ?? this.embedSubtitles,
      embedMetadata: embedMetadata ?? this.embedMetadata,
      ffmpegPath: ffmpegPath ?? this.ffmpegPath,
      sponsorBlockEnabled: sponsorBlockEnabled ?? this.sponsorBlockEnabled,
      sponsorBlockCategories: sponsorBlockCategories ?? this.sponsorBlockCategories,
      cookiesPath: cookiesPath ?? this.cookiesPath,
      subtitleLanguage: subtitleLanguage ?? this.subtitleLanguage,
      privateMode: privateMode ?? this.privateMode,
    );
  }
}

class SettingsStore extends ChangeNotifier {
  SettingsStore._(this._settings, this._file);

  TalosSettings _settings;
  final File _file;

  TalosSettings get value => _settings;

  static Future<SettingsStore> load() async {
    final support = await getApplicationSupportDirectory();
    final file = File('${support.path}${Platform.pathSeparator}settings.json');
    TalosSettings settings = TalosSettings();
    try {
      if (await file.exists()) {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is Map<String, dynamic>) {
          settings = TalosSettings.fromJson(decoded);
        }
      }
    } catch (_) {
      // A corrupt settings file must never block app startup.
    }
    return SettingsStore._(settings, file);
  }

  Future<void> update(TalosSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _persist();
  }

  Future<void> mutate(TalosSettings Function(TalosSettings current) change) {
    return update(change(_settings));
  }

  Future<void> _persist() async {
    try {
      await _file.parent.create(recursive: true);
      await _file.writeAsString(const JsonEncoder.withIndent('  ').convert(_settings.toJson()));
      await restrictFileToOwner(_file);
    } catch (_) {
      // Persistence failures are non-fatal; the in-memory value still applies.
    }
  }
}
