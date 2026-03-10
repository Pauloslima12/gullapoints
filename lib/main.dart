import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

/* ==========================
   CONFIG
========================== */

const String pointsApiBase = "https://pay.gullapay.com.br/api";
const String authTokenKey = "gullapay_token";

const String directusBase = "https://cms.gullapay.com.br";

final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: ['email'],
  serverClientId: '31190049887-v31ju7pehu751qat5oavjia41iksh5dm.apps.googleusercontent.com',
);

const String kExternalIdKey = "external_id";
const String kUserEmailKey = "user_email";
const String kUserNameKey = "user_name";

const String kLogoAsset = "assets/images/gulla_logo.png";

/* ==========================
   APP
========================== */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔒 trava rotação somente retrato
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const GullaPointsApp());
}

class GullaPointsApp extends StatelessWidget {
  const GullaPointsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Gulla Points",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: C.bg,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const SplashGate(),
    );
  }
}

/* ==========================
   THEME PREMIUM
========================== */

class C {
  static const bg = Color(0xFF070A12);
  static const panel = Color(0xFF0E1220);
  static const panel2 = Color(0xFF11162A);
  static const line = Color(0xFF1A2340);
  static const text = Color(0xFFE9EDF7);
  static const muted = Color(0xFFB6BED6);

  static const gold = Color(0xFFF3D27A);
  static const amber = Color(0xFFFFC94A);

  static const logoBlack = Color(0xFF000000);
}

class Grad {
  static const header = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF11173A), Color(0xFF0B0F23)],
  );

  static const goldBtn = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [C.amber, C.gold],
  );

  static const cardShine = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0E1220), Color(0xFF0A0D18)],
  );
}

/* ==========================
   UI COMPONENTS PREMIUM
========================== */

class GPCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Gradient? gradient;
  final bool elevated;

  const GPCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.gradient,
    this.elevated = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? Grad.cardShine,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: C.line.withOpacity(.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(elevated ? 0.5 : 0.3),
            blurRadius: elevated ? 32 : 24,
            offset: Offset(0, elevated ? 16 : 12),
            spreadRadius: elevated ? 2 : 0,
          ),
          BoxShadow(
            color: C.gold.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final IconData? icon;

  const PillButton({
    super.key,
    required this.label,
    required this.onTap,
    this.primary = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = primary ? Grad.goldBtn : null;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: bg,
          color: bg == null ? C.panel2 : null,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: primary ? C.gold.withOpacity(.3) : C.line.withOpacity(.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: primary ? C.amber.withOpacity(.3) : Colors.black.withOpacity(.2),
              blurRadius: primary ? 24 : 16,
              offset: Offset(0, primary ? 12 : 8),
            ),
            if (primary)
              BoxShadow(
                color: Colors.white.withOpacity(.1),
                blurRadius: 4,
                offset: const Offset(0, -1),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: primary ? const Color(0xFF1A1406) : C.gold,
                size: 20,
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: .5,
                fontSize: 14,
                color: primary ? const Color(0xFF1A1406) : C.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LogoMark extends StatelessWidget {
  final double size;
  final bool glowing;

  const LogoMark({super.key, this.size = 92, this.glowing = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: C.logoBlack,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(
          color: glowing ? C.gold.withOpacity(.6) : C.line.withOpacity(.65),
          width: glowing ? 2 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.6),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          if (glowing)
            BoxShadow(
              color: C.gold.withOpacity(.3),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.16),
      child: Image.asset(kLogoAsset, fit: BoxFit.contain),
    );
  }
}

PreferredSizeWidget goldAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    title: Text(
      title,
      style: const TextStyle(
        color: C.gold,
        fontWeight: FontWeight.w900,
        letterSpacing: .4,
        fontSize: 20,
      ),
    ),
    actions: actions,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              C.gold.withOpacity(.2),
              Colors.transparent,
            ],
          ),
        ),
      ),
    ),
  );
}

/* ==========================
   NODE API
========================== */

