import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'infrastructure/auth/session_storage.dart';
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

class AashaNetApp extends StatelessWidget {
  const AashaNetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AASHANet AI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      home: const StartupScreen(),
    );
  }
}

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

    // Validate the saved JWT with the backend before opening Home.
    // AASHANet AI is offline-first, so a temporary network failure
    // must not force the user to log in again.
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/auth/me'),
            headers: {
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 5));

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
        debugPrint('SAVED SESSION EXPIRED OR INVALID');
        await SessionStorage.clearSession();
        return const LoginScreen();
      }

      // For other server responses, preserve the session because the
      // user may still need to work with locally stored records.
      debugPrint(
        'SESSION VALIDATION UNEXPECTED RESPONSE: ${response.body}',
      );
      return HomeScreen(
        username: username,
        role: role,
        fullName: fullName,
        accessToken: accessToken,
      );
    } catch (e) {
      // No network/server connection: keep the existing session so the
      // offline-first application can still open and use local data.
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return const LoginScreen();
        }

        return snapshot.data ?? const LoginScreen();
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
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter username and password'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final accessToken = data['access_token'];
        final loggedInUsername = data['username'];
        final role = data['role'];
        final fullName = data['full_name'];

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
            builder: (context) => HomeScreen(
              username: loggedInUsername,
              role: role,
              fullName: fullName,
              accessToken: accessToken,
            ),
          ),
        );
      } else {
        final data = jsonDecode(response.body);

        final errorMessage =
            data['detail'] ?? 'Login failed';

        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
          ),
        );
      }
    } catch (e) {
      debugPrint('LOGIN CONNECTION ERROR: $e');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not connect to server',
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(20),
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
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'AI-Powered Voice-Based Health Assistant',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    hintText: 'Enter your username',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          obscurePassword =
                              !obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : login,
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Supporting ASHA workers in rural healthcare',
                  textAlign: TextAlign.center,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('AASHANet AI'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              fullName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Role: $role',
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordScreen(
                        accessToken: accessToken,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.note_add),
                label: const Text(
                  'Record',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const LocalRecordsScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.folder_open,
                ),
                label: const Text(
                  'Data Showing',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecordScreen(
                        accessToken: accessToken,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.keyboard),
                label: const Text(
                  'Typing Option',
                  style: TextStyle(
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Tasks feature coming next',
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.task_alt,
                ),
                label: const Text(
                  'Tasks',
                  style: TextStyle(
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

class _RecordScreenState extends State<RecordScreen> {
  final AudioRecorder _audioRecorder =
      AudioRecorder();

  final TextEditingController rawRecordController =
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

  // ==========================================================
  // VOICE RECORDING
  // ==========================================================

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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Voice recording saved'),
            ),
          );
        }

        return;
      }

      final hasPermission =
          await _audioRecorder.hasPermission();

      if (!hasPermission) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recording started'),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Could not record voice: $e'),
        ),
      );
    }
  }

  // ==========================================================
  // PROCESS RECORD
  // ==========================================================

  Future<void> processRecord() async {
    final rawText =
        rawRecordController.text.trim();

    // --------------------------------------------------------
    // STEP 0: VALIDATE INPUT
    // --------------------------------------------------------

    if (rawText.isEmpty && _audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
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

    // --------------------------------------------------------
    // STEP 1: PREPARE LOCAL RECORD
    // --------------------------------------------------------

    final serverRawInput =
        rawText.isEmpty
            ? '[Voice recording]'
            : rawText;

    final inputLanguage =
        rawText.isEmpty
            ? 'Kannada'
            : 'en';

    // Create a local ID before contacting the backend.
    final localRecordId =
        'local-${DateTime.now().millisecondsSinceEpoch}';

    // --------------------------------------------------------
    // STEP 2: SAVE LOCALLY FIRST
    // --------------------------------------------------------

    try {
      await _localRepository.saveHealthRecord(
        id: localRecordId,
        workerId: null,
        rawInput: serverRawInput,
        inputLanguage: inputLanguage,
        audioPath: _audioPath,
      );

      debugPrint(
        'LOCAL DATABASE: '
        'Health record saved successfully',
      );

      debugPrint(
        'LOCAL RECORD ID: $localRecordId',
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not save record locally: $e',
          ),
          duration:
              const Duration(seconds: 5),
        ),
      );

      return;
    }

    // --------------------------------------------------------
    // STEP 3: TRY BACKEND PROCESSING
    // --------------------------------------------------------

    try {
      // ------------------------------------------------------
      // STEP 3A: CREATE SERVER RECORD
      // ------------------------------------------------------

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

      if (createResponse.statusCode != 200 &&
          createResponse.statusCode != 201) {
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

      debugPrint(
        'SERVER RECORD ID: $recordId',
      );

      debugPrint(
        'SERVER WORKER ID: $workerId',
      );

      // ------------------------------------------------------
      // STEP 3A-1: LINK LOCAL RECORD TO SERVER RECORD
      // ------------------------------------------------------
      //
      // Keep the local SQLite ID as the local primary key.
      // Store the PostgreSQL record ID and authenticated worker
      // ID separately so the local record can be synchronized
      // safely without replacing its primary key.
      //
      // The record is NOT marked as synced yet.
      // Sync is completed only after Confirm & Save succeeds.
      // ------------------------------------------------------

      await _localRepository.linkServerRecord(
        localRecordId: localRecordId,
        serverRecordId: recordId.toString(),
        workerId: workerId.toString(),
      );

      debugPrint(
        'LOCAL RECORD LINKED: '
        'local=$localRecordId '
        'server=$recordId '
        'worker=$workerId',
      );

      // ------------------------------------------------------
      // STEP 3B: PROCESS RECORD
      // ------------------------------------------------------

      late Map<String, dynamic> processedData;

      // ------------------------------------------------------
      // STEP 3B-A: AUDIO → GEMINI
      // ------------------------------------------------------

      if (_audioPath != null) {
        debugPrint(
          'PROCESSING AUDIO: '
          '${_audioPath!}',
        );

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
          await http.MultipartFile.fromPath(
            'audio',
            _audioPath!,
          ),
        );

        final streamedResponse =
            await request.send();

        final response =
            await http.Response.fromStream(
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

        if (response.statusCode != 200) {
          throw Exception(
            'Failed to process audio: '
            '${response.body}',
          );
        }

        processedData =
            jsonDecode(
          response.body,
        );
      }

      // ------------------------------------------------------
      // STEP 3B-B: TYPED TEXT → EXISTING PROCESS
      // ------------------------------------------------------

      else {
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

        if (processResponse.statusCode != 200) {
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

      // ------------------------------------------------------
      // STEP 4: ONLINE PROCESSING SUCCESS
      // ------------------------------------------------------

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
      // ------------------------------------------------------
      // STEP 5: BACKEND UNAVAILABLE
      // ------------------------------------------------------

      debugPrint(
        'BACKEND PROCESSING ERROR: $e',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Record saved locally. '
            'It will be processed when the connection is available.',
          ),
          duration:
              Duration(seconds: 5),
        ),
      );

      debugPrint(
        'OFFLINE RECORD PENDING: '
        '$localRecordId',
      );
    }
  }

  // ==========================================================
  // RECORD UI
  // ==========================================================

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
              width: double.infinity,
              height: 100,
              child: OutlinedButton(
                onPressed:
                    isProcessing
                        ? null
                        : toggleRecording,
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isRecording
                          ? Icons.stop_circle
                          : Icons.mic,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isRecording
                          ? 'Tap to Stop Recording'
                          : 'Tap to Record Voice',
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),
                    if (_isRecording) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Recording...',
                        style:
                            TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    ],
                    if (!_isRecording &&
                        _audioPath != null) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Recording saved',
                        style:
                            TextStyle(
                          fontSize: 13,
                        ),
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
                alignLabelWithHint:
                    true,
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
              width: double.infinity,
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

class ReviewRecordScreen extends StatefulWidget {
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
            (widget.recordData['analyzed']
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

  // ==========================================================
  // CONFIRM RECORD
  // ==========================================================

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

      if (response.statusCode != 200) {
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
            content:
                const Text(
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
          duration:
              const Duration(seconds: 5),
        ),
      );
    }
  }

  // ==========================================================
  // REVIEW UI
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final rawRecord =
        widget.recordData['transcript']
                ?.toString() ??
            widget.recordData['raw_input']
                ?.toString() ??
            '';

    final aiStatus =
        widget.recordData['ai_status']
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
              width: double.infinity,
              padding:
                  const EdgeInsets.all(15),
              decoration:
                  BoxDecoration(
                border: Border.all(
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
              width: double.infinity,
              padding:
                  const EdgeInsets.all(15),
              decoration:
                  BoxDecoration(
                color: Colors.teal.withValues(
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
              width: double.infinity,
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