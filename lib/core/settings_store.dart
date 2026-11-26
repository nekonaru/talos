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
    this.downloadFolderSAF = '',
    this.filenameTemplate = '%(title)s.%(ext)s',
    this.defaultMaxHeight = 720,
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
    this.restrictFilenames = false,
    this.downloadArchive = false,
    this.cropArtwork = false,
    this.subtitleFormat = '',
    this.clipStartSeconds,
    this.clipEndSeconds,
    this.forceIpv4 = false,
    this.remuxContainer = '',
    this.maxFilesize = '',
    this.userAgent = '',
    this.formatSort = '',
    this.autoUpdateEngine = false,
    this.videoFolder,
    this.audioFolder,
    this.engineChannel = 'stable',
    this.autoRetryAttempts = 1,
    this.downloadNotification = true,
    this.downloadSubtitles = true,
    this.autoSubtitle = false,
    this.keepSubtitles = false,
    this.customCommandDirectory,
    this.historyRetentionDays = 0,
    this.wifiOnly = false,
    this.customHeaders = '',
    this.queuePaused = false,
    this.quietHoursEnabled = false,
    this.quietStartHour = 22,
    this.quietEndHour = 6,
    this.batterySaverEnabled = false,
    this.batteryThreshold = 20,
    this.folderRules = '',
    this.retryBackoff = 'linear',
    this.stallTimeoutMinutes = 0,
    this.autoOpen = false,
    this.autoShare = false,
    this.autoFavorite = false,
    this.autoCleanTemp = false,
    this.lastSeenVersion = '',
    this.chargingOnly = false,
  });

  factory TalosSettings.fromJson(Map<String, dynamic> json) {
    // Persisted values may come from an older build or a hand-edited file.
    // Normalize fixed-choice fields so a stale value can never crash a
    // DropdownButton with "value not in items".
    String choice(String? value, List<String> allowed, String fallback) =>
        value != null && allowed.contains(value) ? value : fallback;
    int intChoice(int? value, List<int> allowed, int fallback) =>
        value != null && allowed.contains(value) ? value : fallback;
    return TalosSettings(
      themeMode: choice(json['themeMode'] as String?, const ['system', 'light', 'dark'], 'system'),
      accent: json['accent'] as String? ?? 'bronze',
      downloadFolder: json['downloadFolder'] as String?,
      downloadFolderSAF: json['downloadFolderSAF'] as String? ?? '',
      filenameTemplate: json['filenameTemplate'] as String? ?? '%(title)s.%(ext)s',
      defaultMaxHeight: intChoice((json['defaultMaxHeight'] as num?)?.toInt(), const [0, 2160, 1440, 1080, 720, 480, 360], 720),
      defaultAudioFormat: choice(json['defaultAudioFormat'] as String?, const ['mp3', 'm4a', 'opus', 'flac', 'best'], 'mp3'),
      defaultAudioBitrate: choice(json['defaultAudioBitrate'] as String?, const ['128', '192', '256', '320'], '192'),
      proxy: json['proxy'] as String? ?? '',
      rateLimit: json['rateLimit'] as String? ?? '',
      useAria2: json['useAria2'] as bool? ?? false,
      concurrentFragments: intChoice((json['concurrentFragments'] as num?)?.toInt(), const [1, 2, 4, 8, 16], 4),
      embedSubtitles: json['embedSubtitles'] as bool? ?? true,
      embedMetadata: json['embedMetadata'] as bool? ?? true,
      ffmpegPath: json['ffmpegPath'] as String? ?? '',
      sponsorBlockEnabled: json['sponsorBlockEnabled'] as bool? ?? false,
      sponsorBlockCategories: json['sponsorBlockCategories'] as String? ?? 'sponsor',
      cookiesPath: json['cookiesPath'] as String? ?? '',
      subtitleLanguage: json['subtitleLanguage'] as String? ?? 'en',
      privateMode: json['privateMode'] as bool? ?? false,
      restrictFilenames: json['restrictFilenames'] as bool? ?? false,
      downloadArchive: json['downloadArchive'] as bool? ?? false,
      cropArtwork: json['cropArtwork'] as bool? ?? false,
      subtitleFormat: json['subtitleFormat'] as String? ?? '',
      clipStartSeconds: (json['clipStartSeconds'] as num?)?.toInt(),
      clipEndSeconds: (json['clipEndSeconds'] as num?)?.toInt(),
      forceIpv4: json['forceIpv4'] as bool? ?? false,
      remuxContainer: choice(json['remuxContainer'] as String?, const ['', 'mp4', 'mkv', 'webm'], ''),
      maxFilesize: json['maxFilesize'] as String? ?? '',
      userAgent: json['userAgent'] as String? ?? '',
      formatSort: json['formatSort'] as String? ?? '',
      videoFolder: json['videoFolder'] as String?,
      audioFolder: json['audioFolder'] as String?,
      autoUpdateEngine: json['autoUpdateEngine'] as bool? ?? false,
      engineChannel: choice(json['engineChannel'] as String?, const ['stable', 'nightly'], 'stable'),
      autoRetryAttempts: intChoice((json['autoRetryAttempts'] as num?)?.toInt(), const [0, 1, 2, 3], 1),
      downloadNotification: json['downloadNotification'] as bool? ?? true,
      downloadSubtitles: json['downloadSubtitles'] as bool? ?? true,
      autoSubtitle: json['autoSubtitle'] as bool? ?? false,
      keepSubtitles: json['keepSubtitles'] as bool? ?? false,
      customCommandDirectory: json['customCommandDirectory'] as String?,
      historyRetentionDays: intChoice((json['historyRetentionDays'] as num?)?.toInt(), const [0, 7, 30, 90], 0),
      wifiOnly: json['wifiOnly'] as bool? ?? false,
      customHeaders: json['customHeaders'] as String? ?? '',
      queuePaused: json['queuePaused'] as bool? ?? false,
      quietHoursEnabled: json['quietHoursEnabled'] as bool? ?? false,
      quietStartHour: intChoice((json['quietStartHour'] as num?)?.toInt(), List<int>.generate(24, (i) => i), 22),
      quietEndHour: intChoice((json['quietEndHour'] as num?)?.toInt(), List<int>.generate(24, (i) => i), 6),
      batterySaverEnabled: json['batterySaverEnabled'] as bool? ?? false,
      batteryThreshold: intChoice((json['batteryThreshold'] as num?)?.toInt(), const [5, 10, 20, 30], 20),
      folderRules: json['folderRules'] as String? ?? '',
      retryBackoff: choice(json['retryBackoff'] as String?, const ['linear', 'exponential'], 'linear'),
      stallTimeoutMinutes: intChoice((json['stallTimeoutMinutes'] as num?)?.toInt(), const [0, 2, 5, 10, 30], 0),
      autoOpen: json['autoOpen'] as bool? ?? false,
      autoShare: json['autoShare'] as bool? ?? false,
      autoFavorite: json['autoFavorite'] as bool? ?? false,
      autoCleanTemp: json['autoCleanTemp'] as bool? ?? false,
      lastSeenVersion: json['lastSeenVersion'] as String? ?? '',
      chargingOnly: json['chargingOnly'] as bool? ?? false,
    );
  }

  String themeMode;
  String accent;
  String? downloadFolder;
  String downloadFolderSAF;
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
  bool restrictFilenames;
  bool downloadArchive;
  bool cropArtwork;
  String subtitleFormat;
  int? clipStartSeconds;
  int? clipEndSeconds;
  bool forceIpv4;
  String remuxContainer;
  String maxFilesize;
  String userAgent;
  String formatSort;
  String? videoFolder;
  String? audioFolder;
  bool autoUpdateEngine;
  String engineChannel;
  int autoRetryAttempts;
  bool downloadNotification;
  bool downloadSubtitles;
  bool autoSubtitle;
  bool keepSubtitles;
  String? customCommandDirectory;
  int historyRetentionDays;
  bool wifiOnly;
  String customHeaders;
  bool queuePaused;
  bool quietHoursEnabled;
  int quietStartHour;
  int quietEndHour;
  bool batterySaverEnabled;
  int batteryThreshold;
  String folderRules;
  String retryBackoff;
  int stallTimeoutMinutes;
  bool autoOpen;
  bool autoShare;
  bool autoFavorite;
  bool autoCleanTemp;
  String lastSeenVersion;
  bool chargingOnly;

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode,
        'accent': accent,
        'downloadFolder': downloadFolder,
        'downloadFolderSAF': downloadFolderSAF,
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
        'restrictFilenames': restrictFilenames,
        'downloadArchive': downloadArchive,
        'cropArtwork': cropArtwork,
        'subtitleFormat': subtitleFormat,
        'clipStartSeconds': clipStartSeconds,
        'clipEndSeconds': clipEndSeconds,
        'forceIpv4': forceIpv4,
        'remuxContainer': remuxContainer,
        'maxFilesize': maxFilesize,
        'userAgent': userAgent,
        'formatSort': formatSort,
        'videoFolder': videoFolder,
        'audioFolder': audioFolder,
        'autoUpdateEngine': autoUpdateEngine,
        'engineChannel': engineChannel,
        'autoRetryAttempts': autoRetryAttempts,
        'downloadNotification': downloadNotification,
        'downloadSubtitles': downloadSubtitles,
        'autoSubtitle': autoSubtitle,
        'keepSubtitles': keepSubtitles,
        'customCommandDirectory': customCommandDirectory,
        'historyRetentionDays': historyRetentionDays,
        'wifiOnly': wifiOnly,
        'customHeaders': customHeaders,
        'queuePaused': queuePaused,
        'quietHoursEnabled': quietHoursEnabled,
        'quietStartHour': quietStartHour,
        'quietEndHour': quietEndHour,
        'batterySaverEnabled': batterySaverEnabled,
        'batteryThreshold': batteryThreshold,
        'folderRules': folderRules,
        'retryBackoff': retryBackoff,
        'stallTimeoutMinutes': stallTimeoutMinutes,
        'autoOpen': autoOpen,
        'autoShare': autoShare,
        'autoFavorite': autoFavorite,
        'autoCleanTemp': autoCleanTemp,
        'lastSeenVersion': lastSeenVersion,
        'chargingOnly': chargingOnly,
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
    String? downloadFolderSAF,
    bool clearDownloadFolder = false,
    bool clearVideoFolder = false,
    bool clearAudioFolder = false,
    bool clearCustomCommandDirectory = false,
    bool clearClipRange = false,
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
    bool? restrictFilenames,
    bool? downloadArchive,
    bool? cropArtwork,
    String? subtitleFormat,
    int? clipStartSeconds,
    int? clipEndSeconds,
    bool? forceIpv4,
    String? remuxContainer,
    String? maxFilesize,
    String? userAgent,
    String? formatSort,
    String? videoFolder,
    String? audioFolder,
    bool? autoUpdateEngine,
    String? engineChannel,
    int? autoRetryAttempts,
    bool? downloadNotification,
    bool? downloadSubtitles,
    bool? autoSubtitle,
    bool? keepSubtitles,
    String? customCommandDirectory,
    int? historyRetentionDays,
    bool? wifiOnly,
    String? customHeaders,
    bool? queuePaused,
    bool? quietHoursEnabled,
    int? quietStartHour,
    int? quietEndHour,
    bool? batterySaverEnabled,
    int? batteryThreshold,
    String? folderRules,
    String? retryBackoff,
    int? stallTimeoutMinutes,
    bool? autoOpen,
    bool? autoShare,
    bool? autoFavorite,
    bool? autoCleanTemp,
    String? lastSeenVersion,
    bool? chargingOnly,
  }) {
    return TalosSettings(
      themeMode: themeMode ?? this.themeMode,
      accent: accent ?? this.accent,
      downloadFolder: clearDownloadFolder ? null : (downloadFolder ?? this.downloadFolder),
      downloadFolderSAF: downloadFolderSAF ?? this.downloadFolderSAF,
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
      restrictFilenames: restrictFilenames ?? this.restrictFilenames,
      downloadArchive: downloadArchive ?? this.downloadArchive,
      cropArtwork: cropArtwork ?? this.cropArtwork,
      subtitleFormat: subtitleFormat ?? this.subtitleFormat,
      clipStartSeconds: clearClipRange ? null : (clipStartSeconds ?? this.clipStartSeconds),
      clipEndSeconds: clearClipRange ? null : (clipEndSeconds ?? this.clipEndSeconds),
      forceIpv4: forceIpv4 ?? this.forceIpv4,
      remuxContainer: remuxContainer ?? this.remuxContainer,
      maxFilesize: maxFilesize ?? this.maxFilesize,
      userAgent: userAgent ?? this.userAgent,
      formatSort: formatSort ?? this.formatSort,
      videoFolder: clearVideoFolder ? null : (videoFolder ?? this.videoFolder),
      audioFolder: clearAudioFolder ? null : (audioFolder ?? this.audioFolder),
      autoUpdateEngine: autoUpdateEngine ?? this.autoUpdateEngine,
      engineChannel: engineChannel ?? this.engineChannel,
      autoRetryAttempts: autoRetryAttempts ?? this.autoRetryAttempts,
      downloadNotification: downloadNotification ?? this.downloadNotification,
      downloadSubtitles: downloadSubtitles ?? this.downloadSubtitles,
      autoSubtitle: autoSubtitle ?? this.autoSubtitle,
      keepSubtitles: keepSubtitles ?? this.keepSubtitles,
      customCommandDirectory: clearCustomCommandDirectory ? null : (customCommandDirectory ?? this.customCommandDirectory),
      historyRetentionDays: historyRetentionDays ?? this.historyRetentionDays,
      wifiOnly: wifiOnly ?? this.wifiOnly,
      customHeaders: customHeaders ?? this.customHeaders,
      queuePaused: queuePaused ?? this.queuePaused,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartHour: quietStartHour ?? this.quietStartHour,
      quietEndHour: quietEndHour ?? this.quietEndHour,
      batterySaverEnabled: batterySaverEnabled ?? this.batterySaverEnabled,
      batteryThreshold: batteryThreshold ?? this.batteryThreshold,
      folderRules: folderRules ?? this.folderRules,
      retryBackoff: retryBackoff ?? this.retryBackoff,
      stallTimeoutMinutes: stallTimeoutMinutes ?? this.stallTimeoutMinutes,
      autoOpen: autoOpen ?? this.autoOpen,
      autoShare: autoShare ?? this.autoShare,
      autoFavorite: autoFavorite ?? this.autoFavorite,
      autoCleanTemp: autoCleanTemp ?? this.autoCleanTemp,
      lastSeenVersion: lastSeenVersion ?? this.lastSeenVersion,
      chargingOnly: chargingOnly ?? this.chargingOnly,
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
      await writeFileAtomic(_file, const JsonEncoder.withIndent('  ').convert(_settings.toJson()));
      await restrictFileToOwner(_file);
    } catch (_) {
      // Persistence failures are non-fatal; the in-memory value still applies.
    }
  }
}
