import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'l10n/app_localizations.dart';
import 'infrastructure/api/api_client.dart';
import 'infrastructure/auth/session_storage.dart';
import 'infrastructure/settings/language_storage.dart';
import 'presentation/screens/language_selection_screen.dart';
import 'application/app_services.dart';
import 'config.dart';
import 'domain/record_status.dart';
import 'infrastructure/database/app_database.dart';
import 'presentation/app_locale.dart';
import 'presentation/review_data.dart';
import 'presentation/screens/local_records_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/widgets/design.dart';
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

    if (languageCode != null) {
      appLocale.value = Locale(languageCode);
    }

    setState(() {
      _isLoadingLanguage = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLanguage) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AASHANet AI',
        theme: AppTheme.light(),
        home: const BrandedLoader(),
      );
    }

    // Rebuilds the whole app whenever the language changes (first-launch
    // choice or the language button on the home screen).
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocale,
      builder: (context, selectedLocale, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AASHANet AI',

        // Selected app language.
        locale: selectedLocale ?? const Locale('en'),

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

        theme: AppTheme.light(),

        home: selectedLocale == null
            ? LanguageSelectionScreen(
                onLanguageSelected: (locale) => appLocale.value = locale,
              )
            : const StartupScreen(),
      ),
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

    final home = HomeScreen(
      username: username,
      role: role,
      fullName: fullName,
      accessToken: accessToken,
    );

    try {
      final valid = await ApiClient(
        baseUrl: baseUrl,
        tokenProvider: () async => accessToken,
      ).isSessionValid();

      if (!valid) {
        // Expired or invalid login. Local records are kept; they sync
        // after the same worker logs in again.
        await SessionStorage.clearSession();
        return const LoginScreen();
      }

      return home;
    } catch (e) {
      // Server unreachable or failing: continue offline with the saved
      // session so the worker can keep recording.
      debugPrint('SESSION CHECK SKIPPED: ${e.runtimeType}');
      return home;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _checkSession(),
      builder: (context, snapshot) {
        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const BrandedLoader();
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

    void showMessage(String message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    }

    try {
      final data = await ApiClient(
        baseUrl: baseUrl,
        tokenProvider: () async => null, // login needs no token
      ).login(username: username, password: password);

      final accessToken = data['access_token'] as String;
      final role = data['role'] as String;
      final fullName = data['full_name'] as String;

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
            username: data['username'] as String,
            role: role,
            fullName: fullName,
            accessToken: accessToken,
          ),
        ),
      );
    } on ApiException catch (e) {
      // Wrong credentials, disabled account or validation error: show the
      // server's message when it sent one.
      showMessage(e.detail is String ? e.detail as String : l10n.loginFailed);
    } catch (e) {
      debugPrint('LOGIN FAILED: ${e.runtimeType}');
      showMessage(l10n.couldNotConnectServer);
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
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.desktop;

    final intro = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(size: 64, onDark: true),
        const SizedBox(height: 28),
        Text(
          'AASHANet AI',
          style: textTheme.displaySmall?.copyWith(color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.loginSubtitle,
          style: textTheme.titleMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.88),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.volunteer_activism_rounded,
              color: AppColors.marigold,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.loginSupportText,
                style: textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    final form = SurfaceCard(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.welcome,
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 22),
            TextField(
              controller: usernameController,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              decoration: InputDecoration(
                labelText: l10n.username,
                hintText: l10n.usernameHint,
                prefixIcon: const Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: passwordController,
              obscureText: obscurePassword,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) {
                if (!isLoading) {
                  login();
                }
              },
              decoration: InputDecoration(
                labelText: l10n.password,
                hintText: l10n.passwordHint,
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    obscurePassword
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                  ),
                  onPressed: () {
                    setState(() {
                      obscurePassword = !obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 26),
            GradientButton(
              label: l10n.login,
              icon: Icons.login_rounded,
              loading: isLoading,
              onPressed: isLoading ? null : login,
            ),
          ],
        ),
      ),
    );

    // Desktop / large tablet: brand panel beside the form.
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            Expanded(
              flex: 5,
              child: HeroSurface(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: FadeSlideIn(child: intro),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: FadeSlideIn(
                      delay: const Duration(milliseconds: 150),
                      child: form,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Phone / tablet: brand on top, form card overlapping it.
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            HeroSurface(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadii.xl),
              ),
              child: SafeArea(
                bottom: false,
                child: ResponsiveCenter(
                  maxWidth: 520,
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 96),
                  child: FadeSlideIn(
                    child: SizedBox(width: double.infinity, child: intro),
                  ),
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -64),
              child: ResponsiveCenter(
                maxWidth: 520,
                child: FadeSlideIn(
                  delay: const Duration(milliseconds: 150),
                  child: form,
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
// HOME SCREEN
// ============================================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.username,
    required this.role,
    required this.fullName,
    required this.accessToken,
    @visibleForTesting this.servicesForTesting,
  });

  final String username;
  final String role;
  final String fullName;
  final String accessToken;

  /// Lets widget tests supply services built from test doubles.
  final AppServices? servicesForTesting;

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
    final services = widget.servicesForTesting ??
        await AppServices.startFor(widget.username);

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

  void _openRecordScreen({bool focusTyping = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordScreen(
          accessToken: widget.accessToken,
          focusTyping: focusTyping,
        ),
      ),
    );
  }

  void _openRecords([RecordFilter filter = RecordFilter.all]) {
    final services = _services;

    if (services == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocalRecordsScreen(
          services: services,
          onReview: _openReview,
          onRecordVisit: () {
            Navigator.pop(context);
            _openRecordScreen();
          },
          initialFilter: filter,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final services = _services;
    final wide = MediaQuery.sizeOf(context).width >= Breakpoints.tablet;

    final tiles = [
      ActionTile(
        icon: Icons.folder_open_rounded,
        title: l10n.dataShowing,
        subtitle: l10n.localHealthRecords,
        vertical: wide,
        onTap: services == null ? null : _openRecords,
      ),
      ActionTile(
        icon: Icons.keyboard_alt_outlined,
        title: l10n.typingOption,
        subtitle: l10n.enterRecordByTyping,
        color: AppColors.info,
        background: AppColors.infoMist,
        vertical: wide,
        onTap: services != null
            ? () => _openRecordScreen(focusTyping: true)
            : null,
      ),
      ActionTile(
        icon: Icons.task_alt_rounded,
        title: l10n.tasks,
        subtitle: l10n.comingSoon,
        color: AppColors.saffron,
        background: AppColors.marigoldMist,
        vertical: wide,
        onTap: null,
      ),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHero(context, services)),
          if (services != null)
            SliverToBoxAdapter(
              child: ResponsiveCenter(
                maxWidth: 1080,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: LoginRequiredBanner(
                    services: services,
                    onLogInAgain: () => _logout(loginExpired: true),
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: ResponsiveCenter(
              maxWidth: 1080,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 120),
                    child: _RecordCallToAction(
                      title: l10n.record,
                      subtitle: l10n.tapToRecordVoice,
                      onTap: services != null ? _openRecordScreen : null,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (wide)
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < tiles.length; i++) ...[
                            if (i > 0) const SizedBox(width: 16),
                            Expanded(
                              child: FadeSlideIn(
                                delay: Duration(milliseconds: 200 + 80 * i),
                                child: tiles[i],
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
                  else
                    for (var i = 0; i < tiles.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: FadeSlideIn(
                          delay: Duration(milliseconds: 200 + 80 * i),
                          child: tiles[i],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, AppServices? services) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    return HeroSurface(
      borderRadius: const BorderRadius.vertical(
        bottom: Radius.circular(AppRadii.xl),
      ),
      child: SafeArea(
        bottom: false,
        child: ResponsiveCenter(
          maxWidth: 1080,
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top bar: brand, connection status, logout.
              Row(
                children: [
                  const BrandMark(size: 40, onDark: true),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AASHANet AI',
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (services != null)
                    ConnectionStatusBadge(services: services, onDark: true),
                  IconButton(
                    tooltip: l10n.changeLanguage,
                    icon: const Icon(Icons.translate_rounded),
                    color: Colors.white,
                    onPressed: () => showLanguageSheet(context),
                  ),
                  IconButton(
                    tooltip: l10n.logout,
                    icon: const Icon(Icons.logout_rounded),
                    color: Colors.white,
                    onPressed: _logout,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              FadeSlideIn(
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.welcome,
                        style: textTheme.titleMedium?.copyWith(
                          color: AppColors.marigold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.fullName,
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 16,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${l10n.role}: ${widget.role}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (services != null) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _HomeSummary(
                    services: services,
                    onOpen: _openRecords,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Home: large voice-record call to action
// ------------------------------------------------------------

class _RecordCallToAction extends StatelessWidget {
  const _RecordCallToAction({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Pressable(
      onTap: onTap,
      semanticLabel: title,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.actionGradient,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          boxShadow: [
            BoxShadow(
              color: AppColors.saffron.withValues(alpha: 0.32),
              blurRadius: 26,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          child: Stack(
            children: [
              const Positioned.fill(
                child: CustomPaint(
                  painter: KolamPainter(opacity: 0.16, spacing: 26),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        color: AppColors.saffron,
                        size: 40,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// Home: live summary of this worker's records on the phone
// ------------------------------------------------------------

class _HomeSummary extends StatelessWidget {
  const _HomeSummary({required this.services, required this.onOpen});

  final AppServices services;

  /// Opens the records list with the tapped number's filter.
  final ValueChanged<RecordFilter> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return StreamBuilder<List<HealthRecord>>(
      stream: services.records.watchRecordsForOwner(services.username),
      builder: (context, snapshot) {
        final records = snapshot.data ?? const <HealthRecord>[];

        final awaitingReview =
            records.where(RecordFilter.needsReview.matches).length;
        final notSynced = records.where(RecordFilter.notSynced.matches).length;

        return Row(
          children: [
            Expanded(
              child: _SummaryStat(
                value: records.length,
                label: l10n.statRecordsSaved,
                icon: Icons.inventory_2_outlined,
                onTap: () => onOpen(RecordFilter.all),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryStat(
                value: awaitingReview,
                label: l10n.statAwaitingReview,
                icon: Icons.rate_review_outlined,
                highlight: awaitingReview > 0,
                onTap: () => onOpen(RecordFilter.needsReview),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SummaryStat(
                value: notSynced,
                label: l10n.statNotSynced,
                icon: Icons.cloud_upload_outlined,
                onTap: () => onOpen(RecordFilter.notSynced),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.value,
    required this.label,
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  final int value;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: AppRadii.md,
      semanticLabel: '$value $label',
      child: _body(),
    );
  }

  Widget _body() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: highlight
            ? AppColors.marigold.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(
          color: highlight
              ? AppColors.marigold.withValues(alpha: 0.6)
              : Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: highlight ? AppColors.marigold : Colors.white70,
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.toDouble()),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) => Text(
              v.round().toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
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
    this.focusTyping = false,
  });

  final String accessToken;

  /// Opened from "Typing Option": put the cursor in the text box.
  final bool focusTyping;

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

  /// Language spoken in the recording, sent to the AI. Defaults to the
  /// app language; the worker can change it with the chips.
  String? _spokenLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _spokenLanguage ??= spokenLanguageFor(Localizations.localeOf(context));
  }

  /// Deletes an unsent recording so the worker can record again.
  Future<void> _discardRecording() async {
    final path = _audioPath;

    setState(() {
      _audioPath = null;
    });

    if (path != null) {
      try {
        await File(path).delete();
      } catch (_) {
        // Already gone; nothing to clean up.
      }
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.recordingDiscarded)),
    );
  }

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

        HapticFeedback.mediumImpact();

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

      HapticFeedback.mediumImpact();

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
        inputLanguage: hasAudio ? (_spokenLanguage ?? 'Kannada') : 'en',
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
    final textTheme = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final voicePanel = SurfaceCard(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        children: [
          PulsingMicButton(
            isRecording: _isRecording,
            onPressed: isProcessing ? null : toggleRecording,
            size: 128,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _isRecording
                ? Column(
                    key: const ValueKey('recording'),
                    children: [
                      ElapsedTimer(
                        running: true,
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.saffron,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.recording,
                        style: textTheme.bodyMedium?.copyWith(
                          color: AppColors.saffron,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : _audioPath != null
                    ? Container(
                        key: const ValueKey('saved'),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.successMist,
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              l10n.recordingSaved,
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(key: ValueKey('idle'), height: 4),
          ),
          if (_audioPath != null && !_isRecording)
            TextButton.icon(
              onPressed: isProcessing ? null : _discardRecording,
              icon: const Icon(Icons.replay_rounded),
              label: Text(l10n.recordAgain),
            ),
          const SizedBox(height: 12),
          Text(
            _isRecording ? l10n.tapToStopRecording : l10n.tapToRecordVoice,
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(color: AppColors.forest),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.spokenLanguage,
            style: textTheme.labelLarge?.copyWith(color: AppColors.inkMuted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final (value, label) in [
                ('Kannada', 'ಕನ್ನಡ'),
                ('Hindi', 'हिंदी'),
                ('English', 'English'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _spokenLanguage == value,
                  showCheckmark: false,
                  selectedColor: AppColors.tealMist,
                  side: BorderSide(
                    color: _spokenLanguage == value
                        ? AppColors.teal
                        : AppColors.line,
                  ),
                  labelStyle: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _spokenLanguage == value
                        ? AppColors.forest
                        : AppColors.ink,
                  ),
                  onSelected: _isRecording || isProcessing
                      ? null
                      : (_) => setState(() => _spokenLanguage = value),
                ),
            ],
          ),
        ],
      ),
    );

    final services = AppServices.maybeCurrent;

    final typingPanel = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(l10n.enterRecordByTyping, icon: Icons.edit_note_rounded),
          const SizedBox(height: 14),
          TextField(
            controller: rawRecordController,
            autofocus: widget.focusTyping,
            minLines: 6,
            maxLines: 10,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: l10n.recordExampleHint,
              fillColor: AppColors.cream,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recordHealthVisit),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: ResponsiveCenter(
          maxWidth: 1080,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.captureHealthInformation,
                      style: textTheme.headlineSmall?.copyWith(
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.captureHealthDescription,
                      style: textTheme.bodyLarge?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (services != null)
                ValueListenableBuilder<bool>(
                  valueListenable: services.connectivity.isOnline,
                  builder: (context, online, _) => online
                      ? const SizedBox.shrink()
                      : Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Callout(
                            icon: Icons.cloud_off_rounded,
                            color: AppColors.info,
                            background: AppColors.infoMist,
                            child: Text(l10n.offlineRecordNotice),
                          ),
                        ),
                ),
              const SizedBox(height: 22),
              if (wide)
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: FadeSlideIn(
                          delay: const Duration(milliseconds: 100),
                          child: voicePanel,
                        ),
                      ),
                      SizedBox(
                        width: 64,
                        child: Center(
                          child: CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.sand,
                            child: Text(
                              l10n.orText,
                              style: textTheme.labelLarge?.copyWith(
                                color: AppColors.inkMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: FadeSlideIn(
                          delay: const Duration(milliseconds: 180),
                          child: typingPanel,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: voicePanel,
                ),
                const SizedBox(height: 18),
                OrDivider(l10n.orText),
                const SizedBox(height: 18),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: typingPanel,
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 1080,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: GradientButton(
            label: isProcessing ? l10n.analyzingRecord : l10n.processRecord,
            icon: Icons.auto_awesome_rounded,
            loading: isProcessing,
            onPressed: isProcessing ? null : processRecord,
          ),
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


class _ReviewRecordScreenState extends State<ReviewRecordScreen> {
  AppLocalizations get l10n => AppLocalizations.of(context)!;

  late final TextEditingController patientNameController;
  late final TextEditingController ageController;
  late final TextEditingController symptomsController;
  late final TextEditingController durationController;

  /// Fields the AI filled in, shown with a "please check" hint.
  late final Set<String> _aiFilled;

  String? _nameError;
  String? _ageError;

  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    final suggestedData =
        (widget.recordData['ai_suggested_data'] as Map<String, dynamic>?) ??
            (widget.recordData['analyzed'] as Map<String, dynamic>?) ??
            {};

    final symptoms = suggestedData['symptoms'] as List<dynamic>? ?? [];

    patientNameController = TextEditingController(
      text: suggestedData['patient_name']?.toString() ?? '',
    );
    ageController = TextEditingController(
      text: suggestedData['age']?.toString() ?? '',
    );
    symptomsController = TextEditingController(text: symptoms.join(', '));
    durationController = TextEditingController(
      text: suggestedData['duration']?.toString() ?? '',
    );

    _aiFilled = {
      if (patientNameController.text.isNotEmpty) 'name',
      if (ageController.text.isNotEmpty) 'age',
      if (symptomsController.text.isNotEmpty) 'symptoms',
      if (durationController.text.isNotEmpty) 'duration',
    };
  }

  @override
  void dispose() {
    patientNameController.dispose();
    ageController.dispose();
    symptomsController.dispose();
    durationController.dispose();

    super.dispose();
  }

  /// Checks the name and age, showing any problem under the field.
  /// Returns the age (or null when left empty) if everything is valid.
  ({bool valid, int? age}) _validate() {
    final name = patientNameController.text.trim();
    final ageText = ageController.text.trim();

    int? age;
    String? ageError;

    if (ageText.isNotEmpty) {
      age = int.tryParse(ageText);

      // The server only accepts ages 0-120; anything else would make
      // the record fail to sync forever.
      if (age == null || age < 0 || age > 120) {
        ageError = l10n.ageMustBeNumber;
      }
    }

    setState(() {
      _nameError = name.isEmpty ? l10n.enterBeneficiaryName : null;
      _ageError = ageError;
    });

    return (valid: _nameError == null && _ageError == null, age: age);
  }

  /// Saves the worker's confirmed details on the phone first, then sends
  /// them to the server if it is reachable. Offline, the confirmation
  /// waits in the sync queue. Only what the worker confirmed here is
  /// stored as the record's details - never the raw AI suggestions.
  Future<void> confirmRecord() async {
    final patientName =
        patientNameController.text.trim();

    final symptomsText =
        symptomsController.text.trim();

    final duration =
        durationController.text.trim();

    final check = _validate();

    if (!check.valid) {
      return;
    }

    final age = check.age;

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
              child: Text(l10n.ok),
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
    final rawRecord = widget.recordData['transcript']?.toString() ??
        widget.recordData['raw_input']?.toString() ??
        '';

    // English translation of a Kannada/Hindi recording, if the AI made one
    // and it differs from what was said.
    final english = widget.recordData['english']?.toString().trim() ?? '';
    final showEnglish = english.isNotEmpty && english != rawRecord.trim();

    final aiFailed =
        widget.recordData['ai_status']?.toString() == AiStatus.failed;

    final textTheme = Theme.of(context).textTheme;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    String? aiHint(String field) =>
        _aiFilled.contains(field) ? l10n.aiFilledHint : null;

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.aiExtractedInformation,
          style: textTheme.headlineSmall?.copyWith(color: AppColors.forest),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.reviewIntro,
          style: textTheme.bodyLarge?.copyWith(color: AppColors.inkMuted),
        ),
        const SizedBox(height: 16),
        Callout(
          icon: Icons.health_and_safety_outlined,
          child: Text(l10n.aiNotVerifiedNotice),
        ),
        if (aiFailed) ...[
          const SizedBox(height: 12),
          Callout(
            icon: Icons.error_outline_rounded,
            color: AppColors.danger,
            background: AppColors.dangerMist,
            child: Text(l10n.aiFailed),
          ),
        ],
      ],
    );

    Widget quote(String text, Color accent) => Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border(left: BorderSide(color: accent, width: 4)),
          ),
          child: Text(
            text,
            style: textTheme.bodyLarge?.copyWith(color: AppColors.ink),
          ),
        );

    final originalCard = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(
            l10n.originalRecord,
            icon: Icons.format_quote_rounded,
          ),
          const SizedBox(height: 14),
          quote(rawRecord, AppColors.marigold),
          if (showEnglish) ...[
            const SizedBox(height: 16),
            Text(
              l10n.translationLabel,
              style: textTheme.labelLarge?.copyWith(color: AppColors.inkMuted),
            ),
            const SizedBox(height: 8),
            quote(english, AppColors.teal),
          ],
        ],
      ),
    );

    final formCard = SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionLabel(
            l10n.aiSuggestedData,
            icon: Icons.auto_awesome_rounded,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: patientNameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
            decoration: InputDecoration(
              labelText: l10n.beneficiaryName,
              helperText: aiHint('name'),
              errorText: _nameError,
              prefixIcon: const Icon(Icons.person_outline_rounded),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: ageController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) {
              if (_ageError != null) setState(() => _ageError = null);
            },
            decoration: InputDecoration(
              labelText: l10n.ageLabel,
              helperText: aiHint('age'),
              errorText: _ageError,
              prefixIcon: const Icon(Icons.cake_outlined),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: symptomsController,
            minLines: 2,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: l10n.symptomsLabel,
              helperText: aiHint('symptoms') ?? l10n.symptomsHint,
              prefixIcon: const Icon(Icons.medical_information_outlined),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: durationController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: l10n.durationLabel,
              helperText: aiHint('duration'),
              prefixIcon: const Icon(Icons.timer_outlined),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.reviewExtractedInformation),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: ResponsiveCenter(
          maxWidth: 1080,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FadeSlideIn(child: header),
              const SizedBox(height: 20),
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 100),
                        child: originalCard,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        child: formCard,
                      ),
                    ),
                  ],
                )
              else ...[
                FadeSlideIn(
                  delay: const Duration(milliseconds: 100),
                  child: originalCard,
                ),
                const SizedBox(height: 16),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 160),
                  child: formCard,
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: ResponsiveCenter(
          maxWidth: 1080,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: GradientButton(
            label: isSaving ? l10n.saving : l10n.confirmAndSave,
            icon: Icons.check_circle_rounded,
            loading: isSaving,
            onPressed: isSaving ? null : confirmRecord,
          ),
        ),
      ),
    );
  }
}
