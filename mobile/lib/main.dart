import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'l10n/app_localizations.dart';
import 'infrastructure/auth/session_storage.dart';
import 'infrastructure/settings/language_storage.dart';
import 'presentation/screens/language_selection_screen.dart';
import 'application/app_services.dart';
import 'config.dart';
import 'domain/record_status.dart';
import 'infrastructure/database/app_database.dart';
import 'presentation/review_data.dart';
import 'presentation/screens/local_records_screen.dart';
import 'presentation/widgets/sync_status_widgets.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AashaNetApp());
}

// ============================================================
// AASHANET APP
// ============================================================

class AashaNetApp extends StatefulWidget {
  const AashaNetApp({super.key});

  @override
  State<AashaNetApp> createState() => _AashaNetAppState();
}

class _AashaNetAppState extends State<AashaNetApp> {
  final LanguageStorage _languageStorage = LanguageStorage();

  Locale? _selectedLocale;
  bool _isLoadingLanguage = true;

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    final languageCode = await _languageStorage.getLanguage();

    if (!mounted) {
      return;
    }

    setState(() {
      if (languageCode != null) {
        _selectedLocale = Locale(languageCode);
      }

      _isLoadingLanguage = false;
    });
  }

  void _onLanguageSelected(Locale locale) {
    setState(() {
      _selectedLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLanguage) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AASHANet AI',
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AASHANet AI',

      // Selected app language.
      locale: _selectedLocale ?? const Locale('en'),

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en'),
        Locale('kn'),
        Locale('hi'),
      ],

      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),

      home: _selectedLocale == null
          ? LanguageSelectionScreen(
              onLanguageSelected: _onLanguageSelected,
            )
          : const StartupScreen(),
    );
  }
}

// ============================================================
// STARTUP SCREEN
// ============================================================

class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  Future<Widget> _checkSession() async {
    final accessToken = await SessionStorage.getAccessToken();
    final username = await SessionStorage.getUsername();
    final role = await SessionStorage.getRole();
    final fullName = await SessionStorage.getFullName();

    if (accessToken == null ||
        username == null ||
        role == null ||
        fullName == null) {
      return const LoginScreen();
    }

    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(
            const Duration(seconds: 5),
          );

      debugPrint(
        'SESSION VALIDATION STATUS: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        return HomeScreen(
          username: username,
          role: role,
          fullName: fullName,
          accessToken: accessToken,
        );
      }

      if (response.statusCode == 401) {
        debugPrint(
          'SAVED SESSION EXPIRED OR INVALID',
        );

        await SessionStorage.clearSession();

        return const LoginScreen();
      }

      debugPrint(
        'SESSION VALIDATION UNEXPECTED STATUS: '
        '${response.statusCode}',
      );

      return HomeScreen(
        username: username,
        role: role,
        fullName: fullName,
        accessToken: accessToken,
      );
    } catch (e) {
      debugPrint(
        'SESSION VALIDATION NETWORK ERROR: $e',
      );

      return HomeScreen(
        username: username,
        role: role,
        fullName: fullName,
        accessToken: accessToken,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _checkSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const LoginScreen();
        }

        return snapshot.data ??
            const LoginScreen();
      },
    );
  }
}

// ============================================================
// LOGIN SCREEN
// ============================================================

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() =>
      _LoginScreenState();
}

