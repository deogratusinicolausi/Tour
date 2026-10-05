import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/memory_model.dart';
import '../../services/memory_service.dart';
import '../../utils/colors.dart';

class MemoryDetailScreen extends StatefulWidget {
  final MemoryModel memory;

  const MemoryDetailScreen({super.key, required this.memory});

  @override
  State<MemoryDetailScreen> createState() => _MemoryDetailScreenState();
}

class _MemoryDetailScreenState extends State<MemoryDetailScreen> {
  final _service = MemoryService();
  late MemoryModel _memory;
  bool get _isLocked => _memory.isCapsuleLocked;

  @override
  void initState() {
    super.initState();
    _memory = widget.memory;

    // Show capsule sheet if memory is locked
    if (_memory.isCapsuleLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showCapsuleSheet());
    }
  }

  Future<void> _openMap() async {
    if (_memory.latitude == 0 && _memory.longitude == 0) return;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${_memory.latitude},${_memory.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Delete memory?',
            style: TextStyle(color: Colors.white)),
        content: const Text('This cannot be undone.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
            const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.deleteMemory(_memory.id);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Hero image as background
          if (_memory.mediaUrls.isNotEmpty)
            Positioned.fill(
              child: Image.network(
                _memory.mediaUrls.first,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.black),
              ),
            ),
          Container(color: Colors.black.withOpacity(0.75)),

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
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white, size: 18),
                        ),
                      ),
                      const Spacer(),
                      // ⭐ CAPSULE INFO BUTTON (if locked)
                      if (_isLocked)
                        GestureDetector(
                          onTap: _showCapsuleSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: AppColors.goldGradient,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, color: Colors.black, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'Capsule',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(width: width * 0.02),
                      GestureDetector(
                        onTap: () async {
                          await _service.toggleFavorite(
                              _memory.id, _memory.favorite);
                          setState(() {
                            _memory =
                                _memory.copyWith(favorite: !_memory.favorite);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _memory.favorite
                                ? Colors.red.withOpacity(0.3)
                                : Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _memory.favorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _memory.favorite
                                ? Colors.red
                                : Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: width * 0.02),
                      GestureDetector(
                        onTap: _confirmDelete,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.delete_outline,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _isLocked
                      ? _buildLockedBody(width, height)
                      : SingleChildScrollView(
                          padding: EdgeInsets.symmetric(
                        horizontal: width * 0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          _memory.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.08,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: height * 0.01),

                        // Date + Location
                        Row(
                          children: [
                            const Icon(Icons.calendar_today,
                                color: AppColors.accentGold, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _memory.formattedDate,
                              style: const TextStyle(
                                color: AppColors.accentGold,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_memory.location.isNotEmpty) ...[
                              const SizedBox(width: 16),
                              const Icon(Icons.location_on,
                                  color: AppColors.accentGold, size: 16),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  _memory.location,
                                  style: const TextStyle(
                                      color: Colors.white70),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),

                        SizedBox(height: height * 0.025),

                        // Media gallery
                        if (_memory.mediaUrls.length > 1)
                          SizedBox(
                            height: height * 0.15,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _memory.mediaUrls.length,
                              itemBuilder: (context, i) => Container(
                                margin:
                                EdgeInsets.only(right: width * 0.03),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    _memory.mediaUrls[i],
                                    fit: BoxFit.cover,
                                    width: height * 0.15,
                                    height: height * 0.15,
                                    errorBuilder: (_, __, ___) =>
                                        Container(
                                          color: Colors.white10,
                                          child: const Icon(
                                              Icons.broken_image,
                                              color: Colors.white54),
                                        ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: height * 0.02),

                        // Description
                        if (_memory.description.isNotEmpty) ...[
                          const Text(
                            '📖 About',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _memory.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.6,
                            ),
                          ),
                          SizedBox(height: height * 0.025),
                        ],

                        // Journal note
                        if (_memory.note.isNotEmpty) ...[
                          const Text(
                            '✍️ Journal',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.all(width * 0.04),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accentGold
                                    .withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              _memory.note,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                height: 1.6,
                              ),
                            ),
                          ),
                          SizedBox(height: height * 0.025),
                        ],

                        // Activity + Rating chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (_memory.activity.isNotEmpty)
                              _chip('🎯 ${_memory.activity}'),
                            if (_memory.rating > 0)
                              _chip('⭐ ${_memory.rating.toStringAsFixed(1)}'),
                            if (_memory.memoryType.isNotEmpty)
                              _chip('📸 ${_memory.memoryType.toUpperCase()}'),
                          ],
                        ),

                        SizedBox(height: height * 0.03),

                        // Map button
                        if (_memory.latitude != 0 ||
                            _memory.longitude != 0)
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _openMap,
                              icon: const Icon(Icons.map),
                              label: const Text('VIEW ON MAP'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentGold,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
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

  Widget _buildLockedBody(double width, double height) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(width * 0.1),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.6),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(Icons.lock, color: Colors.black, size: 60),
            ),
            SizedBox(height: height * 0.05),
            Text(
              _memory.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: height * 0.02),
            const Text(
              'This memory is time-locked',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 15,
              ),
            ),
            SizedBox(height: height * 0.03),
            Container(
              padding: EdgeInsets.symmetric(horizontal: width * 0.08, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.accentGold.withOpacity(0.6),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'OPENS ON',
                    style: TextStyle(
                      color: AppColors.accentGold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _memory.capsuleOpenDate != null
                        ? DateFormat('MMMM dd, yyyy').format(_memory.capsuleOpenDate!)
                        : '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_daysUntilUnlock()} days from now',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: height * 0.04),
            ElevatedButton.icon(
              onPressed: _showCapsuleSheet,
              icon: const Icon(Icons.info_outline),
              label: const Text('CAPSULE OPTIONS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.15),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: AppColors.accentGold.withOpacity(0.5)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  // ============================================================ // ⭐ CAPSULE INFO + CONTROLS SHEET // ============================================================
  void _showCapsuleSheet() {
    final width = MediaQuery.of(context).size.width;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.all(width * 0.06),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              border: Border(
                top: BorderSide(
                  color: AppColors.accentGold.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                // Lock icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentGold.withOpacity(0.6),
                        blurRadius: 30,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock, color: Colors.black, size: 40),
                ),
                const SizedBox(height: 20),

                const Text(
                  'Time Capsule Locked',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'This memory will unlock on',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _memory.capsuleOpenDate != null
                      ? DateFormat('EEEE, MMMM dd, yyyy')
                          .format(_memory.capsuleOpenDate!)
                      : 'Unknown date',
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // Days remaining
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.06, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accentGold.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule,
                          color: AppColors.accentGold, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_daysUntilUnlock()} days remaining',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Owner can unlock early
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _confirmEarlyUnlock();
                    },
                    icon: const Icon(Icons.lock_open),
                    label: const Text('UNLOCK NOW (Owner)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.15),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: AppColors.accentGold.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Extend date
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _pickNewCapsuleDate();
                    },
                    icon: const Icon(Icons.edit_calendar),
                    label: const Text('CHANGE UNLOCK DATE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.1),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close Viewer',
                      style: TextStyle(color: Colors.white54)),
                ),
                SizedBox(height: width * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _daysUntilUnlock() {
    if (_memory.capsuleOpenDate == null) return 0;
    return _memory.capsuleOpenDate!.difference(DateTime.now()).inDays;
  }

  // ============================================================ // ⭐ EARLY UNLOCK CONFIRMATION // ============================================================
  Future<void> _confirmEarlyUnlock() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 10),
            Text(
              'Unlock capsule?',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: const Text(
          'This will permanently unlock the memory. You can re-lock it later.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Unlock',
              style: TextStyle(
                color: AppColors.accentGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Remove capsule lock
      final updated = _memory.copyWith(
        capsuleOpenDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      await _service.updateMemory(updated);
      if (mounted) {
        setState(() => _memory = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔓 Capsule unlocked!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else if (_isLocked) {
      _showCapsuleSheet();
    }
  }

  // ============================================================ // ⭐ PICK NEW CAPSULE DATE // ============================================================
  Future<void> _pickNewCapsuleDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _memory.capsuleOpenDate ?? now.add(const Duration(days: 365)),
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

    if (picked != null) {
      final updated = _memory.copyWith(capsuleOpenDate: picked);
      await _service.updateMemory(updated);
      if (mounted) {
        setState(() => _memory = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '📅 Unlock date set to ${DateFormat('MMM dd, yyyy').format(picked)}'),
            backgroundColor: AppColors.accentGold,
          ),
        );
        _showCapsuleSheet();
      }
    } else if (_isLocked) {
      _showCapsuleSheet();
    }
  }
}