import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/feed_user_service.dart';
import '../utils/colors.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen>
    with TickerProviderStateMixin {
  final _captionController = TextEditingController();
  final _locationController = TextEditingController();
  final _picker = ImagePicker();
  final _service = FeedUserService();

  File? _mediaFile;
  String _mediaType = 'image';
  bool _isUploading = false;
  double _uploadProgress = 0;

  late AnimationController _pulseController;
  late AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _floatController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _captionController.dispose();
    _locationController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() {
          _mediaFile = File(picked.path);
          _mediaType = 'image';
        });
      }
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final picked = await _picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 3),
      );
      if (picked != null) {
        setState(() {
          _mediaFile = File(picked.path);
          _mediaType = 'video';
        });
      }
    } catch (e) {
      _snack('Error: $e');
    }
  }

  Future<void> _submit() async {
    if (_mediaFile == null) {
      _snack('Please select ${_mediaType == 'video' ? 'a video' : 'an image'}');
      return;
    }
    if (_captionController.text.trim().isEmpty) {
      _snack('Please write a caption');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.1;
    });

    // Simulate progress
    for (int i = 1; i <= 9; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (mounted) setState(() => _uploadProgress = i / 10);
    }

    final ok = await _service.createPost(
      mediaFile: _mediaFile!,
      mediaType: _mediaType,
      caption: _captionController.text.trim(),
      location: _locationController.text.trim(),
    );

    if (!mounted) return;
    setState(() {
      _isUploading = false;
      _uploadProgress = 0;
    });

    if (ok) {
      _snack('✅ Post created successfully!');
      Navigator.pop(context, true);
    } else {
      _snack('❌ Failed to create post');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // ═══════════════════════════════════════════
          // 1️⃣ DEFAULT BACKGROUND IMAGE (Safari)
          // ═══════════════════════════════════════════
          Positioned.fill(
            child: Image.network(
              'https://images.unsplash.com/photo-1516426122078-c23e76319801?q=80&w=1200&auto=format&fit=crop',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1a1a2e),
                      const Color(0xFF16213e),
                      const Color(0xFF0f3460),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════
          // 2️⃣ DARK GRADIENT OVERLAY (kwa readability)
          // ═══════════════════════════════════════════
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // ═══════════════════════════════════════════
          // 3️⃣ COLOR ACCENT GLOW (subtle animation)
          // ═══════════════════════════════════════════
          AnimatedBuilder(
            animation: _floatController,
            builder: (context, child) {
              return Positioned(
                top: -100 + (_floatController.value * 50),
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentGold.withOpacity(0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Positioned(
                bottom: -100,
                left: -100,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.deepOrange.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // ═══════════════════════════════════════════
          // 4️⃣ MAIN CONTENT
          // ═══════════════════════════════════════════
          SafeArea(
            child: Column(
              children: [
                // ═══ APP BAR ═══
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: width * 0.04,
                    vertical: width * 0.03,
                  ),
                  child: Row(
                    children: [
                      // Back button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: EdgeInsets.all(width * 0.025),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                            ),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: width * 0.055,
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Title
                      Column(
                        children: [
                          Text(
                            'Create Post',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: width * 0.05,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Share your journey',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: width * 0.028,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),

                      // Empty space for symmetry
                      SizedBox(width: width * 0.105),
                    ],
                  ),
                ),

                // ═══ SCROLLABLE CONTENT ═══
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ═══ MEDIA UPLOAD ZONE ═══
                        _buildMediaZone(width, height),

                        SizedBox(height: height * 0.03),

                        // ═══ CAPTION FIELD ═══
                        _buildGlassField(
                          controller: _captionController,
                          label: 'Caption',
                          hint: 'Tell your story...',
                          icon: Icons.edit_note,
                          maxLines: 3,
                          width: width,
                        ),

                        SizedBox(height: height * 0.02),

                        // ═══ LOCATION FIELD ═══
                        _buildGlassField(
                          controller: _locationController,
                          label: 'Location',
                          hint: 'Where was this?',
                          icon: Icons.location_on,
                          maxLines: 1,
                          width: width,
                        ),

                        SizedBox(height: height * 0.03),

                        // ═══ PROGRESS BAR (kama uploading) ═══
                        if (_isUploading) _buildProgressBar(width),

                        SizedBox(height: height * 0.02),

                        // ═══ SUBMIT BUTTON ═══
                        _buildSubmitButton(width, height),

                        SizedBox(height: height * 0.04),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // MEDIA UPLOAD ZONE
  // ═══════════════════════════════════════════
  Widget _buildMediaZone(double width, double height) {
    return GestureDetector(
      onTap: _showMediaSourceSheet,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: width * 0.85,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _mediaFile != null
                ? AppColors.accentGold
                : Colors.white.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _mediaFile != null
                  ? AppColors.accentGold.withOpacity(0.4)
                  : Colors.black.withOpacity(0.3),
              blurRadius: _mediaFile != null ? 30 : 20,
              offset: const Offset(0, 10),
            ),
          ],
          image: _mediaFile != null && _mediaType == 'image'
              ? DecorationImage(
            image: FileImage(_mediaFile!),
            fit: BoxFit.cover,
          )
              : null,
        ),
        child: _mediaFile == null
            ? _buildEmptyMediaPlaceholder(width)
            : _mediaType == 'video'
            ? _buildVideoPlaceholder(width)
            : _buildMediaOverlay(width),
      ),
    );
  }

  Widget _buildEmptyMediaPlaceholder(double width) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated camera icon
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1 + (_pulseController.value * 0.1),
                child: Container(
                  padding: EdgeInsets.all(width * 0.06),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.goldGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withOpacity(
                          0.4 + _pulseController.value * 0.3,
                        ),
                        blurRadius: 20 + _pulseController.value * 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.add_a_photo,
                    color: Colors.black,
                    size: width * 0.12,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: width * 0.06),

          Text(
            'Tap to add',
            style: TextStyle(
              color: Colors.white,
              fontSize: width * 0.055,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: width * 0.01),
          Text(
            'Photo or Video',
            style: TextStyle(
              color: Colors.white70,
              fontSize: width * 0.038,
            ),
          ),
          SizedBox(height: width * 0.04),

          // Info chips
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildInfoChip(Icons.image, 'Max 5MB', width),
              SizedBox(width: width * 0.02),
              _buildInfoChip(Icons.videocam, 'Max 3 min', width),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text, double width) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.03,
        vertical: width * 0.015,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: width * 0.035),
          SizedBox(width: width * 0.01),
          Text(
            text,
            style: TextStyle(color: Colors.white70, fontSize: width * 0.028),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlaceholder(double width) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: [Colors.black, Colors.black.withOpacity(0.7)],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.play_circle_fill,
                  size: width * 0.2,
                  color: Colors.white,
                ),
                SizedBox(height: width * 0.03),
                Text(
                  'Video ready',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.04,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: width * 0.02),
                Text(
                  'Tap to change',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: width * 0.03,
                  ),
                ),
              ],
            ),
          ),
          // Video badge
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: width * 0.03,
                vertical: width * 0.012,
              ),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.videocam,
                      color: Colors.black, size: width * 0.035),
                  SizedBox(width: width * 0.01),
                  Text(
                    'VIDEO',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: width * 0.028,
                      fontWeight: FontWeight.bold,
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

  Widget _buildMediaOverlay(double width) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withOpacity(0.6),
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.all(width * 0.04),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: width * 0.04,
                  vertical: width * 0.02,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit, color: Colors.white, size: width * 0.04),
                    SizedBox(width: width * 0.02),
                    Text(
                      'Tap to change',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.032,
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
    );
  }

  // ═══════════════════════════════════════════
  // GLASS FIELD (input)
  // ═══════════════════════════════════════════
  Widget _buildGlassField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int maxLines,
    required double width,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: width * 0.035,
              ),
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: width * 0.035,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.only(left: width * 0.03),
                child: Icon(
                  icon,
                  color: AppColors.accentGold,
                  size: width * 0.055,
                ),
              ),
              prefixIconConstraints: BoxConstraints(
                minWidth: width * 0.12,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: width * 0.04,
                vertical: width * 0.04,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // PROGRESS BAR
  // ═══════════════════════════════════════════
  Widget _buildProgressBar(double width) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  value: _uploadProgress,
                  strokeWidth: 2,
                  color: AppColors.accentGold,
                ),
              ),
              SizedBox(width: width * 0.02),
              Text(
                'Uploading... ${(_uploadProgress * 100).toInt()}%',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: width * 0.032,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.02),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _uploadProgress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.accentGold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SUBMIT BUTTON
  // ═══════════════════════════════════════════
  Widget _buildSubmitButton(double width, double height) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: height * 0.075,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFFD700),
                const Color(0xFFFFA500),
                const Color(0xFFFF8C00),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.accentGold.withOpacity(
                  0.4 + _pulseController.value * 0.3,
                ),
                blurRadius: 20 + _pulseController.value * 10,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: _isUploading ? null : _submit,
              child: Center(
                child: _isUploading
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: width * 0.03),
                    const Text(
                      'Uploading...',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rocket_launch,
                      color: Colors.black,
                      size: width * 0.06,
                    ),
                    SizedBox(width: width * 0.02),
                    Text(
                      'Publish Post',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: width * 0.042,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // MEDIA SOURCE SHEET
  // ═══════════════════════════════════════════
  void _showMediaSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a2e),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Add Photo or Video',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose from',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Grid ya options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _mediaOption(
                      icon: Icons.camera_alt,
                      label: 'Camera',
                      sublabel: 'Take photo',
                      color: Colors.blue,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.camera);
                      },
                    ),
                    _mediaOption(
                      icon: Icons.videocam,
                      label: 'Record',
                      sublabel: 'Video',
                      color: Colors.red,
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideo(ImageSource.camera);
                      },
                    ),
                    _mediaOption(
                      icon: Icons.photo_library,
                      label: 'Gallery',
                      sublabel: 'Choose photo',
                      color: Colors.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _pickImage(ImageSource.gallery);
                      },
                    ),
                    _mediaOption(
                      icon: Icons.video_library,
                      label: 'Videos',
                      sublabel: 'Choose video',
                      color: Colors.orange,
                      onTap: () {
                        Navigator.pop(context);
                        _pickVideo(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mediaOption({
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              sublabel,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}