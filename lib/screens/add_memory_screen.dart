import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/memory_model.dart';
import '../../services/memory_service.dart';
import '../../utils/colors.dart';

class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _noteController = TextEditingController();
  final _locationController = TextEditingController();
  final _activityController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  final _service = MemoryService();
  final _picker = ImagePicker();

  String _memoryType = 'photo';
  DateTime _date = DateTime.now();
  List<String> _uploadedUrls = [];
  List<String> _mediaTypes = [];
  bool _uploading = false;
  bool _saving = false;
  bool _favorite = false;
  double _rating = 5.0;

  // ⭐ Capsule
  bool _isCapsule = false;
  DateTime? _capsuleOpenDate;

  final List<String> _activities = [
    'Safari',
    'Beach',
    'Trekking',
    'Culture',
    'Food',
    'Photography',
    'Wildlife',
    'Adventure',
  ];

  // ============================================================
  // PICK + UPLOAD IMAGE
  // ============================================================
  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploading = true);

    String? url;
    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      url = await _service.uploadMemoryImageBytes(bytes);
    } else {
      url = await _service.uploadMemoryImage(File(picked.path));
    }

    if (url != null && mounted) {
      setState(() {
        _uploadedUrls.add(url!);
        _mediaTypes.add('image');
        _uploading = false;
      });
    } else {
      setState(() => _uploading = false);
      _showError('Upload failed');
    }
  }

  // ============================================================
  // SAVE
  // ============================================================
  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a title');
      return;
    }

    if (_uploadedUrls.isEmpty && _memoryType != 'journal') {
      _showError('Please add at least one photo');
      return;
    }

    setState(() => _saving = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final memory = MemoryModel(
      id: '',
      userId: user.uid,
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      note: _noteController.text.trim(),
      memoryType: _memoryType,
      mediaUrls: _uploadedUrls,
      mediaTypes: _mediaTypes,
      thumbnailUrl: _uploadedUrls.isNotEmpty ? _uploadedUrls.first : '',
      location: _locationController.text.trim(),
      latitude: double.tryParse(_latController.text) ?? 0.0,
      longitude: double.tryParse(_lngController.text) ?? 0.0,
      date: _date,
      activity: _activityController.text.trim(),
      rating: _rating,
      favorite: _favorite,
      capsuleOpenDate: _isCapsule ? _capsuleOpenDate : null, // ⭐ ADDED
    );

    final id = await _service.createMemory(memory);
    setState(() => _saving = false);

    if (id != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Memory saved!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      _showError('Failed to save memory');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentGold,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _noteController.dispose();
    _locationController.dispose();
    _activityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
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
          Container(color: Colors.black.withOpacity(0.8)),

          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: EdgeInsets.all(width * 0.04),
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
                          child: const Icon(Icons.close,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      const Text(
                        '✨ New Memory',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                        horizontal: width * 0.04),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Media upload area
                        _buildUploadArea(width),
                        SizedBox(height: width * 0.05),

                        // Title
                        _buildField(_titleController, 'Title',
                            'My first day in Arusha', Icons.title),
                        SizedBox(height: width * 0.03),

                        // Description
                        _buildField(_descController, 'Description',
                            'What happened?', Icons.description,
                            maxLines: 3),
                        SizedBox(height: width * 0.03),

                        // Journal note
                        _buildField(_noteController, 'Personal Note',
                            'How did it feel?', Icons.edit_note,
                            maxLines: 4),
                        SizedBox(height: width * 0.03),

                        // Date
                        _buildDatePicker(width),
                        SizedBox(height: width * 0.03),

                        // Location
                        _buildField(_locationController, 'Location',
                            'Arusha, Tanzania', Icons.location_on),
                        SizedBox(height: width * 0.03),

                        // Coordinates row
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                  _latController,
                                  'Latitude',
                                  '-3.2360',
                                  Icons.my_location,
                                  keyboard: TextInputType.number),
                            ),
                            SizedBox(width: width * 0.03),
                            Expanded(
                              child: _buildField(
                                  _lngController,
                                  'Longitude',
                                  '35.4910',
                                  Icons.my_location,
                                  keyboard: TextInputType.number),
                            ),
                          ],
                        ),
                        SizedBox(height: width * 0.03),

                        // Activity picker
                        _buildActivityPicker(width),
                        SizedBox(height: width * 0.03),

                        // Rating
                        _buildRatingPicker(width),
                        SizedBox(height: width * 0.03),

                        // Favorite toggle
                        _buildFavoriteToggle(width),
                        const SizedBox(height: 16),

                        // ⭐ CAPSULE TOGGLE
                        _buildCapsuleToggle(width),
                        if (_isCapsule) ...[
                          const SizedBox(height: 12),
                          _buildCapsuleDatePicker(width),
                        ],
                        SizedBox(height: width * 0.06),

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _saving || _uploading ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.black,
                                strokeWidth: 2,
                              ),
                            )
                                : const Icon(Icons.save),
                            label: Text(
                              _saving ? 'Saving...' : 'SAVE MEMORY',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 1,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentGold,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
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
  // UPLOAD AREA
  // ============================================================
  Widget _buildUploadArea(double width) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.all(width * 0.04),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.13),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    '📸 Media',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${_uploadedUrls.length} added',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              SizedBox(height: width * 0.03),
              if (_uploadedUrls.isNotEmpty)
                SizedBox(
                  height: width * 0.3,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _uploadedUrls.length,
                    itemBuilder: (context, i) {
                      return Container(
                        margin: EdgeInsets.only(right: width * 0.02),
                        width: width * 0.3,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _uploadedUrls[i],
                                fit: BoxFit.cover,
                                width: width * 0.3,
                                height: width * 0.3,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.white10,
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.white54),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _uploadedUrls.removeAt(i);
                                    _mediaTypes.removeAt(i);
                                  });
                                },
                                child: Container(
                                  padding:
                                  const EdgeInsets.all(4),
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
                        ),
                      );
                    },
                  ),
                ),
              SizedBox(height: width * 0.03),
              GestureDetector(
                onTap: _uploading ? null : _pickImage,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      vertical: width * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.5),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _uploading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.accentGold,
                          strokeWidth: 2,
                        ),
                      )
                          : const Icon(Icons.add_photo_alternate,
                          color: AppColors.accentGold),
                      const SizedBox(width: 8),
                      Text(
                        _uploading ? 'Uploading...' : 'Add Photo',
                        style: const TextStyle(
                          color: AppColors.accentGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController controller,
      String label,
      String hint,
      IconData icon, {
        int maxLines = 1,
        TextInputType keyboard = TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboard,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: AppColors.accentGold),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
          const BorderSide(color: AppColors.accentGold, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDatePicker(double width) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today,
                color: AppColors.accentGold),
            SizedBox(width: width * 0.03),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Date',
                  style:
                  TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  DateFormat('EEEE, dd MMM yyyy').format(_date),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios,
                color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityPicker(double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Activity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: width * 0.02),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _activities.map((a) {
            final selected = _activityController.text == a;
            return GestureDetector(
              onTap: () =>
                  setState(() => _activityController.text = a),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.accentGold
                      : Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? AppColors.accentGold
                        : Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  a,
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.white,
                    fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRatingPicker(double width) {
    return Row(
      children: [
        const Text(
          '⭐ Rating',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        ...List.generate(5, (i) {
          return GestureDetector(
            onTap: () => setState(() => _rating = (i + 1).toDouble()),
            child: Icon(
              i < _rating ? Icons.star : Icons.star_border,
              color: AppColors.accentGold,
              size: 28,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFavoriteToggle(double width) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: width * 0.04, vertical: width * 0.02),
      decoration: BoxDecoration(
        color: _favorite
            ? Colors.red.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _favorite
              ? Colors.red.withOpacity(0.5)
              : Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _favorite ? Icons.favorite : Icons.favorite_border,
            color: _favorite ? Colors.red : Colors.white70,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _favorite
                  ? 'Marked as favorite'
                  : 'Mark as favorite',
              style: TextStyle(
                color: _favorite ? Colors.red : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: _favorite,
            onChanged: (v) => setState(() => _favorite = v),
            activeColor: Colors.red,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CAPSULE TOGGLE
  // ============================================================
  Widget _buildCapsuleToggle(double width) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: width * 0.04, vertical: width * 0.02),
      decoration: BoxDecoration(
        color: _isCapsule
            ? AppColors.accentGold.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isCapsule
              ? AppColors.accentGold.withOpacity(0.6)
              : Colors.white.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isCapsule ? Icons.lock : Icons.lock_open,
            color: _isCapsule ? AppColors.accentGold : Colors.white70,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '🔒 Lock as Capsule',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  _isCapsule
                      ? 'This memory will unlock on the date you choose'
                      : 'Save as a time-locked memory for the future',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isCapsule,
            onChanged: (v) {
              setState(() {
                _isCapsule = v;
                if (v && _capsuleOpenDate == null) {
                  _capsuleOpenDate =
                      DateTime.now().add(const Duration(days: 365 * 5));
                }
              });
            },
            activeColor: AppColors.accentGold,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CAPSULE DATE PICKER
  // ============================================================
  Widget _buildCapsuleDatePicker(double width) {
    return GestureDetector(
      onTap: _pickCapsuleDate,
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: AppColors.accentGold.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accentGold.withOpacity(0.5),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.event, color: AppColors.accentGold),
            SizedBox(width: width * 0.03),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Opens on',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                Text(
                  _capsuleOpenDate != null
                      ? DateFormat('EEEE, dd MMM yyyy').format(_capsuleOpenDate!)
                      : 'Pick a date',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 14),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PICK CAPSULE DATE
  // ============================================================
  Future<void> _pickCapsuleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _capsuleOpenDate ?? now.add(const Duration(days: 365)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(now.year + 50),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accentGold,
              onPrimary: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _capsuleOpenDate = picked);
  }
}