class _LoginScreenState
    extends State<LoginScreen> {
  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final username =
        usernameController.text.trim();

    final password =
        passwordController.text;

    final l10n =
        AppLocalizations.of(context)!;

    if (username.isEmpty ||
        password.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.enterUsernamePassword,
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          '$baseUrl/auth/login',
        ),
        headers: {
          'Content-Type':
              'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(response.body);

        final accessToken =
            data['access_token'];

        final loggedInUsername =
            data['username'];

        final role =
            data['role'];

        final fullName =
            data['full_name'];

        await SessionStorage.saveSession(
          accessToken: accessToken,
          username: username,
          role: role,
          fullName: fullName,
        );

        if (!mounted) {
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                HomeScreen(
              username:
                  loggedInUsername,
              role: role,
              fullName: fullName,
              accessToken:
                  accessToken,
            ),
          ),
        );
      } else {
        final data =
            jsonDecode(response.body);

        final errorMessage =
            data['detail'] ??
                l10n.loginFailed;

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              errorMessage.toString(),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'LOGIN CONNECTION ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.couldNotConnectServer,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration:
                      BoxDecoration(
                    color: Colors.teal,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: const Icon(
                    Icons.health_and_safety,
                    color: Colors.white,
                    size: 55,
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  'AASHANet AI',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  l10n.loginSubtitle,
                  textAlign:
                      TextAlign.center,
                ),

                const SizedBox(height: 40),

                TextField(
                  controller:
                      usernameController,
                  decoration:
                      InputDecoration(
                    labelText:
                        l10n.username,
                    hintText:
                        l10n.usernameHint,
                    prefixIcon:
                        const Icon(
                      Icons.person,
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                TextField(
                  controller:
                      passwordController,
                  obscureText:
                      obscurePassword,
                  decoration:
                      InputDecoration(
                    labelText:
                        l10n.password,
                    hintText:
                        l10n.passwordHint,
                    prefixIcon:
                        const Icon(
                      Icons.lock,
                    ),
                    suffixIcon:
                        IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons
                                .visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword =
                              !obscurePassword;
                        });
                      },
                    ),
                    border:
                        OutlineInputBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width:
                      double.infinity,
                  height: 52,
                  child:
                      ElevatedButton(
                    onPressed:
                        isLoading
                            ? null
                            : login,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child:
                                CircularProgressIndicator(),
                          )
                        : Text(
                            l10n.login,
                            style:
                                const TextStyle(
                              fontSize:
                                  17,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  l10n.loginSupportText,
                  textAlign:
                      TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.username,
    required this.role,
    required this.fullName,
    required this.accessToken,
  });

  final String username;
  final String role;
  final String fullName;
  final String accessToken;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with WidgetsBindingObserver {
  AppServices? _services;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startServices();
  }

  Future<void> _startServices() async {
    final services = await AppServices.startFor(widget.username);

    if (mounted) {
      setState(() {
        _services = services;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back to the app: re-check the connection and sync anything
  // saved while it was in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final services = _services;

    if (state == AppLifecycleState.resumed && services != null) {
      services.connectivity.checkNow().then((online) {
        if (online) {
          services.sync.syncAll();
        }
      });
    }
  }

  void _openRecordScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordScreen(
          accessToken: widget.accessToken,
        ),
      ),
    );
  }

  void _openReview(BuildContext context, HealthRecord record) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewRecordScreen(
          localRecordId: record.id,
          recordData: reviewDataFor(record),
        ),
      ),
    );
  }

  /// Ends the session. Local records are never deleted: they stay on
  /// the phone and sync after the same worker logs in again.
  Future<void> _logout({bool loginExpired = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final services = _services;

    if (!loginExpired && services != null) {
      final unsynced = await services.records
          .watchUnsyncedCount(services.username)
          .first;

      if (unsynced > 0 && mounted) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.logout),
            content: Text(l10n.logoutUnsyncedWarning(unsynced)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(l10n.logout),
              ),
            ],
          ),
        );

        if (proceed != true) {
          return;
        }
      }
    }

    AppServices.stop();
    await SessionStorage.clearSession();

    if (!mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  Widget _menuButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon),
          label: Text(
            label,
            style: const TextStyle(fontSize: 17),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final services = _services;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AASHANet AI'),
        centerTitle: true,
        actions: [
          if (services != null) ConnectionStatusBadge(services: services),
          IconButton(
            tooltip: l10n.logout,
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          if (services != null)
            LoginRequiredBanner(
              services: services,
              onLogInAgain: () => _logout(loginExpired: true),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcome,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.fullName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.role}: ${widget.role}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (services != null)
                    StreamBuilder<int>(
                      stream: services.records
                          .watchUnsyncedCount(services.username),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;

                        if (count == 0) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.cloud_upload_outlined,
                                size: 20,
                              ),
                              const SizedBox(width: 6),
                              Text(l10n.unsyncedCount(count)),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 30),
                  _menuButton(
                    icon: Icons.note_add,
                    label: l10n.record,
                    onPressed: services != null ? _openRecordScreen : null,
                  ),
                  _menuButton(
                    icon: Icons.folder_open,
                    label: l10n.dataShowing,
                    onPressed: services == null
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocalRecordsScreen(
                                  services: services,
                                  onReview: _openReview,
                                ),
                              ),
                            ),
                  ),
                  _menuButton(
                    icon: Icons.keyboard,
                    label: l10n.typingOption,
                    onPressed: services != null ? _openRecordScreen : null,
                  ),
                  _menuButton(
                    icon: Icons.task_alt,
                    label: l10n.tasks,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tasks feature coming next'),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// RECORD SCREEN
// ============================================================

class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    required this.accessToken,
  });

  final String accessToken;

  @override
  State<RecordScreen> createState() =>
      _RecordScreenState();
}

