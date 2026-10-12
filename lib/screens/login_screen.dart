import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'main_screen.dart';
import '../utils/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _isBiometricSupported = false;
  bool _isFingerprintEnabled = false;
  String _biometricStatus = '🔓';
  String? _errorMessage;

  // Animations
  late AnimationController _entryController;
  late AnimationController _bgController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _checkBiometricSupport();
  }

  void _initAnimations() {
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
          parent: _entryController, curve: Curves.easeOutCubic),
    );

    _bgController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _entryController.forward();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      final LocalAuthentication auth = LocalAuthentication();
      bool canCheck = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();

      if (mounted) {
        setState(() {
          _isBiometricSupported = canCheck && isSupported;
          _isFingerprintEnabled = canCheck;
          _biometricStatus = _isFingerprintEnabled ? '🔒' : '🔓';
        });
      }
    } catch (e) {
      setState(() => _isBiometricSupported = false);
    }
  }

  // ═══ BIOMETRIC LOGIN ═══
  Future<void> _loginWithBiometrics() async {
    if (!_isBiometricSupported) {
      _showError('Biometric not supported on this device');
      return;
    }

    try {
      final LocalAuthentication auth = LocalAuthentication();
      bool authenticated = await auth.authenticate(
        localizedReason: '🔐 Login to TURIVA with fingerprint',
      );

      if (!authenticated) return;

      // ⭐ Soma credentials kutoka secure storage
      const storage = FlutterSecureStorage();
      final email = await storage.read(key: 'user_email');
      final password = await storage.read(key: 'user_password');
      final biometricEnabled = await storage.read(key: 'biometric_enabled');

      if (email == null || password == null || biometricEnabled != 'true') {
        _showError('No biometric account found. Please register first.');
        return;
      }

      // ⭐ Login kwa stored credentials
      setState(() => _isLoading = true);
      User? user = await _auth.loginWithEmail(
        email: email,
        password: password,
      );
      setState(() => _isLoading = false);

      if (user != null) {
        _showSuccess('Welcome back ${user.displayName ?? 'Traveler'}!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Biometric login failed: ${e.toString()}');
    }
  }

  // ⭐ GOOGLE SIGN-IN
  Future<void> _loginWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return; // User cancelled
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);

      setState(() => _isGoogleLoading = false);

      if (userCredential.user != null) {
        _showSuccess('✅ Welcome ${userCredential.user!.displayName}!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      setState(() => _isGoogleLoading = false);
      _showError('Google sign-in failed: ${e.toString()}');
    }
  }

  // ═══ EMAIL LOGIN ═══
  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty) {
      _showError('Please enter your email');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email');
      return;
    }

    if (password.isEmpty) {
      _showError('Please enter your password');
      return;
    }

    if (password.length < 6) {
      _showError('Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User? user = await _auth.loginWithEmail(
        email: email,
        password: password,
      );

      setState(() => _isLoading = false);

      if (user != null) {
        _showSuccess('Welcome back ${user.displayName ?? 'Traveler'}!');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainScreen()),
            );
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _handleAuthError(e);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  // ═══ HELPERS ═══
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _handleAuthError(FirebaseAuthException e) {
    String message;
    switch (e.code) {
      case 'user-not-found':
        message = 'No account found. Please register.';
        break;
      case 'wrong-password':
        message = 'Invalid password. Try again.';
        break;
      case 'invalid-email':
        message = 'Please enter a valid email.';
        break;
      case 'user-disabled':
        message = 'Account disabled. Contact support.';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Try later.';
        break;
      case 'network-request-failed':
        message = 'No internet. Check connection.';
        break;
      default:
        message = e.message ?? 'Login failed';
    }
    _showError(message);
  }

  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Enter your email to reset password');
      return;
    }
    try {
      await _auth.resetPassword(email);
      _showSuccess('📧 Reset email sent to $email');
    } catch (e) {
      _showError(e.toString());
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    _bgController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ═══════════════════════════════════════
          // 1️⃣ CINEMATIC BACKGROUND
          // ═══════════════════════════════════════
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1516426122078-c23e76319801?q=80&w=1200&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primaryDark,
              ),
            ),
          ),

          // ═══════════════════════════════════════
          // 2️⃣ DARK GRADIENT OVERLAY
          // ═══════════════════════════════════════
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.75),
                    Colors.black.withOpacity(0.95),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════
          // 3️⃣ ANIMATED GLOW ORBS
          // ═══════════════════════════════════════
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: 100 - (_bgController.value * 80),
                    right: -100,
                    child: _glowOrb(
                      300,
                      AppColors.accentGold.withOpacity(0.25),
                    ),
                  ),
                  Positioned(
                    bottom: 150 + (_bgController.value * 50),
                    left: -100,
                    child: _glowOrb(
                      350,
                      Colors.purple.withOpacity(0.2),
                    ),
                  ),
                ],
              );
            },
          ),

          // ═══════════════════════════════════════
          // 4️⃣ MAIN CONTENT
          // ═══════════════════════════════════════
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.06,
                    vertical: height * 0.02,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: height * 0.03),

                      // ═══ LOGO ═══
                      _buildLogo(width),

                      SizedBox(height: height * 0.04),

                      // ═══ WELCOME ═══
                      _buildWelcome(width),

                      SizedBox(height: height * 0.04),

                      // ═══ GLASS FORM ═══
                      _buildGlassForm(width),

                      SizedBox(height: height * 0.03),

                      // ═══ REGISTER LINK ═══
                      _buildRegisterLink(width),

                      SizedBox(height: height * 0.03),

                      // ═══ SECURITY BADGE ═══
                      _buildSecurityBadge(width),

                      SizedBox(height: height * 0.03),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══ GLOW ORB ═══
  Widget _glowOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }

  // ═══ LOGO ═══
  Widget _buildLogo(double width) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(width * 0.06),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.accentGold.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
          child: Container(
            padding: EdgeInsets.all(width * 0.05),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.goldGradient,
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.6),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Text(
              '🌍',
              style: TextStyle(fontSize: width * 0.15),
            ),
          ),
        ),
        SizedBox(height: width * 0.04),
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.accentGold,
              Colors.orange.shade300,
            ],
          ).createShader(bounds),
          child: Text(
            'TURIVA',
            style: TextStyle(
              color: Colors.white,
              fontSize: width * 0.1,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
        ),
        Text(
          'Explore Tanzania',
          style: TextStyle(
            color: Colors.white60,
            fontSize: width * 0.035,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  // ═══ WELCOME ═══
  Widget _buildWelcome(double width) {
    return Column(
      children: [
        Text(
          'Welcome Back',
          style: TextStyle(
            color: Colors.white,
            fontSize: width * 0.07,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: width * 0.02),
        Text(
          'Sign in to continue your adventure 🇹🇿',
          style: TextStyle(
            color: Colors.white70,
            fontSize: width * 0.035,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ═══ GLASS FORM ═══
  Widget _buildGlassForm(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          // ═══ EMAIL FIELD ═══
          _glassField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'your@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            width: width,
          ),

          SizedBox(height: width * 0.04),

          // ═══ PASSWORD FIELD ═══
          _glassField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outlined,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white60,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            width: width,
          ),

          SizedBox(height: width * 0.03),

          // ═══ FORGOT PASSWORD ═══
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resetPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: TextStyle(
                  color: AppColors.accentGold,
                  fontSize: width * 0.032,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          SizedBox(height: width * 0.04),

          // ═══ LOGIN BUTTON ═══
          _buildLoginButton(width),

          SizedBox(height: width * 0.04),

          // ═══ DIVIDER ═══
          _buildDivider(width),

          SizedBox(height: width * 0.04),

          // ═══ SOCIAL LOGIN ROW ═══
          _buildSocialRow(width),
        ],
      ),
    );
  }

  // ═══ GLASS FIELD ═══
  Widget _glassField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required double width,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.white70,
          fontSize: width * 0.033,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          color: Colors.white38,
          fontSize: width * 0.033,
        ),
        prefixIcon: Icon(
          icon,
          color: AppColors.accentGold,
          size: width * 0.055,
        ),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white.withOpacity(0.06),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: AppColors.accentGold,
            width: 2,
          ),
        ),
      ),
    );
  }

  // ═══ LOGIN BUTTON ═══
  Widget _buildLoginButton(double width) {
    return GestureDetector(
      onTap: _isLoading ? null : _login,
      child: Container(
        width: double.infinity,
        height: width * 0.14,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? null
              : LinearGradient(
            colors: [
              AppColors.accentGold,
              Colors.orange.shade400,
            ],
          ),
          color: _isLoading ? Colors.white10 : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isLoading
              ? []
              : [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.black,
              strokeWidth: 2.5,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.login,
                color: Colors.black,
                size: width * 0.06,
              ),
              SizedBox(width: width * 0.02),
              Text(
                'LOGIN',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ DIVIDER ═══
  Widget _buildDivider(double width) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.15),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.03),
          child: Text(
            'OR CONTINUE WITH',
            style: TextStyle(
              color: Colors.white38,
              fontSize: width * 0.026,
              letterSpacing: 1.5,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.15),
          ),
        ),
      ],
    );
  }

  // ═══ SOCIAL ROW ═══
  Widget _buildSocialRow(double width) {
    return Row(
      children: [
        // GOOGLE
        Expanded(
          child: GestureDetector(
            onTap: _isGoogleLoading ? null : _loginWithGoogle,
            child: Container(
              height: width * 0.13,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: _isGoogleLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.blue,
                    strokeWidth: 2,
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Google "G" logo using text
                    Container(
                      width: width * 0.06,
                      height: width * 0.06,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4285F4),
                            Color(0xFF34A853),
                            Color(0xFFFBBC05),
                            Color(0xFFEA4335),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: width * 0.04,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: width * 0.02),
                    Text(
                      'Google',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: width * 0.035,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // BIOMETRIC (kama ina support)
        if (_isBiometricSupported) ...[
          SizedBox(width: width * 0.03),
          Expanded(
            child: GestureDetector(
              onTap: _loginWithBiometrics,
              child: Container(
                height: width * 0.13,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.shade600,
                      Colors.purple.shade400,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.fingerprint,
                        color: Colors.white,
                        size: width * 0.07,
                      ),
                      SizedBox(width: width * 0.015),
                      Text(
                        'Bio',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.035,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ═══ REGISTER LINK ═══
  Widget _buildRegisterLink(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: TextStyle(
            color: Colors.white60,
            fontSize: width * 0.035,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.03,
              vertical: width * 0.015,
            ),
            decoration: BoxDecoration(
              gradient: AppColors.goldGradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentGold.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              'Register',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: width * 0.035,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══ SECURITY BADGE ═══
  Widget _buildSecurityBadge(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield,
          color: Colors.white.withOpacity(0.3),
          size: width * 0.035,
        ),
        SizedBox(width: width * 0.015),
        Text(
          'SSL Encrypted',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: width * 0.028,
          ),
        ),
        SizedBox(width: width * 0.04),
        Icon(
          Icons.verified,
          color: Colors.white.withOpacity(0.3),
          size: width * 0.035,
        ),
        SizedBox(width: width * 0.015),
        Text(
          'Firebase Protected',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: width * 0.028,
          ),
        ),
      ],
    );
  }
}