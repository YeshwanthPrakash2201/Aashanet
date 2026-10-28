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
import 'package:mobile/infrastructure/database/app_database.dart';
import 'package:mobile/domain/repositories/health_record_local_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AashaNetApp());
}

// ============================================================
// CONFIGURATION
// ============================================================

const String baseUrl = 'http://192.168.113.74:8000';

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
        'SESSION VALIDATION UNEXPECTED RESPONSE: '
        '${response.body}',
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

class HomeScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AASHANet AI',
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              l10n.welcome,
              style:
                  const TextStyle(
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              fullName,
              style:
                  const TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              '${l10n.role}: $role',
              style:
                  const TextStyle(
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width:
                  double.infinity,
              height: 60,
              child:
                  ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              RecordScreen(
                        accessToken:
                            accessToken,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.note_add,
                ),
                label: Text(
                  l10n.record,
                  style:
                      const TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width:
                  double.infinity,
              height: 60,
              child:
                  ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              const LocalRecordsScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.folder_open,
                ),
                label: Text(
                  l10n.dataShowing,
                  style:
                      const TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width:
                  double.infinity,
              height: 60,
              child:
                  ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) =>
                              RecordScreen(
                        accessToken:
                            accessToken,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.keyboard,
                ),
                label: Text(
                  l10n.typingOption,
                  style:
                      const TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width:
                  double.infinity,
              height: 60,
              child:
                  ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger
                          .of(context)
                      .showSnackBar(
                    SnackBar(
                      content: Text(
                        'Tasks feature coming next',
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.task_alt,
                ),
                label: Text(
                  l10n.tasks,
                  style:
                      const TextStyle(
                    fontSize: 17,
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
  final AudioRecorder _audioRecorder =
      AudioRecorder();

  final TextEditingController
      rawRecordController =
      TextEditingController();

  bool _isRecording = false;

  String? _audioPath;

  bool isProcessing = false;

  final AppDatabase _database =
      AppDatabase();

  late final HealthRecordLocalRepository
      _localRepository;

  @override
  void initState() {
    super.initState();

    _localRepository =
        HealthRecordLocalRepository(
      _database,
    );
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    rawRecordController.dispose();
    _database.close();

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
            const SnackBar(
              content: Text(
                'Voice recording saved',
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
          const SnackBar(
            content: Text(
              'Microphone permission is required',
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
        const SnackBar(
          content: Text(
            'Recording started',
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
            'Could not record voice: $e',
          ),
        ),
      );
    }
  }

  Future<void> processRecord() async {
    final rawText =
        rawRecordController.text.trim();

    if (rawText.isEmpty &&
        _audioPath == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter or record the health information',
          ),
        ),
      );

      return;
    }

    setState(() {
      isProcessing = true;
    });

    final serverRawInput =
        rawText.isEmpty
            ? '[Voice recording]'
            : rawText;

    final inputLanguage =
        rawText.isEmpty
            ? 'Kannada'
            : 'en';

    final localRecordId =
        'local-${DateTime.now().millisecondsSinceEpoch}';

    try {
      await _localRepository
          .saveHealthRecord(
        id: localRecordId,
        workerId: null,
        rawInput: serverRawInput,
        inputLanguage:
            inputLanguage,
        audioPath: _audioPath,
      );

      debugPrint(
        'LOCAL DATABASE: '
        'Health record saved successfully',
      );

      debugPrint(
        'LOCAL RECORD ID: '
        '$localRecordId',
      );
    } catch (e) {
      debugPrint(
        'LOCAL SAVE ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not save record locally: $e',
          ),
        ),
      );

      return;
    }

    try {
      final createResponse =
          await http.post(
        Uri.parse(
          '$baseUrl/health-records',
        ),
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer ${widget.accessToken}',
        },
        body: jsonEncode({
          'raw_input':
              serverRawInput,
          'input_language':
              inputLanguage,
        }),
      );

      debugPrint(
        'CREATE STATUS: '
        '${createResponse.statusCode}',
      );

      debugPrint(
        'CREATE RESPONSE: '
        '${createResponse.body}',
      );

      if (createResponse.statusCode !=
              200 &&
          createResponse.statusCode !=
              201) {
        throw Exception(
          'Failed to create health record: '
          '${createResponse.body}',
        );
      }

      final createdData =
          jsonDecode(
        createResponse.body,
      );

      final recordId =
          createdData['id'];

      if (recordId == null) {
        throw Exception(
          'Backend did not return record ID',
        );
      }

      final workerId =
          createdData['worker_id'];

      if (workerId == null) {
        throw Exception(
          'Backend did not return worker ID',
        );
      }

      await _localRepository
          .linkServerRecord(
        localRecordId:
            localRecordId,
        serverRecordId:
            recordId.toString(),
        workerId:
            workerId.toString(),
      );

      late Map<String, dynamic>
          processedData;

      if (_audioPath != null) {
        final request =
            http.MultipartRequest(
          'POST',
          Uri.parse(
            '$baseUrl/health-records/'
            '$recordId/process-audio',
          ),
        );

        request.headers[
                'Authorization'] =
            'Bearer ${widget.accessToken}';

        request.fields[
                'language'] =
            'Kannada';

        request.files.add(
          await http.MultipartFile
              .fromPath(
            'audio',
            _audioPath!,
          ),
        );

        final streamedResponse =
            await request.send();

        final response =
            await http.Response
                .fromStream(
          streamedResponse,
        );

        debugPrint(
          'AUDIO PROCESS STATUS: '
          '${response.statusCode}',
        );

        debugPrint(
          'AUDIO PROCESS RESPONSE: '
          '${response.body}',
        );

        if (response.statusCode !=
            200) {
          throw Exception(
            'Failed to process audio: '
            '${response.body}',
          );
        }

        processedData =
            jsonDecode(
          response.body,
        );
      } else {
        final processResponse =
            await http.post(
          Uri.parse(
            '$baseUrl/health-records/'
            '$recordId/process',
          ),
          headers: {
            'Content-Type':
                'application/json',
            'Authorization':
                'Bearer ${widget.accessToken}',
          },
        );

        debugPrint(
          'PROCESS STATUS: '
          '${processResponse.statusCode}',
        );

        debugPrint(
          'PROCESS RESPONSE: '
          '${processResponse.body}',
        );

        if (processResponse.statusCode !=
            200) {
          throw Exception(
            'Failed to process health record: '
            '${processResponse.body}',
          );
        }

        processedData =
            jsonDecode(
          processResponse.body,
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isProcessing = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              ReviewRecordScreen(
            accessToken:
                widget.accessToken,
            recordData:
                processedData,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'BACKEND PROCESSING ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Record saved locally. '
            'It will be processed when the connection is available.',
          ),
          duration:
              Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Record Health Visit',
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
              'Capture Health Information',
              style: TextStyle(
                fontSize: 23,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the information naturally. '
              'AASHANet AI will analyze it '
              'and structure the record.',
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
                          ? 'Tap to Stop Recording'
                          : 'Tap to Record Voice',
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
                      const Text(
                        'Recording...',
                      ),
                    ],
                    if (!_isRecording &&
                        _audioPath !=
                            null) ...[
                      const SizedBox(
                        height: 4,
                      ),
                      const Text(
                        'Recording saved',
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('OR'),
            ),
            const SizedBox(height: 20),
            TextField(
              controller:
                  rawRecordController,
              maxLines: 8,
              decoration:
                  InputDecoration(
                labelText:
                    'Enter record by typing',
                hintText:
                    'Example: Ramesh is 42 years old '
                    'and has cough and fever for three days',
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
                      ? 'Analyzing Record...'
                      : 'Process Record',
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
    required this.accessToken,
    required this.recordData,
  });

  final String accessToken;
  final Map<String, dynamic>
      recordData;

  @override
  State<ReviewRecordScreen>
      createState() =>
          _ReviewRecordScreenState();
}

class _ReviewRecordScreenState
    extends State<ReviewRecordScreen> {
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

  Future<void> confirmRecord() async {
    final recordId =
        widget.recordData['id'];

    if (recordId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Record ID is missing',
          ),
        ),
      );

      return;
    }

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

    try {
      final response =
          await http.post(
        Uri.parse(
          '$baseUrl/health-records/'
          '$recordId/confirm',
        ),
        headers: {
          'Content-Type':
              'application/json',
          'Authorization':
              'Bearer ${widget.accessToken}',
        },
        body: jsonEncode({
          'patient_name':
              patientName,
          'age': age,
          'symptoms': symptoms,
          'duration':
              duration.isEmpty
                  ? null
                  : duration,
        }),
      );

      debugPrint(
        'CONFIRM STATUS: '
        '${response.statusCode}',
      );

      debugPrint(
        'CONFIRM RESPONSE: '
        '${response.body}',
      );

      if (response.statusCode !=
          200) {
        throw Exception(
          'Failed to confirm record: '
          '${response.body}',
        );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                ),
                SizedBox(width: 10),
                Text(
                  'Record Confirmed',
                ),
              ],
            ),
            content: const Text(
              'The health record has been '
              'reviewed and successfully '
              'confirmed.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                  );
                },
                child:
                    const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) {
        return;
      }

      Navigator.popUntil(
        context,
        (route) => route.isFirst,
      );
    } catch (e) {
      debugPrint(
        'CONFIRM RECORD ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Could not save record: $e',
          ),
        ),
      );
    }
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
        title: const Text(
          'Review AI Analysis',
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

// ============================================================
// LOCAL RECORDS SCREEN
// ============================================================

class LocalRecordsScreen
    extends StatefulWidget {
  const LocalRecordsScreen({
    super.key,
  });

  @override
  State<LocalRecordsScreen>
      createState() =>
          _LocalRecordsScreenState();
}

class _LocalRecordsScreenState
    extends State<LocalRecordsScreen> {
  final AppDatabase _database =
      AppDatabase();

  late final HealthRecordLocalRepository
      _repository;

  @override
  void initState() {
    super.initState();

    _repository =
        HealthRecordLocalRepository(
      _database,
    );
  }

  @override
  void dispose() {
    _database.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Local Health Records',
        ),
      ),
      body: FutureBuilder(
        future:
            _repository.getAllRecords(),
        builder:
            (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Could not load records:\n'
                '${snapshot.error}',
                textAlign:
                    TextAlign.center,
              ),
            );
          }

          final records =
              snapshot.data ?? [];

          if (records.isEmpty) {
            return const Center(
              child: Text(
                'No local health records yet.',
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(16),
            itemCount:
                records.length,
            itemBuilder:
                (context, index) {
              final record =
                  records[index];

              return Card(
                margin:
                    const EdgeInsets.only(
                  bottom: 12,
                ),
                child: ListTile(
                  leading:
                      const CircleAvatar(
                    child: Icon(
                      Icons
                          .medical_information,
                    ),
                  ),
                  title: Text(
                    record.rawInput,
                    maxLines: 2,
                    overflow:
                        TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Worker: '
                    '${record.workerId ?? 'Not assigned yet'}\n'
                    'Status: '
                    '${record.syncStatus}',
                  ),
                  isThreeLine: true,
                ),
              );
            },
          );
        },
      ),
    );
  }
}