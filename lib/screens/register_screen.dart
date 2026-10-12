import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:local_auth/local_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';
import '../utils/colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final _storage = const FlutterSecureStorage();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _termsAccepted = false;
  bool _biometricEnabled = false;
  bool _isBiometricSupported = false;

  // Password strength
  double _passwordStrength = 0.0;
  String _passwordStrengthText = 'Weak';
  Color _passwordStrengthColor = Colors.red;

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
        });
      }
    } catch (e) {
      setState(() => _isBiometricSupported = false);
    }
  }

  // ═══ PASSWORD STRENGTH ═══
  void _checkPasswordStrength(String password) {
    setState(() {
      if (password.isEmpty) {
        _passwordStrength = 0.0;
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = Colors.red;
        return;
      }

      double strength = 0.0;
      if (password.length >= 8) strength += 0.2;
      if (password.contains(RegExp(r'[A-Z]'))) strength += 0.2;
      if (password.contains(RegExp(r'[a-z]'))) strength += 0.2;
      if (password.contains(RegExp(r'[0-9]'))) strength += 0.2;
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength += 0.2;

      if (strength >= 0.8) {
        _passwordStrengthText = 'Strong 💪';
        _passwordStrengthColor = Colors.green;
      } else if (strength >= 0.6) {
        _passwordStrengthText = 'Medium 👍';
        _passwordStrengthColor = Colors.orange;
      } else {
        _passwordStrengthText = 'Weak 🔒';
        _passwordStrengthColor = Colors.red;
      }

      _passwordStrength = strength;
    });
  }

  // ═══ BIOMETRIC ENABLE ═══
  Future<void> _setupBiometric() async {
    try {
      final LocalAuthentication auth = LocalAuthentication();

      bool canCheck = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();

      if (!canCheck || !isSupported) {
        _showError('Biometric not available on this device');
        return;
      }

      bool authenticated = await auth.authenticate(
        localizedReason: '🔐 Enroll your fingerprint for TURIVA',
      );

      if (authenticated) {
        setState(() => _biometricEnabled = true);
        _showSuccess('🔐 Fingerprint enrolled successfully!');
      } else {
        _showError('Biometric enrolment cancelled');
      }
    } catch (e) {
      _showError('Biometric error: ${e.toString()}');
    }
  }

  // ═══ REGISTER ═══
  void _register() async {
    // Validate
    if (_nameController.text.trim().isEmpty) {
      _showError('Please enter your name');
      return;
    }

    if (_nameController.text.trim().length < 2) {
      _showError('Name too short');
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showError('Please enter a valid email');
      return;
    }

    final password = _passwordController.text;
    if (password.length < 8) {
      _showError('Password must be at least 8 characters');
      return;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      _showError('Password must contain at least 1 uppercase letter');
      return;
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      _showError('Password must contain at least 1 lowercase letter');
      return;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      _showError('Password must contain at least 1 number');
      return;
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      _showError('Password must contain at least 1 special character');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match');
      return;
    }

    if (!_termsAccepted) {
      _showError('Please accept Terms of Service');
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = await _auth.registerWithEmail(
        name: _nameController.text.trim(),
        email: email,
        password: password,
      );

      if (user != null && _biometricEnabled) {
        // ⭐ Hifadhi credentials kwenye secure storage
        // (Kwa biometric login baadaye)
        await _storage.write(key: 'user_email', value: email);
        await _storage.write(key: 'user_password', value: password);
        await _storage.write(key: 'user_uid', value: user.uid);
        await _storage.write(key: 'biometric_enabled', value: 'true');
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showSuccess('🎉 Account created! Welcome ${_nameController.text}');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      });
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _handleAuthError(e);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  // ═══ GOOGLE SIGN-UP ═══
  Future<void> _registerWithGoogle() async {
    setState(() => _isGoogleLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isGoogleLoading = false);
        return;
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
        _showSuccess('Welcome ${userCredential.user!.displayName}!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      setState(() => _isGoogleLoading = false);
      _showError('Google sign-up failed: ${e.toString()}');
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
      case 'email-already-in-use':
        message = 'Email already registered. Please login.';
        break;
      case 'weak-password':
        message = 'Password too weak.';
        break;
      case 'invalid-email':
        message = 'Invalid email address.';
        break;
      case 'network-request-failed':
        message = 'No internet connection.';
        break;
      default:
        message = e.message ?? 'Registration failed';
    }
    _showError(message);
  }

  @override
  void dispose() {
    _entryController.dispose();
    _bgController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ═══ SAFARI BACKGROUND ═══
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1516426122078-c23e76319801?q=80&w=1200&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.primaryDark,
              ),
            ),
          ),

          // ═══ DARK OVERLAY ═══
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

          // ═══ GLOW ORBS ═══
          AnimatedBuilder(
            animation: _bgController,
            builder: (context, _) {
              return Stack(
                children: [
                  Positioned(
                    top: 100 - (_bgController.value * 80),
                    right: -100,
                    child: _glowOrb(300,
                        AppColors.accentGold.withOpacity(0.25)),
                  ),
                  Positioned(
                    bottom: 150 + (_bgController.value * 50),
                    left: -100,
                    child: _glowOrb(
                        350, Colors.purple.withOpacity(0.2)),
                  ),
                ],
              );
            },
          ),

          // ═══ MAIN CONTENT ═══
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
                      // ═══ BACK BUTTON ═══
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(width * 0.03),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white,
                              size: width * 0.05,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: height * 0.03),

                      // ═══ LOGO ═══
                      _buildLogo(width),

                      SizedBox(height: height * 0.03),

                      // ═══ WELCOME ═══
                      Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.07,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: width * 0.02),
                      Text(
                        'Join the TURIVA adventure 🇹🇿',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: width * 0.035,
                        ),
                      ),

                      SizedBox(height: height * 0.04),

                      // ═══ GLASS FORM ═══
                      _buildGlassForm(width),

                      SizedBox(height: height * 0.03),

                      // ═══ LOGIN LINK ═══
                      _buildLoginLink(width),

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
        SizedBox(height: width * 0.03),
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
              fontSize: width * 0.09,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
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
          // ═══ NAME ═══
          _glassField(
            controller: _nameController,
            label: 'Full Name',
            hint: 'John Doe',
            icon: Icons.person_outline,
            width: width,
          ),

          SizedBox(height: width * 0.04),

          // ═══ EMAIL ═══
          _glassField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'your@email.com',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            width: width,
          ),

          SizedBox(height: width * 0.04),

          // ═══ PASSWORD ═══
          _glassField(
            controller: _passwordController,
            label: 'Password',
            hint: '••••••••',
            icon: Icons.lock_outlined,
            obscureText: _obscurePassword,
            onChanged: _checkPasswordStrength,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white60,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            width: width,
          ),

          // ═══ PASSWORD STRENGTH ═══
          if (_passwordController.text.isNotEmpty) ...[
            SizedBox(height: width * 0.02),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _passwordStrength,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: _passwordStrengthColor,
                      minHeight: 4,
                    ),
                  ),
                ),
                SizedBox(width: width * 0.02),
                Text(
                  _passwordStrengthText,
                  style: TextStyle(
                    color: _passwordStrengthColor,
                    fontSize: width * 0.028,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],

          SizedBox(height: width * 0.04),

          // ═══ CONFIRM PASSWORD ═══
          _glassField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            hint: '••••••••',
            icon: Icons.lock_outline,
            obscureText: _obscureConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: Colors.white60,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            width: width,
          ),

          SizedBox(height: width * 0.04),

          // ═══ BIOMETRIC SECTION ═══
          if (_isBiometricSupported) _buildBiometricCard(width),

          SizedBox(height: width * 0.04),

          // ═══ TERMS ═══
          _buildTerms(width),

          SizedBox(height: width * 0.05),

          // ═══ REGISTER BUTTON ═══
          _buildRegisterButton(width),

          SizedBox(height: width * 0.04),

          // ═══ DIVIDER ═══
          _buildDivider(width),

          SizedBox(height: width * 0.04),

          // ═══ GOOGLE ═══
          _buildGoogleButton(width),
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
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
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

  // ═══ BIOMETRIC CARD ═══
  Widget _buildBiometricCard(double width) {
    return GestureDetector(
      onTap: _biometricEnabled ? null : _setupBiometric,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: _biometricEnabled
              ? Colors.green.withOpacity(0.15)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _biometricEnabled
                ? Colors.green.withOpacity(0.5)
                : Colors.white.withOpacity(0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.03),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _biometricEnabled
                    ? Colors.green.withOpacity(0.2)
                    : AppColors.accentGold.withOpacity(0.15),
              ),
              child: Icon(
                _biometricEnabled
                    ? Icons.check_circle
                    : Icons.fingerprint,
                color: _biometricEnabled
                    ? Colors.green
                    : AppColors.accentGold,
                size: width * 0.07,
              ),
            ),
            SizedBox(width: width * 0.03),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _biometricEnabled
                        ? 'Fingerprint Enrolled ✅'
                        : 'Enable Fingerprint',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: width * 0.037,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: width * 0.005),
                  Text(
                    _biometricEnabled
                        ? 'You can login with fingerprint'
                        : 'Fast & secure login',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: width * 0.028,
                    ),
                  ),
                ],
              ),
            ),
            if (!_biometricEnabled)
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white54,
                size: width * 0.04,
              ),
          ],
        ),
      ),
    );
  }

  // ═══ TERMS ═══
  Widget _buildTerms(double width) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => setState(() => _termsAccepted = !_termsAccepted),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: width * 0.06,
            height: width * 0.06,
            decoration: BoxDecoration(
              color: _termsAccepted
                  ? AppColors.accentGold
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _termsAccepted
                    ? AppColors.accentGold
                    : Colors.white38,
                width: 2,
              ),
            ),
            child: _termsAccepted
                ? Icon(
              Icons.check,
              color: Colors.black,
              size: width * 0.04,
            )
                : null,
          ),
        ),
        SizedBox(width: width * 0.03),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'I agree to the ',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: width * 0.03,
                  ),
                ),
                TextSpan(
                  text: 'Terms',
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontSize: width * 0.03,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextSpan(
                  text: ' & ',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: width * 0.03,
                  ),
                ),
                TextSpan(
                  text: 'Privacy',
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontSize: width * 0.03,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══ REGISTER BUTTON ═══
  Widget _buildRegisterButton(double width) {
    return GestureDetector(
      onTap: _isLoading ? null : _register,
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
                Icons.person_add_alt_1,
                color: Colors.black,
                size: width * 0.06,
              ),
              SizedBox(width: width * 0.02),
              Text(
                'CREATE ACCOUNT',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: width * 0.045,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
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

  // ═══ GOOGLE BUTTON ═══
  Widget _buildGoogleButton(double width) {
    return GestureDetector(
      onTap: _isGoogleLoading ? null : _registerWithGoogle,
      child: Container(
        width: double.infinity,
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
              SizedBox(width: width * 0.03),
              Text(
                'Sign up with Google',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: width * 0.038,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══ LOGIN LINK ═══
  Widget _buildLoginLink(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: TextStyle(
            color: Colors.white60,
            fontSize: width * 0.035,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
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
              'Login',
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