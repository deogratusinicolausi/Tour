import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../models/review_model.dart';
import '../services/review_service.dart';
import '../services/cloudinary_service.dart';
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

    // Check if user has verified booking
    final bookingId = await _reviewService.getVerifiedBooking(
      _user!.uid,
      widget.itemId,
    );

    // Get user name
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('⭐ Write Review'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(width * 0.05),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item info
              Container(
                padding: EdgeInsets.all(width * 0.04),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reviewing',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: width * 0.028,
                      ),
                    ),
                    SizedBox(height: height * 0.005),
                    Text(
                      widget.itemName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.042,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    SizedBox(height: height * 0.005),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.itemType.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: height * 0.03),

              // Rating
              Container(
                padding: EdgeInsets.all(width * 0.05),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'How was your experience?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.042,
                        color: Colors.grey.shade900,
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                    StarPicker(
                      rating: _rating,
                      onChanged: (v) => setState(() => _rating = v),
                    ),
                    SizedBox(height: height * 0.015),
                    Text(
                      _ratingText,
                      style: TextStyle(
                        fontSize: width * 0.045,
                        fontWeight: FontWeight.bold,
                        color: _rating > 0
                            ? AppColors.accentGold
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: height * 0.025),

              // Title
              Text(
                '📝 Review Title (Optional)',
                style: TextStyle(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: height * 0.01),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'e.g. Amazing experience!',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),

              SizedBox(height: height * 0.025),

              // Comment
              Text(
                '💬 Your Review',
                style: TextStyle(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
              SizedBox(height: height * 0.01),
              TextFormField(
                controller: _commentController,
                maxLines: 6,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please write a review';
                  if (v.length < 10) return 'At least 10 characters';
                  return null;
                },
                decoration: InputDecoration(
                  hintText:
                  'Share your experience... What did you like? What could be better?',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
              ),

              SizedBox(height: height * 0.025),

              // Photos
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '📸 Add Photos',
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  Text(
                    '${_photos.length}/5',
                    style: TextStyle(
                      color: Colors.grey.shade500,
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
                        onTap: _isUploading ? null : _pickImage,
                        child: Container(
                          width: height * 0.12,
                          margin: EdgeInsets.only(right: width * 0.02),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border:
                            Border.all(color: Colors.grey.shade300),
                          ),
                          child: _isUploading
                              ? const Center(
                              child: CircularProgressIndicator())
                              : Icon(Icons.add_photo_alternate,
                              color: Colors.grey.shade400,
                              size: width * 0.08),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Container(
                          width: height * 0.12,
                          margin: EdgeInsets.only(right: width * 0.02),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: NetworkImage(_photos[i]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _photos.removeAt(i)),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              SizedBox(height: height * 0.04),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    'SUBMIT REVIEW',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
    );
  }
}