class _RecordScreenState
 extends State<RecordScreen> {
   AppLocalizations get l10n =>
        AppLocalizations.of(context)!;
  final AudioRecorder _audioRecorder =
      AudioRecorder();

  final TextEditingController
      rawRecordController =
      TextEditingController();

  bool _isRecording = false;

  String? _audioPath;

  bool isProcessing = false;

  @override
  void dispose() {
    _audioRecorder.dispose();
    rawRecordController.dispose();

    super.dispose();
  }

  Future<void> toggleRecording() async {
    try {
      if (_isRecording) {
        final path =
            await _audioRecorder.stop();

        if (!mounted) {
          return;
        }

        setState(() {
          _isRecording = false;
          _audioPath = path;
        });

        if (path != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content: Text(
                l10n.recordingSaved,
              ),
            ),
          );
        }

        return;
      }

      final hasPermission =
          await _audioRecorder
              .hasPermission();

      if (!hasPermission) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
            .showSnackBar(
           SnackBar(
            content: Text(
              l10n.microphonePermissionRequired,
            ),
          ),
        );

        return;
      }

      final directory =
          await getApplicationDocumentsDirectory();

      final audioPath =
          '${directory.path}/aashanet_recording_'
          '${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
        ),
        path: audioPath,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isRecording = true;
        _audioPath = null;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.recordingStarted,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'VOICE RECORDING ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isRecording = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.couldNotRecordVoice}: $e',
          ),
        ),
      );
    }
  }

  /// Saves the record on the phone first (works offline), then - if the
  /// server is reachable - uploads it and runs AI processing straight
  /// away. Offline, or if the AI does not finish, the record waits in
  /// the sync queue and is processed automatically later.
  Future<void> processRecord() async {
    final rawText = rawRecordController.text.trim();

    if (rawText.isEmpty && _audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.pleaseEnterOrRecordHealthInfo),
        ),
      );
      return;
    }

    final services = AppServices.current;
    final hasAudio = _audioPath != null;

    setState(() {
      isProcessing = true;
    });

    // 1. Save on the phone. This never needs the internet.
    final String localRecordId;

    try {
      localRecordId = await services.records.saveNewRecord(
        ownerUsername: services.username,
        rawInput: rawText.isEmpty ? '[Voice recording]' : rawText,
        inputLanguage: hasAudio ? 'Kannada' : 'en',
        audioPath: _audioPath,
      );
    } catch (e) {
      debugPrint('LOCAL SAVE ERROR: ${e.runtimeType}');

      if (!mounted) {
        return;
      }

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotSaveRecordLocally)),
      );
      return;
    }

    // 2. Online: upload and run AI now, so the worker can review at once.
    HealthRecord? record;

    if (await services.connectivity.checkNow()) {
      record = await services.sync.syncRecord(localRecordId);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isProcessing = false;
    });

    final aiFinished = record != null &&
        record.serverRecordId != null &&
        (record.aiStatus == AiStatus.completed ||
            record.aiStatus == AiStatus.failed);

    if (aiFinished) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ReviewRecordScreen(
            localRecordId: localRecordId,
            recordData: reviewDataFor(record!),
          ),
        ),
      );
      return;
    }

    // 3. Saved, but AI has not run yet. Tell the worker honestly.
    final String message;

    if (record?.lastSyncError == SyncError.loginRequired) {
      message = l10n.loginToSync;
    } else if (record == null || record.lastSyncError == SyncError.network) {
      message = l10n.savedOfflineAiPending;
    } else {
      message = l10n.savedAiRetry;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.recordHealthVisit,
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              l10n.captureHealthInformation,
              style: const TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.captureHealthDescription,
            ),
            const SizedBox(height: 25),
            SizedBox(
              width:
                  double.infinity,
              height: 100,
              child:
                  OutlinedButton(
                onPressed:
                    isProcessing
                        ? null
                        : toggleRecording,
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,
                  children: [
                    Icon(
                      _isRecording
                          ? Icons
                              .stop_circle
                          : Icons.mic,
                      size: 40,
                    ),
                    const SizedBox(
                      height: 8,
                    ),
                    Text(
                      _isRecording
                          ? l10n.tapToStopRecording
                          : l10n.tapToRecordVoice,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight
                                .bold,
                      ),
                    ),
                    if (_isRecording) ...[
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        l10n.recording,
                      ),
                    ],
                    if (!_isRecording &&
                        _audioPath !=
                            null) ...[
                      const SizedBox(
                        height: 4,
                      ),
                     Text(
                        l10n.recordingSaved,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(l10n.orText),
            ),
            const SizedBox(height: 20),
            TextField(
              controller:
                  rawRecordController,
              maxLines: 8,
              decoration:
                  InputDecoration(
                labelText:
                    l10n.enterRecordByTyping,
                hintText:
                    l10n.recordExampleHint,
                alignLabelWithHint: true,
                prefixIcon:
                    const Padding(
                  padding:
                      EdgeInsets.only(
                    bottom: 110,
                  ),
                  child: Icon(
                    Icons.edit_note,
                  ),
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width:
                  double.infinity,
              height: 55,
              child:
                  ElevatedButton.icon(
                onPressed:
                    isProcessing
                        ? null
                        : processRecord,
                icon: isProcessing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(),
                      )
                    : const Icon(
                        Icons.auto_awesome,
                      ),
                label: Text(
                  isProcessing
                      ? l10n.analyzingRecord
                      : 	l10n.processRecord,
                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// REVIEW RECORD SCREEN
// ============================================================

class ReviewRecordScreen
    extends StatefulWidget {
  const ReviewRecordScreen({
    super.key,
    required this.localRecordId,
    required this.recordData,
  });

  // Local SQLite id of the record being reviewed.
  final String localRecordId;

  // AI suggestions and original input (see reviewDataFor).
  final Map<String, dynamic> recordData;

  @override
  State<ReviewRecordScreen>
      createState() =>
          _ReviewRecordScreenState();
}


  class _ReviewRecordScreenState
    extends State<ReviewRecordScreen> {
  AppLocalizations get l10n =>
      AppLocalizations.of(context)!;
  late TextEditingController
      patientNameController;

  late TextEditingController
      ageController;

  late TextEditingController
      symptomsController;

  late TextEditingController
      durationController;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    final suggestedData =
        (widget.recordData[
                    'ai_suggested_data']
                as Map<String, dynamic>?) ??
            (widget.recordData[
                    'analyzed']
                as Map<String, dynamic>?) ??
            {};

    patientNameController =
        TextEditingController(
      text: suggestedData[
                  'patient_name']
              ?.toString() ??
          '',
    );

    ageController =
        TextEditingController(
      text: suggestedData['age']
              ?.toString() ??
          '',
    );

    final symptoms =
        suggestedData['symptoms']
                as List<dynamic>? ??
            [];

    symptomsController =
        TextEditingController(
      text: symptoms.join(', '),
    );

    durationController =
        TextEditingController(
      text: suggestedData[
                  'duration']
              ?.toString() ??
          '',
    );
  }

  @override
  void dispose() {
    patientNameController.dispose();
    ageController.dispose();
    symptomsController.dispose();
    durationController.dispose();

    super.dispose();
  }

  /// Saves the worker's confirmed details on the phone first, then sends
  /// them to the server if it is reachable. Offline, the confirmation
  /// waits in the sync queue. Only what the worker confirmed here is
  /// stored as the record's details - never the raw AI suggestions.
  Future<void> confirmRecord() async {
    final patientName =
        patientNameController.text.trim();

    final ageText =
        ageController.text.trim();

    final symptomsText =
        symptomsController.text.trim();

    final duration =
        durationController.text.trim();

    if (patientName.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter beneficiary name',
          ),
        ),
      );

      return;
    }

    int? age;

    if (ageText.isNotEmpty) {
      age = int.tryParse(ageText);

      if (age == null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Age must be a valid number',
            ),
          ),
        );

        return;
      }
    }

    final symptoms =
        symptomsText.isEmpty
            ? <String>[]
            : symptomsText
                .split(',')
                .map(
                  (item) =>
                      item.trim(),
                )
                .where(
                  (item) =>
                      item.isNotEmpty,
                )
                .toList();

    setState(() {
      isSaving = true;
    });

    final services = AppServices.current;

    try {
      await services.records.saveConfirmation(
        id: widget.localRecordId,
        confirmedData: {
          'patient_name': patientName,
          'age': age,
          'symptoms': symptoms,
          'duration': duration.isEmpty ? null : duration,
        },
      );
    } catch (e) {
      debugPrint('LOCAL CONFIRM ERROR: ${e.runtimeType}');

      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotSaveRecordLocally)),
      );
      return;
    }

    HealthRecord? record;

    if (await services.connectivity.checkNow()) {
      record = await services.sync.syncRecord(widget.localRecordId);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      isSaving = false;
    });

    final conflict = record?.syncStatus == SyncStatus.conflict;
    final synced = record?.syncStatus == SyncStatus.synced;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(conflict ? Icons.warning_amber : Icons.check_circle),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  conflict ? l10n.conflictTitle : l10n.recordConfirmedTitle,
                ),
              ),
            ],
          ),
          content: Text(
            conflict
                ? l10n.conflictBody
                : synced
                    ? l10n.confirmedSynced
                    : l10n.confirmedOffline,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (!mounted) {
      return;
    }

    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final rawRecord =
        widget.recordData[
                    'transcript']
                ?.toString() ??
            widget.recordData[
                    'raw_input']
                ?.toString() ??
            '';

    final aiStatus =
        widget.recordData[
                    'ai_status']
                ?.toString() ??
            '';

    final recordStatus =
        widget.recordData[
                    'record_status']
                ?.toString() ??
            '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.reviewExtractedInformation,
        ),
      ),
      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            const Text(
              'AI Extracted Information',
              style: TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review and edit the information '
              'extracted by AASHANet AI before saving.',
            ),

            const SizedBox(height: 8),

            Text(
              l10n.aiNotVerifiedNotice,
              style: TextStyle(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'Original Record',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(15),
              decoration:
                  BoxDecoration(
                border:
                    Border.all(
                  color: Colors.grey,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Text(
                rawRecord,
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              'AI Suggested Data',
              style: TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller:
                  patientNameController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Beneficiary Name',
                prefixIcon:
                    Icon(Icons.person),
                border:
                    OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller:
                  ageController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                labelText: 'Age',
                prefixIcon:
                    Icon(
                  Icons.calendar_today,
                ),
                border:
                    OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller:
                  symptomsController,
              maxLines: 3,
              decoration:
                  const InputDecoration(
                labelText:
                    'Symptoms',
                hintText:
                    'Separate multiple symptoms with commas',
                prefixIcon:
                    Icon(
                  Icons.medical_information,
                ),
                border:
                    OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller:
                  durationController,
              decoration:
                  const InputDecoration(
                labelText:
                    'Duration',
                prefixIcon:
                    Icon(Icons.timer),
                border:
                    OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets.all(15),
              decoration:
                  BoxDecoration(
                color:
                    Colors.teal.withValues(
                  alpha: 0.1,
                ),
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: Text(
                      'AI status: $aiStatus\n'
                      'Record status: '
                      '$recordStatus\n\n'
                      'Please verify the information '
                      'before confirming the record.',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width:
                  double.infinity,
              height: 55,
              child:
                  ElevatedButton.icon(
                onPressed:
                    isSaving
                        ? null
                        : confirmRecord,
                icon: isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(),
                      )
                    : const Icon(
                        Icons.check_circle,
                      ),
                label: Text(
                  isSaving
                      ? 'Saving...'
                      : 'Confirm & Save',
                  style:
                      const TextStyle(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
