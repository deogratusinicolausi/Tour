import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';
import 'home_screen.dart';
import 'main_screen.dart';
import '../utils/colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isBiometricSupported = false;
  bool _isFingerprintEnabled = false;
  String _biometricStatus = '🔓';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
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
      setState(() {
        _isBiometricSupported = false;
      });
    }
  }

  Future<void> _loginWithBiometrics() async {
    if (!_isBiometricSupported) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biometric not supported on this device')),
      );
      return;
    }

    try {
      final LocalAuthentication auth = LocalAuthentication();

      bool authenticated = await auth.authenticate(
        localizedReason: '🔐 Log in to Turiva with your fingerprint',
        // ✅ Remove all other parameters - just use localizedReason
      );

      if (authenticated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Biometric authentication successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Biometric failed: ${e.toString()}')),
      );
    }
  }

  void _login() async {
    String email = _emailController.text.trim();
    String password = _passwordController.text;

    if (email.isEmpty) {
      _showError('Email required', 'Please enter your email address');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showError('Invalid email', 'Please enter a valid email address');
      return;
    }

    if (password.isEmpty) {
      _showError('Password required', 'Please enter your password');
      return;
    }

    if (password.length < 6) {
      _showError('Password too short', 'Password must be at least 6 characters');
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
        _showSuccess('✅ Welcome back ${user.displayName ?? 'Traveler'}!');

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
      _showError('Login failed', e.toString());
    }
  }

  void _showError(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('❌ $title', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleAuthError(FirebaseAuthException e) {
    String title = 'Login failed';
    String message = 'Please try again';
    String icon = '❌';

    switch (e.code) {
      case 'user-not-found':
        title = 'User not found';
        message = 'No account found with this email. Please register.';
        icon = '🔍';
        break;
      case 'wrong-password':
        title = 'Wrong password';
        message = 'Invalid password. Please try again.';
        icon = '🔑';
        break;
      case 'invalid-email':
        title = 'Invalid email';
        message = 'Please enter a valid email address.';
        icon = '📧';
        break;
      case 'user-disabled':
        title = 'Account disabled';
        message = 'This account has been disabled. Contact support.';
        icon = '🚫';
        break;
      case 'too-many-requests':
        title = 'Too many attempts';
        message = 'Please wait a moment and try again.';
        icon = '⏳';
        break;
      case 'network-request-failed':
        title = 'No internet';
        message = 'Please check your connection and try again.';
        icon = '🌐';
        break;
      default:
        title = 'Login failed';
        message = e.message ?? 'An unexpected error occurred';
    }

    setState(() => _errorMessage = '$icon $title: $message');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$icon $title', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: Colors.red.shade900,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _resetPassword() async {
    String email = _emailController.text.trim();

    if (email.isEmpty) {
      _showError('Email required', 'Enter your email to reset password');
      return;
    }

    if (!email.contains('@')) {
      _showError('Invalid email', 'Please enter a valid email');
      return;
    }

    try {
      await _auth.resetPassword(email);
      _showSuccess('📧 Password reset email sent to $email');
    } catch (e) {
      _showError('Reset failed', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;

          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                  AppColors.primaryGreen,
                ],
              ),
            ),
            child: SafeArea(
              child: isLandscape
                ? _buildLandscapeLayout(width, height)
                : _buildPortraitLayout(width, height),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPortraitLayout(double width, double height) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.06,
        vertical: height * 0.05,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _buildCommonWidgets(width, height),
      ),
    );
  }

  Widget _buildLandscapeLayout(double width, double height) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.05,
        vertical: height * 0.03,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildLogoSection(width),
                SizedBox(height: height * 0.05),
                _buildWelcomeText(height),
              ],
            ),
          ),
          SizedBox(width: 30.w),
          Expanded(
            flex: 3,
            child: Column(
              children: _buildFormWidgets(width, height),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCommonWidgets(double width, double height) {
    return [
      _buildLogoSection(width),
      SizedBox(height: height * 0.05),
      _buildWelcomeText(height),
      SizedBox(height: height * 0.04),
      ..._buildFormWidgets(width, height),
    ];
  }

  List<Widget> _buildFormWidgets(double width, double height) {
    return [
      _buildTextField(
        controller: _emailController,
        label: 'Email Address',
        icon: Icons.email_outlined,
        hint: 'Enter your email',
        keyboardType: TextInputType.emailAddress,
      ),
      SizedBox(height: height * 0.02),
      _buildPasswordField(),
      SizedBox(height: height * 0.012),
      _buildForgotPassword(),
      SizedBox(height: height * 0.035),
      _buildLoginButton(height),
      SizedBox(height: height * 0.02),
      if (_isBiometricSupported) ...[
        _buildBiometricSection(width),
        SizedBox(height: height * 0.02),
      ],
      _buildDivider(width),
      SizedBox(height: height * 0.02),
      _buildRegisterLink(),
      SizedBox(height: height * 0.025),
      _buildSecurityBadge(width),
    ];
  }

  Widget _buildLogoSection(double width) {
    return Container(
      width: width * 0.25,
      height: width * 0.25,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accentGold.withOpacity(0.3),
          width: 3,
        ),
      ),
      child: Center(
        child: Text('🌍', style: TextStyle(fontSize: width * 0.12)),
      ),
    );
  }

  Widget _buildWelcomeText(double height) {
    return Column(
      children: [
        Text(
          'Welcome Back!',
          style: TextStyle(
            color: Colors.white,
            fontSize: height * 0.035,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: height * 0.01),
        Text(
          'Sign in to continue your Tanzanian adventure 🇹🇿',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: height * 0.018,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.6)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        hintText: 'Enter your password',
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        prefixIcon: Icon(Icons.lock_outlined, color: Colors.white.withOpacity(0.6)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white.withOpacity(0.6),
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accentGold, width: 2),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
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
            color: AppColors.accentGold.withOpacity(0.8),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(double height) {
    return SizedBox(
      width: double.infinity,
      height: height * 0.07,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: _isLoading
              ? null
              : LinearGradient(
            colors: [AppColors.accentGold, AppColors.accentOrange],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _isLoading
              ? []
              : [
            BoxShadow(
              color: AppColors.accentGold.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: _isLoading
            ? Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
            ),
          ),
        )
            : ElevatedButton(
          onPressed: _login,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🚀 LOGIN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBiometricSection(double width) {
    return GestureDetector(
      onTap: _loginWithBiometrics,
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fingerprint,
              color: Colors.white.withOpacity(0.8),
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Login with Fingerprint',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _biometricStatus,
              style: const TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(double width) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Colors.white.withOpacity(0.2),
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.04),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Colors.white.withOpacity(0.2),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?",
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
          },
          child: Text(
            'Register',
            style: TextStyle(
              color: AppColors.accentGold,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge(double width) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.shield,
          color: Colors.white.withOpacity(0.3),
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          '256-bit SSL Encrypted',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 11,
          ),
        ),
        SizedBox(width: width * 0.04),
        Icon(
          Icons.verified,
          color: Colors.white.withOpacity(0.3),
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          'Firebase Protected',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}