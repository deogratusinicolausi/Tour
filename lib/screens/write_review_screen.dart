import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/review_model.dart';
import '../services/cloudinary_service.dart';
import '../services/review_service.dart';
import '../utils/colors.dart';
import '../widgets/review_card_widget.dart';

class WriteReviewScreen extends StatefulWidget {
  final String itemId;
  final String itemType;
  final String itemName;

  const WriteReviewScreen({
    super.key,
    required this.itemId,
    required this.itemType,
    required this.itemName,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reviewService = ReviewService();
  final _cloudinary = CloudinaryService();
  final _user = FirebaseAuth.instance.currentUser;

  final _titleController = TextEditingController();
  final _commentController = TextEditingController();

  double _rating = 0.0;
  List<String> _photos = [];
  bool _isLoading = false;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    if (_photos.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Max 5 photos')),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 75,
      );
      if (pickedFile == null) return;
      setState(() => _isUploading = true);

      String? url;
      if (kIsWeb) {
        Uint8List bytes = await pickedFile.readAsBytes();
        url = await _cloudinary.uploadImageBytes(bytes,
            folder: 'turiva/reviews');
      } else {
        url = await _cloudinary.uploadImage(File(pickedFile.path),
            folder: 'turiva/reviews');
      }

      setState(() {
        if (url != null) _photos.add(url);
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_user == null) return;
    setState(() => _isLoading = true);

    final bookingId = await _reviewService.getVerifiedBooking(
      _user!.uid,
      widget.itemId,
    );

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user!.uid)
        .get();
    final userName =
        userDoc.data()?['name'] ?? _user!.displayName ?? 'User';
    final userPhoto = userDoc.data()?['photoUrl'] ?? '';

    final review = ReviewModel(
      id: '',
      itemId: widget.itemId,
      itemType: widget.itemType,
      itemName: widget.itemName,
      userId: _user!.uid,
      userName: userName,
      userPhoto: userPhoto,
      rating: _rating,
      title: _titleController.text.trim(),
      comment: _commentController.text.trim(),
      photos: _photos,
      verified: bookingId != null,
      bookingId: bookingId ?? '',
    );

    final id = await _reviewService.addReview(review);
    setState(() => _isLoading = false);

    if (mounted && id != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Review submitted! Thank you.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to submit review'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  String get _ratingText {
    if (_rating == 0) return 'Tap to rate';
    if (_rating <= 1) return '😞 Poor';
    if (_rating <= 2) return '😕 Fair';
    if (_rating <= 3) return '😐 Good';
    if (_rating <= 4) return '😊 Very Good';
    return '🤩 Excellent!';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ===== BACKGROUND IMAGE =====
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // ===== DARK OVERLAY =====
          Container(color: Colors.black.withOpacity(0.75)),

          // ===== CONTENT =====
          SafeArea(
            child: Column(
              children: [
                // ===== GLASS APP BAR =====
                _buildGlassAppBar(context, width),

                // ===== FORM =====
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.04,
                        vertical: height * 0.01,
                      ),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        // ===== ITEM INFO CARD =====
                        _glassCard(
                          width: width,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reviewing',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: width * 0.028,
                                ),
                              ),
                              SizedBox(height: height * 0.005),
                              Text(
                                widget.itemName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.042,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: height * 0.008),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentGold
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppColors.accentGold
                                        .withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  widget.itemType.toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.accentGold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: height * 0.02),

                        // ===== RATING CARD =====
                        _glassCard(
                          width: width,
                          child: Column(
                            children: [
                              Text(
                                'How was your experience?',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: width * 0.042,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: height * 0.02),
                              StarPicker(
                                rating: _rating,
                                onChanged: (v) =>
                                    setState(() => _rating = v),
                              ),
                              SizedBox(height: height * 0.015),
                              Text(
                                _ratingText,
                                style: TextStyle(
                                  fontSize: width * 0.045,
                                  fontWeight: FontWeight.bold,
                                  color: _rating > 0
                                      ? AppColors.accentGold
                                      : Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: height * 0.025),

                        // ===== TITLE =====
                        _labelText('📝 Review Title (Optional)', width),
                        SizedBox(height: height * 0.01),
                        _glassTextField(
                          controller: _titleController,
                          hint: 'e.g. Amazing experience!',
                          width: width,
                          height: height,
                        ),

                        SizedBox(height: height * 0.025),

                        // ===== COMMENT =====
                        _labelText('💬 Your Review', width),
                        SizedBox(height: height * 0.01),
                        _glassTextField(
                          controller: _commentController,
                          hint:
                          'Share your experience... What did you like? What could be better?',
                          width: width,
                          height: height,
                          maxLines: 6,
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Please write a review';
                            }
                            if (v.length < 10) {
                              return 'At least 10 characters';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: height * 0.025),

                        // ===== PHOTOS =====
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            _labelText('📸 Add Photos', width),
                            Text(
                              '${_photos.length}/5',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: width * 0.032,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: height * 0.01),
                        SizedBox(
                          height: height * 0.12,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _photos.length + 1,
                            itemBuilder: (context, i) {
                              if (i == _photos.length) {
                                return GestureDetector(
                                  onTap: _isUploading
                                      ? null
                                      : _pickImage,
                                  child: ClipRRect(
                                    borderRadius:
                                    BorderRadius.circular(12),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                          sigmaX: 12, sigmaY: 12),
                                      child: Container(
                                        width: height * 0.12,
                                        margin: EdgeInsets.only(
                                            right: width * 0.02),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withOpacity(0.15),
                                          borderRadius:
                                          BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.white
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        child: _isUploading
                                            ? const Center(
                                          child:
                                          CircularProgressIndicator(
                                            color: AppColors
                                                .accentGold,
                                          ),
                                        )
                                            : Icon(
                                          Icons
                                              .add_photo_alternate,
                                          color:
                                          Colors.white70,
                                          size: width * 0.08,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                              return Stack(
                                children: [
                                  Container(
                                    width: height * 0.12,
                                    margin: EdgeInsets.only(
                                        right: width * 0.02),
                                    decoration: BoxDecoration(
                                      borderRadius:
                                      BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.white
                                            .withOpacity(0.3),
                                      ),
                                      image: DecorationImage(
                                        image:
                                        NetworkImage(_photos[i]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(
                                              () => _photos.removeAt(i)),
                                      child: Container(
                                        padding:
                                        const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.white,
                                            size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        SizedBox(height: height * 0.04),

                        // ===== SUBMIT BUTTON =====
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 6,
                              shadowColor: AppColors.accentGold
                                  .withOpacity(0.6),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                color: Colors.black)
                                : const Text(
                              'SUBMIT REVIEW',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: height * 0.05),
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

  // ============================================================
  // GLASS APP BAR
  // ============================================================
  Widget _buildGlassAppBar(BuildContext context, double width) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.03,
        vertical: width * 0.02,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: width * 0.02,
              vertical: width * 0.02,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
                SizedBox(width: width * 0.03),
                const Expanded(
                  child: Text(
                    '⭐ Write Review',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPER: glass card
  // ============================================================
  Widget _glassCard({
    required double width,
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.all(width * 0.05),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  // ============================================================
  // HELPER: glass text field
  // ============================================================
  Widget _glassTextField({
    required TextEditingController controller,
    required String hint,
    required double width,
    required double height,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          cursorColor: AppColors.accentGold,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.white.withOpacity(0.12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.white.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: AppColors.accentGold, width: 1.5),
            ),
            contentPadding: EdgeInsets.all(width * 0.04),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HELPER: label text
  // ============================================================
  Widget _labelText(String text, double width) {
    return Text(
      text,
      style: TextStyle(
        fontSize: width * 0.04,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }
}