class NodeApi {
  static Future<Map<String, dynamic>> getBalance(String externalId) async {
    final uri = Uri.parse(
      '$pointsApiBase/points/balance?external_id=$externalId',
    );

    final res = await http.get(uri);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Balance HTTP ${res.statusCode}: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> listStores({String? search}) async {
    final uri = Uri.parse(
      '$pointsApiBase/clube/stores${search != null && search.isNotEmpty ? '?search=${Uri.encodeComponent(search)}' : ''}',
    );

    final res = await http.get(uri);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Stores HTTP ${res.statusCode}: ${res.body}');
    }

    final data = jsonDecode(res.body);
    final list = (data['data'] ?? []) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<Map<String, dynamic>> getStoreRewards({
    required int storeId,
    required String externalId,
  }) async {
    final uri = Uri.parse(
      '$pointsApiBase/stores/$storeId/rewards?external_id=$externalId',
    );

    final res = await http.get(uri);

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Rewards HTTP ${res.statusCode}: ${res.body}');
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

/* ==========================
   AUTH
========================== */

Future<String> signInWithGoogleAndGetExternalId() async {
  final account = await _googleSignIn.signIn();
  if (account == null) throw Exception("Login cancelado.");

  final auth = await account.authentication;
  final idToken = auth.idToken;
  if (idToken == null) throw Exception("Falha ao obter idToken do Google.");

  final res = await http.post(
    Uri.parse('$pointsApiBase/auth/google'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'idToken': idToken}),
  );

  if (res.statusCode != 200) {
    throw Exception("Erro ao autenticar no servidor (${res.statusCode})");
  }

  final data = jsonDecode(res.body);
  final token = data['token'];
  final user = data['user'];

  final prefs = await SharedPreferences.getInstance();

  await prefs.setString(authTokenKey, token);
  await prefs.setString(kExternalIdKey, user['external_id']);
  await prefs.setString(kUserEmailKey, user['email']);
  await prefs.setString(kUserNameKey, user['name']);

  return user['external_id'];
}

Future<void> signOutGoogle() async {
  try {
    await _googleSignIn.signOut();
  } catch (_) {}

  final prefs = await SharedPreferences.getInstance();

  await prefs.remove(authTokenKey);
  await prefs.remove(kExternalIdKey);
  await prefs.remove(kUserEmailKey);
  await prefs.remove(kUserNameKey);
  await prefs.remove('gulla_points_balance');
}

/* ==========================
   SPLASH GATE PREMIUM
========================== */

class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> with SingleTickerProviderStateMixin {
  bool _openedByLink = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _boot();
  }

    // referral loading removed from SplashGate (belongs to ReferralCard)

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    await Future.delayed(const Duration(milliseconds: 650));

    if (_openedByLink) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(authTokenKey);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            (token != null && token.isNotEmpty)
                ? const Shell()
                : const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Grad.header),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _pulseAnimation,
                child: const LogoMark(size: 96, glowing: true),
              ),
              const SizedBox(height: 18),
              const _BrandTitle(),
              const SizedBox(height: 24),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(C.gold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ==========================
   BRAND TITLE PREMIUM
========================== */

class _BrandTitle extends StatelessWidget {
  const _BrandTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          "Gulla",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          "Points",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: C.muted,
            letterSpacing: .6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/* ==========================
   LOGIN PREMIUM
========================== */

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _loginGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await signInWithGoogleAndGetExternalId();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const Shell()),
        (_) => false,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: Grad.header),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const LogoMark(size: 120, glowing: true),
                    const SizedBox(height: 20),
                    const _BrandTitle(),
                    const SizedBox(height: 32),
                    PillButton(
                      label: _loading ? "Aguarde..." : "ENTRAR COM GOOGLE",
                      primary: true,
                      onTap: _loading ? null : _loginGoogle,
                      icon: Icons.login_rounded,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.red.withOpacity(.3)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.redAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* ==========================
   SHELL + NAV PREMIUM
========================== */

class Shell extends StatefulWidget {
  const Shell({super.key});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int idx = 0;
  String? clubCategory;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePoints(
        onOpenClube: (cat) => setState(() {
          clubCategory = cat;
          idx = 1;
        }),
        onOpenScan: () => setState(() => idx = 2),
      ),
      GullaClubeScreen(initialCategory: clubCategory),
      const PointsScanScreen(),
      const ActivityScreen(),
      ProfileScreen(
        onLogout: () async {
          await signOutGoogle();
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        },
      ),
    ];

    return Scaffold(
      body: SafeArea(child: pages[idx]),
      bottomNavigationBar: SafeArea(
        top: false,
        child: _BottomBar(
          index: idx,
          onChange: (v) => setState(() => idx = v),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChange;

  const _BottomBar({required this.index, required this.onChange});

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0E1B), Color(0xFF07090F)],
        ),
        border: Border(
          top: BorderSide(
            color: C.line.withOpacity(.3),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.4),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(12, 10, 12, 12 + bottomSafe),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: "Pontos", active: index == 0, onTap: () => onChange(0)),
          _NavItem(icon: Icons.storefront_rounded, label: "Clube", active: index == 1, onTap: () => onChange(1)),
          _CenterAction(active: index == 2, onTap: () => onChange(2)),
          _NavItem(icon: Icons.bar_chart_rounded, label: "Atividade", active: index == 3, onTap: () => onChange(3)),
          _NavItem(icon: Icons.person_rounded, label: "Perfil", active: index == 4, onTap: () => onChange(4)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: active
            ? BoxDecoration(
                color: C.gold.withOpacity(.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: C.gold.withOpacity(.2),
                  width: 1,
                ),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? C.gold : C.muted,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                color: active ? C.gold : C.muted,
                letterSpacing: .3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterAction extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _CenterAction({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: C.logoBlack,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: active ? C.gold.withOpacity(.7) : C.gold.withOpacity(.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.6),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            if (active)
              BoxShadow(
                color: C.gold.withOpacity(.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Image.asset(kLogoAsset, fit: BoxFit.contain),
      ),
    );
  }
}

/* ==========================
   HOME PREMIUM
========================== */

class HomePoints extends StatefulWidget {
  final void Function(String? category) onOpenClube;
  final VoidCallback onOpenScan;
  const HomePoints({super.key, required this.onOpenClube, required this.onOpenScan});

  @override
  State<HomePoints> createState() => _HomePointsState();
}

class _HomePointsState extends State<HomePoints> with WidgetsBindingObserver {
  List<Map<String,dynamic>> _banners = [];
  bool _loading = false;
  int _balance = 0;
  String _name = "Usuário";
  List<dynamic> _lastActs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_loadCachedUser());
    unawaited(_loadBalance());
    unawaited(_loadLastActivities());
    unawaited(_loadBanners());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_loadBalance());
      unawaited(_loadLastActivities());
    }
  }

  Future<void> _loadCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final n = prefs.getString(kUserNameKey);
    if (n != null && n.trim().isNotEmpty) {
      if (mounted) setState(() => _name = n.trim());
    }
  }

  int _rewardTarget(int balance) {
    return 50;
  }

  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 12) return "Bom dia";
    if (h < 18) return "Boa tarde";
    return "Boa noite";
  }

  Future<void> _loadBanners() async {
    try {
      final uri = Uri.parse('$pointsApiBase/ads/banners?placement=home');
      final res = await http.get(uri);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final list = (data['data'] ?? []) as List;

        if (mounted) {
          setState(() {
            _banners = list.map((e) => Map<String,dynamic>.from(e)).toList();
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _loadLastActivities() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('gulla_activity') ?? '[]';
      final list = (jsonDecode(raw) as List).toList();

      final filtered = list.where((a) {
        final activity = a is Map ? a : {};
        return (activity['points'] ?? 0) > 0;
      }).toList();

      if (mounted) setState(() => _lastActs = filtered.take(3).toList());
    } catch (_) {
      if (mounted) setState(() => _lastActs = []);
    }
  }

  Future<void> _loadBalance() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final externalId = prefs.getString(kExternalIdKey);

      final cached = prefs.getInt('gulla_points_balance') ?? 0;
      if (_balance == 0 && cached > 0) setState(() => _balance = cached);

      if (externalId == null || externalId.isEmpty) return;

      final data = await NodeApi.getBalance(externalId);
      final b = int.tryParse('${data['balance'] ?? 0}') ?? 0;

      await prefs.setInt('gulla_points_balance', b);
      if (mounted) setState(() => _balance = b);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final target = _rewardTarget(_balance);
    final missing = (target - _balance).clamp(0, 999999);
    final progress = target == 0 ? 0.0 : (_balance / target).clamp(0.0, 1.0);
    final greeting = _getGreeting();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 20),
      children: [
        GPCard(
          gradient: Grad.header,
          padding: const EdgeInsets.all(16),
          elevated: true,
          child: Row(
            children: [
              const LogoMark(size: 48, glowing: true),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$greeting, $_name!",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: C.gold,
                        letterSpacing: .3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Bem-vindo ao Gulla Points",
                      style: TextStyle(
                        fontSize: 12,
                        color: C.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: C.panel2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: C.line.withOpacity(.4)),
                ),
                child: IconButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          await _loadBalance();
                          await _loadLastActivities();
                        },
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: _loading ? C.muted : C.gold,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        GPCard(
          elevated: true,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  C.panel,
                  C.panel2,
                ],
              ),
              border: Border.all(
                color: C.gold.withOpacity(.2),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.stars_rounded, color: C.gold, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      "Seu saldo atual",
                      style: TextStyle(
                        color: C.gold,
                        fontWeight: FontWeight.w900,
                        letterSpacing: .4,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "$_balance",
                      style: const TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        shadows: [
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        "GULLA",
                        style: TextStyle(
                          color: C.muted,
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: missing > 0 ? C.panel2 : C.gold.withOpacity(.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: missing > 0 ? C.line.withOpacity(.4) : C.gold.withOpacity(.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        missing > 0 ? Icons.trending_up_rounded : Icons.celebration_rounded,
                        color: missing > 0 ? C.muted : C.gold,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          missing > 0
                              ? "Faltam $missing pontos para o cupom de R\$10"
                              : "Você já pode resgatar um cupom 🎉",
                          style: TextStyle(
                            color: missing > 0 ? C.muted : C.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: C.panel2,
                      border: Border.all(color: C.line.withOpacity(.3)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.transparent,
                      valueColor: AlwaysStoppedAnimation<Color>(C.gold),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                PillButton(
                  label: "GANHAR PONTOS",
                  primary: true,
                  onTap: widget.onOpenScan,
                  icon: Icons.qr_code_scanner_rounded,
                ),
                const SizedBox(height: 12),
                PillButton(
                  label: "ABRIR GULLA CLUBE",
                  primary: false,
                  onTap: () => widget.onOpenClube(null),
                  icon: Icons.store_rounded,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        GPCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.explore_rounded, color: C.gold, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    "Onde usar seus pontos",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: C.gold,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.0,
                children: [
                  _QuickChip(icon: Icons.restaurant_rounded, label: "Restaurante", onTap: () => widget.onOpenClube("Restaurante")),
                  _QuickChip(icon: Icons.checkroom_rounded, label: "Vestuário", onTap: () => widget.onOpenClube("Vestuário")),
                  _QuickChip(icon: Icons.shopping_bag_rounded, label: "Calçados", onTap: () => widget.onOpenClube("Calçados")),
                  _QuickChip(icon: Icons.home_repair_service_rounded, label: "Utilidades", onTap: () => widget.onOpenClube("Utilidades")),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 🔥 BANNERS PROMOCIONAIS
        if (_banners.isNotEmpty)
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _banners.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) {
                final b = _banners[i];
                final img = b['image'];
                final link = b['link'];

                return InkWell(
                  onTap: () async {
                    if (link != null) {
                      final uri = Uri.parse(link);
                      await launchUrl(uri,mode:LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    width: 280,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      image: DecorationImage(
                        image: NetworkImage('$directusBase/assets/$img'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 18),
        _ReferralCard(),
        const SizedBox(height: 18),
        GPCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, color: C.gold, size: 20),
                  const SizedBox(width: 10),
                  const Text(
                    "Últimas atividades",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: C.gold,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_lastActs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: C.panel2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: C.line.withOpacity(.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: C.muted, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Sem registros ainda.",
                          style: TextStyle(color: C.muted, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ..._lastActs.map((activity) {
                  final act = activity is Map ? activity : {'display': activity.toString(), 'points': 0, 'store': 'Loja'};
                  final points = act['points'] ?? 0;

                  if (points == 0) return const SizedBox.shrink();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: C.panel2,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: C.line.withOpacity(.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: C.gold.withOpacity(.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.bolt_rounded, color: C.gold, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                act['display'] ?? '',
                                style: TextStyle(
                                  color: C.muted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "+${act['points']} pontos • ${act['store']}",
                                style: const TextStyle(
                                  color: C.gold,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: C.panel2,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: C.gold.withOpacity(.3), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: C.gold.withOpacity(.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: C.gold.withOpacity(.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: C.gold, size: 24),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                label,
                style: const TextStyle(
                  color: C.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: .2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==========================
   REFERRAL CARD PREMIUM
========================== */

class _ReferralCard extends StatefulWidget {
  @override
  State<_ReferralCard> createState() => _ReferralCardState();
}

class _ReferralCardState extends State<_ReferralCard> {
  @override
  void initState() {
    super.initState();
    _loadReferral();
  }
  String? _externalId;
  final _ctrl = TextEditingController();

  Future<void> _loadReferral() async {
    final prefs = await SharedPreferences.getInstance();
    final ext = prefs.getString(kExternalIdKey);

    if (ext != null && ext.isNotEmpty) {
      _externalId = ext;
      final link = "https://gullapay.com.br/indique?ref=$ext";

      if (mounted) {
        setState(() {
          _ctrl.text = link;
        });
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sendWhatsapp() async {
    final link = _ctrl.text.trim();
    if (link.isEmpty) return;

    final text = "Baixe o GullaPoints e ganhe 10 GULLA ao entrar no Gulla Clube: $link";
    final uri = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(text)}");

    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Não consegui abrir o WhatsApp neste dispositivo.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GPCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: C.gold.withOpacity(.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: C.gold, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "Indique e ganhe 10 GullaCoin",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: C.gold,
                    letterSpacing: .3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Compartilhe seu link. Quando até 5 amigos utilizarem o aplicativo pela primeira vez, você recebe 10 GullaCoin como recompensa digital.",
            style: TextStyle(
              color: C.muted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: "Cole aqui seu link...",
              hintStyle: TextStyle(color: C.muted, fontSize: 13),
              filled: true,
              fillColor: C.panel2,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: C.line.withOpacity(.4), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: C.line.withOpacity(.4), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: C.gold.withOpacity(.5), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 14),
          PillButton(
            label: "ENVIAR NO WHATSAPP",
            primary: true,
            onTap: _sendWhatsapp,
            icon: Icons.share_rounded,
          ),
          const SizedBox(height: 14),

          // 🔽 Saiba mais minimizado
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            collapsedIconColor: C.gold,
            iconColor: C.gold,
            title: const Text(
              "Saiba mais sobre o GullaCoin",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: C.gold,
                fontSize: 13,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "O GullaCoin é um token digital do ecossistema GullaPay. Ele será utilizado futuramente para recompensas, benefícios e novas funcionalidades dentro da plataforma.",
                  style: TextStyle(
                    color: C.muted,
                    fontSize: 12,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

/* ==========================
   CLUBE PREMIUM
========================== */

class GullaClubeScreen extends StatefulWidget {
  final String? initialCategory;
  const GullaClubeScreen({super.key, this.initialCategory});

  @override
  State<GullaClubeScreen> createState() => _GullaClubeScreenState();
}

class _GullaClubeScreenState extends State<GullaClubeScreen> {
  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _allStores = [];
  bool _loading = false;
  String? _err;

  String? _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory;
    unawaited(_load());
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      final list = await NodeApi.listStores(search: _searchCtrl.text);
      if (!mounted) return;
      setState(() {
        _allStores = list;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _extractCategories() {
    final set = <String>{};
    for (final s in _allStores) {
      final cat = (s['category'] ?? '').toString().trim();
      if (cat.isNotEmpty) set.add(cat);
    }
    final list = set.toList()..sort();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final categories = _extractCategories();

    final filtered = _allStores.where((s) {
      final matchesCategory = _category == null ||
          _category!.isEmpty ||
          (s['category'] ?? '').toString().toLowerCase() ==
              _category!.toLowerCase();

      final q = _searchCtrl.text.trim().toLowerCase();
      final matchesSearch = q.isEmpty ||
          s['name'].toString().toLowerCase().contains(q) ||
          s['city'].toString().toLowerCase().contains(q);

      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      appBar: goldAppBar(
        "Gulla Clube",
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: C.panel2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.line.withOpacity(.4)),
            ),
            child: IconButton(
              onPressed: _loading ? null : _load,
              icon: Icon(
                Icons.refresh_rounded,
                color: _loading ? C.muted : C.gold,
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GPCard(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "Buscar loja ou cidade...",
                hintStyle: TextStyle(color: C.muted, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: C.gold, size: 22),
                filled: true,
                fillColor: C.panel2,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: C.line.withOpacity(.4), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: C.line.withOpacity(.4), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: C.gold.withOpacity(.5), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (categories.isNotEmpty)
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CatChip(
                    label: "Todos",
                    active: _category == null,
                    onTap: () => setState(() => _category = null),
                  ),
                  ...categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: _CatChip(
                        label: cat,
                        active: _category == cat,
                        onTap: () => setState(() => _category = cat),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (!_loading && filtered.isEmpty && _err == null)
            GPCard(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: C.gold.withOpacity(.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, size: 48, color: C.gold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Nenhuma empresa encontrada",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tente outra categoria ou busca",
                    style: TextStyle(color: C.muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          else
            ...filtered.map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StoreRewardsScreen(store: s),
                        ),
                      );
                    },
                    child: GPCard(
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: C.gold.withOpacity(.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: C.gold.withOpacity(.3)),
                            ),
                            child: const Icon(Icons.store_rounded, color: C.gold, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${s['name'] ?? ''}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.location_on_rounded, size: 14, color: C.muted),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        "${s['city'] ?? ''} • ${s['category'] ?? ''}",
                                        style: TextStyle(
                                          color: C.muted,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: C.gold.withOpacity(.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_forward_ios_rounded, color: C.gold, size: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}

class _CatChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CatChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: active
              ? LinearGradient(
                  colors: [C.gold.withOpacity(.2), C.gold.withOpacity(.15)],
                )
              : null,
          color: active ? null : C.panel2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? C.gold.withOpacity(.6) : C.line.withOpacity(.5),
            width: 1.5,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: C.gold.withOpacity(.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? C.gold : C.muted,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: .3,
          ),
        ),
      ),
    );
  }
}

// 🔥 TELA DE RECOMPENSAS PREMIUM
class StoreRewardsScreen extends StatefulWidget {
  final Map<String, dynamic> store;
  const StoreRewardsScreen({super.key, required this.store});

  @override
  State<StoreRewardsScreen> createState() => _StoreRewardsScreenState();
}

class _StoreRewardsScreenState extends State<StoreRewardsScreen> {
  Map<String, dynamic>? data;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final externalId = prefs.getString(kExternalIdKey);
    if (externalId == null) return;

    final result = await NodeApi.getStoreRewards(
      storeId: widget.store['id'],
      externalId: externalId,
    );

    if (!mounted) return;
    setState(() {
      data = result;
      loading = false;
    });
  }

  // ✨ Método para resgatar e gerar cupom
  Future<void> _redeemReward(int rewardId, BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final externalId = prefs.getString(kExternalIdKey);
      final token = prefs.getString(authTokenKey);

      if (externalId == null || token == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erro: Usuário não autenticado")),
        );
        return;
      }

      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(C.gold),
              ),
              const SizedBox(height: 16),
              const Text(
                "Gerando seu cupom...",
                style: TextStyle(color: C.text, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

      final res = await http.post(
        Uri.parse('$pointsApiBase/rewards/redeem'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'external_id': externalId,
          'reward_id': rewardId,
        }),
      );

      print('[DEBUG REDEEM] Response status: ${res.statusCode}');
      print('[DEBUG REDEEM] Response body: ${res.body}');

      if (!context.mounted) return;
      Navigator.pop(context);

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);

        print('[DEBUG REDEEM] Response data: $data');

        if (data['ok'] == true || data['coupon_id'] != null) {
          if (!context.mounted) return;

          final couponId = data['coupon_id'].toString();
          final couponCode = (data['coupon_code'] ?? couponId).toString();
          final costPoints = int.tryParse('${data['points_used'] ?? 0}') ?? 0;

          print('[DEBUG REDEEM] Navegando com couponId: $couponId');

          await prefs.setInt('gulla_points_balance', int.tryParse('${data['store_balance'] ?? 0}') ?? 0);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CouponRedeemScreen(
                couponId: couponId,
                couponCode: couponCode,
                couponLink: data['coupon_link'] ?? 'https://pay.gullapay.com.br/coupon/$couponId',
                rewardTitle: data['reward_title'] ?? 'Recompensa',
                discountPercent: data['discount_percent'] ?? 0,
                pointsUsed: costPoints,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Erro ao resgatar')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro HTTP ${res.statusCode}')),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: goldAppBar(widget.store['name'] ?? "Loja"),
      body: loading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(C.gold),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Carregando recompensas...",
                    style: TextStyle(color: C.muted, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(18),
              children: [
                ...((data?['rewards'] ?? []) as List).map((r) {
                  final int cost = r['points_cost'];
                  final int user = r['user_points'];
                  final double progress =
                      cost == 0 ? 0 : (user / cost).clamp(0.0, 1.0);
                  final bool canRedeem = progress >= 1;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GPCard(
                      gradient: canRedeem ? Grad.goldBtn : null,
                      elevated: canRedeem,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: canRedeem
                                      ? Colors.black.withOpacity(.15)
                                      : C.gold.withOpacity(.12),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  Icons.card_giftcard_rounded,
                                  color: canRedeem ? const Color(0xFF1A1406) : C.gold,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  r['title'],
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: .3,
                                    color: canRedeem ? const Color(0xFF1A1406) : C.gold,
                                  ),
                                ),
                              ),
                              if (canRedeem)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    "PRONTO",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A1406),
                                      letterSpacing: .6,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Icon(
                                Icons.stars_rounded,
                                size: 18,
                                color: canRedeem ? const Color(0xFF1A1406) : C.gold,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "$user / $cost pontos",
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: canRedeem ? const Color(0xFF1A1406) : C.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              height: 12,
                              decoration: BoxDecoration(
                                color: canRedeem
                                    ? Colors.black.withOpacity(.15)
                                    : C.panel2,
                                border: Border.all(
                                  color: canRedeem
                                      ? Colors.black.withOpacity(.1)
                                      : C.line.withOpacity(.3),
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.transparent,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  canRedeem ? const Color(0xFF1A1406) : C.gold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          PillButton(
                            label: canRedeem
                                ? "RESGATAR AGORA"
                                : "Faltam ${r['points_missing']} pontos",
                            primary: canRedeem,
                            onTap: canRedeem
                                ? () async {
                                    await _redeemReward(r['id'], context);
                                  }
                                : null,
                            icon: canRedeem ? Icons.check_circle_rounded : Icons.lock_rounded,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}

/* ==========================
   CUPOM COM QR CODE
========================== */

class CouponRedeemScreen extends StatefulWidget {
  final String couponId;
  final String couponCode;
  final String couponLink;
  final String rewardTitle;
  final int discountPercent;
  final int pointsUsed;

  const CouponRedeemScreen({
    super.key,
    required this.couponId,
    required this.couponCode,
    required this.couponLink,
    required this.rewardTitle,
    required this.discountPercent,
    required this.pointsUsed,
  });

  @override
  State<CouponRedeemScreen> createState() => _CouponRedeemScreenState();
}

class _CouponRedeemScreenState extends State<CouponRedeemScreen> {
  @override
  void initState() {
    super.initState();
    print('[CouponScreen] Inicializando com couponId: ${widget.couponId}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: goldAppBar("Seu Cupom"),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const SizedBox(height: 20),
            GPCard(
              elevated: true,
              gradient: Grad.goldBtn,
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(.3),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.card_giftcard_rounded,
                      color: Colors.white,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.rewardTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1406),
                      letterSpacing: .3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${widget.discountPercent}% DE DESCONTO",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1406),
                        letterSpacing: .6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.black,
                        width: 2,
                      ),
                    ),
                    child: QrImageView(
                      data: widget.couponLink,
                      version: QrVersions.auto,
                      size: 200.0,
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "CÓDIGO: ${widget.couponCode}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1406),
                      letterSpacing: 2,
                      fontFamily: 'Courier',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "-${widget.pointsUsed} Gulla Points",
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1406),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Mostre este código ou QR no balcão",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black.withOpacity(.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PillButton(
              label: "COMPARTILHAR",
              primary: false,
              onTap: () async {
                await Share.share(
                  "Resgatei um cupom no GullaPoints: ${widget.couponLink}",
                  subject: "Meu cupom GullaPoints",
                );
              },
              icon: Icons.share_rounded,
            ),
            const SizedBox(height: 12),
            PillButton(
              label: "VOLTAR PARA HOME",
              primary: true,
              onTap: () {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/',
                  (route) => false,
                );
              },
              icon: Icons.home_rounded,
            ),
            const SizedBox(height: 20),
            GPCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: C.gold, size: 20),
                      const SizedBox(width: 10),
                      const Text(
                        "Como usar",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: C.gold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "1. Mostre o QR code ou código no balcão\n"
                    "2. O lojista aponta a câmera do celular\n"
                    "3. Cupom é validado automaticamente\n"
                    "4. Seu desconto é aplicado!",
                    style: TextStyle(
                      fontSize: 13,
                      color: C.muted,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ==========================
   ACTIVITY PREMIUM
========================== */

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  final _searchCtrl = TextEditingController();
  List<dynamic> _items = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    _searchCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('gulla_activity') ?? '[]';
      final list = (jsonDecode(raw) as List).toList();
      setState(() => _items = list);
    } catch (_) {
      setState(() => _items = []);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final q = _searchCtrl.text.trim().toLowerCase();
    final filtered = q.isEmpty
        ? _items
        : _items.where((x) {
            final activity = x is Map ? x : {};
            final store = (activity['store'] ?? '').toString().toLowerCase();
            return store.contains(q);
          }).toList();

    return Scaffold(
      appBar: goldAppBar(
        "Atividade",
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: C.panel2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.line.withOpacity(.4)),
            ),
            child: IconButton(
              onPressed: _loading ? null : _load,
              icon: Icon(
                Icons.refresh_rounded,
                color: _loading ? C.muted : C.gold,
                size: 22,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          GPCard(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: "Pesquisar por loja...",
                hintStyle: TextStyle(color: C.muted, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: C.gold, size: 22),
                filled: true,
                fillColor: C.panel2,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: C.line.withOpacity(.4), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: C.line.withOpacity(.4), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: C.gold.withOpacity(.5), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          if (filtered.isEmpty)
            GPCard(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: C.gold.withOpacity(.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bar_chart_rounded, size: 48, color: C.gold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Sem registros",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: .3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Quando você escanear QR ou resgatar,\naparece aqui.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: C.muted,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            ...filtered.map((activity) {
              final act = activity is Map ? activity : {'display': activity.toString(), 'points': 0, 'store': 'Loja'};
              final points = act['points'] ?? 0;

              if (points == 0) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GPCard(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: C.gold.withOpacity(.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.history_rounded, color: C.gold, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act['display'] ?? '',
                              style: TextStyle(
                                color: C.muted,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "+${act['points']} pontos • ${act['store']}",
                              style: const TextStyle(
                                color: C.gold,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

/* ==========================
   PROFILE PREMIUM
========================== */

class ProfileScreen extends StatelessWidget {
  final Future<void> Function() onLogout;
  const ProfileScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: goldAppBar("Perfil"),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GPCard(
            elevated: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LogoMark(size: 88, glowing: true),
                const SizedBox(height: 20),
                const Text(
                  "Perfil do Usuário",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: C.gold,
                    letterSpacing: .4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Gulla Points • by GullaPay",
                  style: TextStyle(
                    color: C.muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                PillButton(
                  label: "SAIR DA CONTA",
                  primary: false,
                  onTap: () async => onLogout(),
                  icon: Icons.logout_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ==========================
   SCAN PREMIUM
========================== */

class PointsScanScreen extends StatefulWidget {
  const PointsScanScreen({super.key});

  @override
  State<PointsScanScreen> createState() => _PointsScanScreenState();
}

class _PointsScanScreenState extends State<PointsScanScreen> with WidgetsBindingObserver {
  late final MobileScannerController _controller;

  bool _handled = false;
  bool _loading = false;
  String? _lastPayload;
  String? _resultMsg;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );

    unawaited(_safeStart());
  }

  Future<void> _safeStart() async {
    try {
      await _controller.start();
    } catch (_) {}
  }

  Future<void> _safeStop() async {
    try {
      await _controller.stop();
    } catch (_) {}
  }

  @override
  void deactivate() {
    unawaited(_safeStop());
    super.deactivate();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_safeStop());
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      unawaited(_safeStop());
    } else if (state == AppLifecycleState.resumed) {
      if (mounted) unawaited(_safeStart());
    }
  }

  Future<void> _appendActivity(String storeName, int points) async {
    if (points == 0) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('gulla_activity') ?? '[]';
      final list = jsonDecode(raw) as List;

      final now = DateTime.now();
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final formatted = '${twoDigits(now.day)}/${twoDigits(now.month)}/${now.year} ${twoDigits(now.hour)}:${twoDigits(now.minute)}:${twoDigits(now.second)}';

      list.insert(0, {
        'timestamp': now.toIso8601String(),
        'display': formatted,
        'store': storeName,
        'points': points,
      });

      await prefs.setString('gulla_activity', jsonEncode(list.take(200).toList()));
    } catch (e) {
      print('[DEBUG] Erro ao salvar atividade: $e');
    }
  }

  Future<void> _onPayload(String payload) async {
    setState(() {
      _loading = true;
      _lastPayload = payload;
      _resultMsg = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final externalId = prefs.getString(kExternalIdKey);

      final uri = Uri.parse('$pointsApiBase/points/scan');

      final res = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'payload': payload,
          'external_id': externalId,
        }),
      );

      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body);
        final msg = data['message']?.toString() ?? 'Scan confirmado!';
        final balance = int.tryParse('${data['balance'] ?? 0}') ?? 0;
        final pointsAdded = int.tryParse('${data['pointsAdded'] ?? 0}') ?? 0;

        final storeName = (data['store']?['name'] ?? 'Loja').toString();

        await prefs.setInt('gulla_points_balance', balance);

        print('[DEBUG SCAN] Points: $pointsAdded, Store: $storeName');
        await _appendActivity(storeName, pointsAdded);

        setState(() => _resultMsg = msg);
      } else {
        setState(() => _resultMsg = 'Não foi possível registrar (HTTP ${res.statusCode}).');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _resultMsg = 'Erro ao registrar: $e');
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  void _reset() {
    setState(() {
      _handled = false;
      _loading = false;
      _lastPayload = null;
      _resultMsg = null;
    });
    unawaited(_safeStart());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: goldAppBar(
        "Escanear QR",
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: C.panel2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: C.line.withOpacity(.4)),
            ),
            child: IconButton(
              onPressed: _reset,
              icon: const Icon(Icons.refresh_rounded, color: C.gold, size: 22),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
              child: MobileScanner(
                controller: _controller,
                onDetect: (capture) {
                  if (_handled) return;
                  final barcodes = capture.barcodes;
                  if (barcodes.isEmpty) return;
                  final raw = barcodes.first.rawValue;
                  if (raw == null || raw.trim().isEmpty) return;

                  _handled = true;
                  unawaited(_safeStop());
                  unawaited(_onPayload(raw.trim()));
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: GPCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: C.gold.withOpacity(.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.qr_code_scanner_rounded, color: C.gold, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Escaneie o QR do balcão',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: C.gold,
                            letterSpacing: .3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Você ganha pontos automaticamente (com limites por loja).',
                    style: TextStyle(
                      color: C.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                  if (_lastPayload != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: C.panel2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: C.line.withOpacity(.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, color: C.gold, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'QR lido: $_lastPayload',
                              style: TextStyle(
                                color: C.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_loading) ...[
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        valueColor: AlwaysStoppedAnimation<Color>(C.gold),
                      ),
                    ),
                  ],
                  if (_resultMsg != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: C.gold.withOpacity(.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: C.gold.withOpacity(.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: C.gold, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _resultMsg!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: SizedBox(
                      width: 240,
                      child: PillButton(
                        label: 'LER NOVO QR',
                        primary: true,
                        onTap: _reset,
                        icon: Icons.qr_code_scanner_rounded,
                      ),
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
}

void unawaited(Future<void> f) {}