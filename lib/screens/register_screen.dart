import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:local_auth/local_auth.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import '../utils/colors.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;
  bool _biometricEnabled = false; // ✅ ADD THIS
  String _biometricStatus = '🔓'; // ✅ ADD THIS

  // 🆕 UNBELIEVABLE FEATURE: Bio-metric like strength indicator
  double _passwordStrength = 0.0;
  String _passwordStrengthText = 'Weak';
  Color _passwordStrengthColor = Colors.red;

  // 🆕 UNBELIEVABLE FEATURE: Spirit Animal Selection
  String? _selectedSpiritAnimal;

  // 🆕 UNBELIEVABLE FEATURE: Digital Passport ID
  String _digitalPassportId = '';

  // 🆕 UNBELIEVABLE FEATURE: Travel Personality
  String? _travelPersonality;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<Map<String, dynamic>> _spiritAnimals = [
    {'emoji': '🦁', 'name': 'Lion', 'meaning': 'Courageous Leader'},
    {'emoji': '🐘', 'name': 'Elephant', 'meaning': 'Wise Guardian'},
    {'emoji': '🦒', 'name': 'Giraffe', 'meaning': 'Visionary Seeker'},
    {'emoji': '🦏', 'name': 'Rhino', 'meaning': 'Fierce Protector'},
    {'emoji': '🐆', 'name': 'Leopard', 'meaning': 'Mysterious Adventurer'},
    {'emoji': '🦩', 'name': 'Flamingo', 'meaning': 'Graceful Explorer'},
  ];

  final List<Map<String, dynamic>> _travelPersonalities = [
    {'icon': '🏔️', 'name': 'Mountain Seeker', 'desc': 'Love heights & views'},
    {'icon': '🌊', 'name': 'Ocean Lover', 'desc': 'Beaches & watersports'},
    {'icon': '🌿', 'name': 'Nature Wanderer', 'desc': 'Forests & wildlife'},
    {'icon': '🎭', 'name': 'Culture Hunter', 'desc': 'Traditions & festivals'},
    {'icon': '🍛', 'name': 'Food Explorer', 'desc': 'Cuisine & cooking'},
    {'icon': '📸', 'name': 'Photo Artist', 'desc': 'Capture moments'},
  ];

  @override
  void initState() {
    super.initState();
    _generateDigitalPassport();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  // 🆕 UNBELIEVABLE FEATURE: Generate unique Digital Passport ID
  void _generateDigitalPassport() {
    final timestamp =
        DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final random = (1000 + (DateTime.now().microsecond % 9000)).toString();
    setState(() {
      _digitalPassportId = 'TUR-${timestamp}-${random}';
    });
  }

  // 🆕 UNBELIEVABLE FEATURE: Real-time password strength
  void _checkPasswordStrength(String password) {
    setState(() {
      if (password.isEmpty) {
        _passwordStrength = 0.0;
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = Colors.red;
        return;
      }

      double strength = 0.0;
      List<String> requirements = [];

      // Length 8+
      if (password.length >= 8) {
        strength += 0.2;
      } else {
        requirements.add('8+ chars');
      }

      // Uppercase
      if (password.contains(RegExp(r'[A-Z]'))) {
        strength += 0.2;
      } else {
        requirements.add('uppercase');
      }

      // Lowercase
      if (password.contains(RegExp(r'[a-z]'))) {
        strength += 0.2;
      } else {
        requirements.add('lowercase');
      }

      // Number
      if (password.contains(RegExp(r'[0-9]'))) {
        strength += 0.2;
      } else {
        requirements.add('number');
      }

      // Special character
      if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
        strength += 0.2;
      } else {
        requirements.add('special char');
      }

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

  void _register() async {
    // Validate all fields
    if (_nameController.text.isEmpty) {
      _showError('Please enter your name',
          'Your name is needed to create your Digital Passport');
      return;
    }

    if (_nameController.text.length < 2) {
      _showError('Name too short', 'Please enter your full name');
      return;
    }

    if (_emailController.text.isEmpty) {
      _showError(
          'Email required', 'We need your email for your Digital Passport');
      return;
    }

    if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      _showError('Invalid email', 'Please enter a valid email address');
      return;
    }

    String password = _passwordController.text;

    // Check length (8 characters)
    if (password.length < 8) {
      _showError('Password too short', 'Password must be at least 8 characters');
      return;
    }

    // Check uppercase
    if (!password.contains(RegExp(r'[A-Z]'))) {
      _showError('Missing uppercase', 'Password must contain at least 1 uppercase letter (A-Z)');
      return;
    }

    // Check lowercase
    if (!password.contains(RegExp(r'[a-z]'))) {
      _showError('Missing lowercase', 'Password must contain at least 1 lowercase letter (a-z)');
      return;
    }

    // Check number
    if (!password.contains(RegExp(r'[0-9]'))) {
      _showError('Missing number', 'Password must contain at least 1 number (0-9)');
      return;
    }

    // Check special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      _showError('Missing special character', 'Password must contain at least 1 special character (!@#\$%^&*)');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError(
          'Passwords do not match', 'Please confirm your password correctly');
      return;
    }

    if (_selectedSpiritAnimal == null) {
      _showError('Choose your Spirit Animal',
          'Your spirit animal is your Turiva mascot!');
      return;
    }

    if (_travelPersonality == null) {
      _showError('Select your travel personality',
          'This helps us personalize your experience');
      return;
    }

    if (!_termsAccepted) {
      _showError(
          'Accept Terms', 'Please accept our Terms of Service to continue');
      return;
    }

    setState(() => _isLoading = true);

    try {
      User? user = await _auth.registerWithEmail(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (user != null) {
        // Send admin notification
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': 'admin',
          'title': '👤 New User Registered!',
          'body': '${_nameController.text.trim()} just created an account',
          'type': 'user',
          'category': 'info',
          'icon': '👤',
          'actionType': 'open_user',
          'actionId': user.uid,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉 Welcome to the Adventure!', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Your Digital Passport ($_digitalPassportId) is ready. Please login to explore Tanzania! 🌍'),
            ],
          ),
          backgroundColor: Colors.green,
        ));
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      _handleAuthError(e);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Registration failed', e.toString());
    }
  }

  void _showError(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('❌ $title', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(message, style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.03)),
        ],
      ),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
    ));
  }

  Future<void> _setupBiometric() async {
    try {
      final LocalAuthentication auth = LocalAuthentication();

      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        _showError('Biometric not available', 'Your device does not support fingerprint or face ID');
        return;
      }

      bool authenticated = await auth.authenticate(
        localizedReason: 'Secure your Turiva account with fingerprint',
        // ✅ Remove all other parameters - just use localizedReason
      );

      if (authenticated) {
        setState(() {
          _biometricEnabled = true;
          _biometricStatus = '🔒';
        });
        _showSuccess('🔐 Biometric enabled!', 'Your fingerprint is now linked to Turiva');
      } else {
        _showError('Biometric failed', 'Authentication was cancelled or failed');
      }
    } catch (e) {
      _showError('Error', e.toString());
    }
  }

  void _showBiometricSuccess(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✅ $title',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message, style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.03)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccess(String title, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉 $title', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message, style: TextStyle(fontSize: MediaQuery.of(context).size.width * 0.03)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _handleAuthError(FirebaseAuthException e) {
    String title = 'Registration failed';
    String message = 'Please try again';

    switch (e.code) {
      case 'email-already-in-use':
        title = 'Email already in use';
        message = 'This email is already registered. Please login.';
        break;
      case 'weak-password':
        title = 'Password too weak';
        message = 'Please use a stronger password.';
        break;
      case 'invalid-email':
        title = 'Invalid email address';
        message = 'Please enter a valid email.';
        break;
      case 'network-request-failed':
        title = 'No internet connection';
        message = 'Please check your network.';
        break;
      default:
        title = 'Registration failed';
        message = e.message ?? 'Please try again';
    }

    _showError(title, message);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final height = size.height;
    final width = size.width;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;

        return Scaffold(
          body: Container(
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
                  ? _buildLandscapeLayout(constraints)
                  : _buildPortraitLayout(constraints),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortraitLayout(BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: constraints.maxWidth * 0.06,
        vertical: constraints.maxHeight * 0.02
      ),
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _buildRegistrationForm(constraints),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BoxConstraints constraints) {
    return Row(
      children: [
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDigitalPassport(),
                SizedBox(height: constraints.maxHeight * 0.02),
                _buildSecurityBadge(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: _buildRegistrationForm(constraints),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildRegistrationForm(BoxConstraints constraints) {
    final height = constraints.maxHeight;
    final isLandscape = constraints.maxWidth > constraints.maxHeight;

    return [
      if (!isLandscape) ...[
        _buildDigitalPassport(),
        SizedBox(height: height * 0.02),
      ],

      _buildProgressTracker(),
      SizedBox(height: height * 0.035),

      _buildTextField(
        controller: _nameController,
        label: 'Full Name',
        icon: Icons.person_outline,
        hint: 'Enter your full name',
      ),
      SizedBox(height: height * 0.02),

      _buildTextField(
        controller: _emailController,
        label: 'Email Address',
        icon: Icons.email_outlined,
        hint: 'Enter your email',
        isEmail: true,
      ),
      SizedBox(height: height * 0.02),

      _buildPasswordField(),
      SizedBox(height: height * 0.02),

      _buildConfirmPasswordField(),
      SizedBox(height: height * 0.035),

      _buildSpiritAnimalSection(),
      SizedBox(height: height * 0.035),

      _buildTravelPersonality(),
      SizedBox(height: height * 0.035),

      _buildBiometricSection(),
      SizedBox(height: height * 0.02),

      _buildTermsSection(),
      SizedBox(height: height * 0.028),

      _buildRegisterButton(),
      SizedBox(height: height * 0.028),

      _buildLoginLink(),
      SizedBox(height: height * 0.02),

      if (!isLandscape) ...[
        _buildSecurityBadge(),
        SizedBox(height: height * 0.02),
      ],
    ];
  }

  Widget _buildBiometricSection() {
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(width * 0.06),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _biometricEnabled
              ? Colors.green.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: width * 0.12,
            height: width * 0.12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _biometricEnabled
                  ? Colors.green.withOpacity(0.2)
                  : Colors.white.withOpacity(0.1),
            ),
            child: Icon(
              Icons.fingerprint,
              color: _biometricEnabled ? Colors.green : Colors.white.withOpacity(0.5),
              size: 28,
            ),
          ),
          SizedBox(width: width * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biometric Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: width * 0.037,
                  ),
                ),
                Text(
                  _biometricEnabled
                      ? 'Fingerprint protection active'
                      : 'Enable for faster, secure access',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: width * 0.03,
                  ),
                ),
              ],
            ),
          ),
          if (!_biometricEnabled)
            ElevatedButton(
              onPressed: _setupBiometric,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGold,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'ENABLE',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.037,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'ACTIVE',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.037,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDigitalPassport() {
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(width * 0.05),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: width * 0.15,
                height: width * 0.15,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accentGold,
                    width: 3,
                  ),
                  gradient: const LinearGradient(
                    colors: [AppColors.accentGold, AppColors.accentOrange],
                  ),
                ),
                child: const Center(
                  child: Text(
                    '🌍',
                    style: TextStyle(fontSize: 30),
                  ),
                ),
              ),
              SizedBox(width: width * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Turiva Digital Passport',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: width * 0.02),
                    Text(
                      'Your gateway to Tanzania 🇹🇿',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: width * 0.037,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accentGold.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'NEW',
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontSize: width * 0.03,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          Container(
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Text(
                  '🆔',
                  style: TextStyle(fontSize: 16), // No change specified
                ),
                SizedBox(width: width * 0.02),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Passport ID',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: width * 0.025,
                        ),
                      ),
                      Text(
                        _digitalPassportId,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.037,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _generateDigitalPassport,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTracker() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          _buildProgressStep(1, true, 'Account'),
          _buildProgressLine(true),
          _buildProgressStep(2, false, 'Profile'),
          _buildProgressLine(false),
          _buildProgressStep(3, false, 'Ready'),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int number, bool active, String label) {
    final width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? AppColors.accentGold
                : Colors.white.withOpacity(0.2),
            border: Border.all(
              color: active
                  ? AppColors.accentGold
                  : Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: TextStyle(
                color: active ? Colors.black : Colors.white.withOpacity(0.5),
                fontWeight: FontWeight.bold,
                fontSize: width * 0.037,
              ),
            ),
          ),
        ),
        SizedBox(height: width * 0.02),
        Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white.withOpacity(0.4),
            fontSize: width * 0.025,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool active) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: active ? AppColors.accentGold : Colors.white.withOpacity(0.2),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    bool isEmail = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
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
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.accentGold,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    final width = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          onChanged: _checkPasswordStrength,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Password (8+ chars, A-Z, a-z, 0-9, !@#)',
            labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            prefixIcon:
                Icon(Icons.lock_outlined, color: Colors.white.withOpacity(0.6)),
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
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.accentGold,
                width: 2,
              ),
            ),
          ),
        ),
        if (_passwordController.text.isNotEmpty) ...[
          SizedBox(height: MediaQuery.of(context).size.width * 0.02),
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
                  fontSize: MediaQuery.of(context).size.width * 0.03,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_passwordController.text.isNotEmpty && _passwordStrength < 0.8)
            Padding(
              padding: EdgeInsets.only(top: MediaQuery.of(context).size.width * 0.02),
              child: Wrap(
                spacing: 6,
                runSpacing: 2,
                children: [
                  _buildRequirementChip('8+ chars', _passwordController.text.length >= 8),
                  _buildRequirementChip('Uppercase', _passwordController.text.contains(RegExp(r'[A-Z]'))),
                  _buildRequirementChip('Lowercase', _passwordController.text.contains(RegExp(r'[a-z]'))),
                  _buildRequirementChip('Number', _passwordController.text.contains(RegExp(r'[0-9]'))),
                  _buildRequirementChip('Special !@#', _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildRequirementChip(String label, bool isMet) {
    final width = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isMet ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMet ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Text(
        isMet ? '✅ $label' : '❌ $label',
        style: TextStyle(
          color: isMet ? Colors.green : Colors.red,
          fontSize: width * 0.025,
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Confirm Password',
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon:
            Icon(Icons.lock_outline, color: Colors.white.withOpacity(0.6)),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.white.withOpacity(0.6),
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
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
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.accentGold,
            width: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSpiritAnimalSection() {
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(width * 0.06),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🦁 Spirit Animal',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.037,
                ),
              ),
              GestureDetector(
                onTap: _setupBiometric,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _biometricEnabled
                        ? Colors.green.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _biometricEnabled
                          ? Colors.green
                          : Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(_biometricStatus,
                          style: TextStyle(fontSize: width * 0.03)),
                      SizedBox(width: width * 0.02),
                      Text(
                        _biometricEnabled ? 'Enabled' : 'Enable Bio',
                        style: TextStyle(color: Colors.white, fontSize: width * 0.025),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(
                '🦁 Your Guide',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: width * 0.037,
                ),
              ),
              SizedBox(width: width * 0.02),
              Text(
                '🌟 Choose your guide',
                style: TextStyle(
                  color: AppColors.accentGold,
                  fontSize: width * 0.037,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.03),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _spiritAnimals.map((animal) {
              final isSelected = _selectedSpiritAnimal == animal['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedSpiritAnimal = animal['name'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentGold
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentGold
                          : Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.accentGold.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    children: [
                      Text(
                        animal['emoji'],
                        style: const TextStyle(fontSize: 24),
                      ),
                      Text(
                        animal['name'],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : Colors.white.withOpacity(0.8),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: width * 0.03,
                        ),
                      ),
                      if (isSelected)
                        Text(
                          animal['meaning'],
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontSize: width * 0.025,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: width * 0.02),
          Text(
            'Your spirit animal will be your Turiva mascot!',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: width * 0.03,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelPersonality() {
    final width = MediaQuery.of(context).size.width;

    return Container(
      padding: EdgeInsets.all(width * 0.06),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎯 Your Travel Personality',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: width * 0.037,
            ),
          ),
          SizedBox(height: width * 0.025),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _travelPersonalities.map((personality) {
              final isSelected = _travelPersonality == personality['name'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _travelPersonality = personality['name'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.accentGold
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.accentGold
                          : Colors.white.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        personality['icon'],
                        style: const TextStyle(fontSize: 20),
                      ),
                      Text(
                        personality['name'],
                        style: TextStyle(
                          color: isSelected
                              ? Colors.black
                              : Colors.white.withOpacity(0.8),
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: width * 0.03,
                        ),
                      ),
                      if (isSelected)
                        Text(
                          personality['desc'],
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.6),
                            fontSize: width * 0.025,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    final width = MediaQuery.of(context).size.width;

    return Row(
      children: [
        Theme(
          data: ThemeData(
            unselectedWidgetColor: Colors.white.withOpacity(0.3),
          ),
          child: Checkbox(
            value: _termsAccepted,
            onChanged: (value) {
              setState(() {
                _termsAccepted = value ?? false;
              });
            },
            activeColor: AppColors.accentGold,
            checkColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        Expanded(
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'I agree to the ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: width * 0.037,
                  ),
                ),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontSize: width * 0.037,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(
                  text: ' and ',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: width * 0.037,
                  ),
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.accentGold,
                    fontSize: width * 0.037,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
    final width = MediaQuery.of(context).size.width;

    return SizedBox(
      width: double.infinity,
      height: width * 0.14,
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
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                  ),
                ),
              )
            : ElevatedButton(
                onPressed: _register,
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
                      '🚀 CREATE TURIVA ACCOUNT',
                      style: TextStyle(
                        fontSize: width * 0.045,
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

  Widget _buildLoginLink() {
    final width = MediaQuery.of(context).size.width;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account?',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: width * 0.037,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text(
            'Login',
            style: TextStyle(
              color: AppColors.accentGold,
              fontWeight: FontWeight.bold,
              fontSize: width * 0.045,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.verified,
          color: Colors.white.withOpacity(0.3),
          size: 14,
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
        Text(
          '256-bit SSL Encrypted',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: MediaQuery.of(context).size.width * 0.03,
          ),
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
        Icon(
          Icons.verified,
          color: Colors.white.withOpacity(0.3),
          size: 14,
        ),
        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
        Text(
          'Firebase Protected',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: MediaQuery.of(context).size.width * 0.03,
          ),
        ),
      ],
    );
  }
}
