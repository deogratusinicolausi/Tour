import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // for HapticFeedback
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/wishlist_service.dart';
import '../services/firestore_service.dart';
import '../services/air_zoom_service.dart';
import '../utils/colors.dart';
import 'map_screen.dart';
import 'booking_screen.dart';

class DestinationDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> destination;

  const DestinationDetailsScreen({super.key, required this.destination});

  @override
  State<DestinationDetailsScreen> createState() =>
      _DestinationDetailsScreenState();
}

class _DestinationDetailsScreenState extends State<DestinationDetailsScreen> {
  final _wishlistService = WishlistService();
  final _firestoreService = FirestoreService();
  final _firestore = FirebaseFirestore.instance;
  final User? _user = FirebaseAuth.instance.currentUser;

  bool _isLiked = false;
  int _currentImageIndex = 0;
  int _viewCount = 0;

  // ⭐ Guard so we don't double-log on rebuild
  bool _viewLogged = false;

  // ⭐ REVIEW STATE
  bool _hasUserReviewed = false;
  String? _userReviewId;

  // ⭐ Highlight selections
  final Set<String> _selectedHighlights = {};
  String? _selectedBestTime;
  String? _selectedType;

  // Firestore subcollection path helper
  String get _highlightDocPath {
    final uid = _user?.uid ?? 'guest';
    final destId = widget.destination['id'];
    return 'user_preferences/$uid/destinations/$destId';
  }

  @override
  void initState() {
    super.initState();
    _viewCount = (widget.destination['views'] ?? 0) as int;
    _checkLiked();
    _checkUserReview(); // ⭐ NEW
    _loadHighlightSelections(); // ⭐ NEW
    WidgetsBinding.instance.addPostFrameCallback((_) => _registerView());
  }

  // ⭐ Single, safe view registration (log + increment in one pass)
  Future<void> _registerView() async {
    if (_viewLogged) return;
    _viewLogged = true;

    final id = widget.destination['id']?.toString();
    if (id == null || id.isEmpty) return;

    try {
      final ref = _firestore.collection('destinations').doc(id);
      final snap = await ref.get();

      if (snap.exists) {
        final current = (snap.data()?['views'] ?? 0) as int;
        await ref.update({
          'views': current + 1,
          'lastViewedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) setState(() => _viewCount = current + 1);
      } else {
        // Doc may live in featured_destinations only — silently skip
        if (mounted) setState(() => _viewCount = _viewCount + 1);
      }

      // Admin activity log
      await _firestore.collection('activities').add({
        'type': 'view',
        'action': 'viewed',
        'title': 'Viewed: ${widget.destination['name']}',
        'description':
        '${_user?.displayName ?? 'Guest'} viewed this destination',
        'userId': _user?.uid ?? 'guest',
        'userName': _user?.displayName ?? 'Guest',
        'itemId': id,
        'itemType': 'destination',
        'icon': '👁️',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('🔥 view register error: $e');
    }
  }

  // ===== Load saved highlights for this user + destination =====
  Future<void> _loadHighlightSelections() async {
    if (_user == null) return;
    try {
      final doc = await _firestore.doc(_highlightDocPath).get();
      if (doc.exists) {
        final saved = (doc.data()?['highlights'] as List?) ?? [];
        if (mounted) {
          setState(() {
            _selectedHighlights
              ..clear()
              ..addAll(saved.map((e) => e.toString()));
          });
        }
      }
    } catch (e) {
      debugPrint('🔥 load highlights: $e');
    }
  }

  // ===== Save highlights silently =====
  Future<void> _saveHighlightSelections() async {
    if (_user == null) return;
    try {
      await _firestore.doc(_highlightDocPath).set({
        'highlights': _selectedHighlights.toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('🔥 save highlights: $e');
    }
  }

  // ===== Toggle a highlight =====
  void _toggleHighlight(String label) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedHighlights.contains(label)) {
        _selectedHighlights.remove(label);
      } else {
        _selectedHighlights.add(label);
      }
    });
    _saveHighlightSelections();
  }

  // ===== Clear all highlights =====
  void _clearHighlights() {
    HapticFeedback.mediumImpact();
    setState(() => _selectedHighlights.clear());
    _saveHighlightSelections();
  }

  Future<void> _checkLiked() async {
    if (_user == null) return;
    try {
      final liked = await _wishlistService.isLiked(
        _user!.uid,
        widget.destination['id'],
      );
      if (mounted) setState(() => _isLiked = liked);
    } catch (e) {
      debugPrint('🔥 checkLiked: $e');
    }
  }

  Future<void> _toggleLike() async {
    if (_user == null) {
      _snack('Please login first', Colors.orange);
      return;
    }
    try {
      final wasAdded = await _wishlistService.addToWishlist(
        userId: _user!.uid,
        itemId: widget.destination['id'],
        itemType: 'destination',
        itemName: widget.destination['name'] ?? '',
        itemImage: widget.destination['imageUrl'] ?? '',
        price: 0,
        currency: 'USD',
      );

      if (wasAdded) {
        await _firestore.collection('activities').add({
          'type': 'wishlist',
          'action': 'liked',
          'title': 'Liked: ${widget.destination['name']}',
          'description':
          '${_user!.displayName ?? 'User'} liked this destination',
          'userId': _user!.uid,
          'userName': _user!.displayName ?? 'User',
          'itemId': widget.destination['id'],
          'itemType': 'destination',
          'icon': '❤️',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        setState(() => _isLiked = wasAdded);
        _snack(wasAdded ? '❤️ Added to wishlist' : '💔 Removed',
            wasAdded ? Colors.red : Colors.grey);
      }
    } catch (e) {
      debugPrint('🔥 toggleLike: $e');
    }
  }

  Future<void> _shareDestination() async {
    final id = widget.destination['id'];
    final uri = Uri.parse('https://turiva.app/destination/$id');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      await _firestore.collection('activities').add({
        'type': 'share',
        'action': 'shared',
        'title': 'Shared: ${widget.destination['name']}',
        'description': '${_user?.displayName ?? 'Guest'} shared this',
        'userId': _user?.uid ?? 'guest',
        'userName': _user?.displayName ?? 'Guest',
        'itemId': id,
        'itemType': 'destination',
        'icon': '📤',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('🔥 share: $e');
    }
  }

  Future<void> _openMap() async {
    final dest = widget.destination;

    final double? lat = (dest['latitude'] is num)
        ? (dest['latitude'] as num).toDouble()
        : null;
    final double? lng = (dest['longitude'] is num)
        ? (dest['longitude'] as num).toDouble()
        : null;

    final String name = (dest['name'] ?? '').toString().trim();
    final String location = (dest['location'] ?? '').toString().trim();
    final String country = (dest['country'] ?? '').toString().trim();

    Uri uri;

    // ✅ Kipaumbele 1: Coordinates halisi (pin sahihi)
    if (lat != null && lng != null && (lat != 0 || lng != 0)) {
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
      );
    }
    // ✅ Kipaumbele 2: Jina + location + country
    else if (name.isNotEmpty) {
      final q = Uri.encodeComponent(
        [name, location, country].where((s) => s.isNotEmpty).join(', '),
      );
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$q',
      );
    }
    // ❌ Hakuna kitu cha kutumia
    else {
      _snack('Location haipo kwa destination hii', Colors.orange);
      return;
    }

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Log activity kwa admin
        try {
          await _firestore.collection('activities').add({
            'type': 'map',
            'action': 'opened',
            'title': 'Opened map: $name',
            'description':
                '${_user?.displayName ?? 'Guest'} opened map',
            'userId': _user?.uid ?? 'guest',
            'userName': _user?.displayName ?? 'Guest',
            'itemId': dest['id'],
            'itemType': 'destination',
            'icon': '📍',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } catch (_) {}
      } else {
        _snack('Imeshindwa kufungua Google Maps', Colors.red);
      }
    } catch (e) {
      debugPrint('🔥 openMap: $e');
      _snack('Hitilafu wakati wa kufungua ramani', Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<String> get _allImages {
    final set = <String>{};
    final hero = (widget.destination['imageUrl'] ?? '').toString();
    if (hero.isNotEmpty) set.add(hero);

    final gallery = widget.destination['gallery'];
    if (gallery is List) {
      for (final img in gallery) {
        final s = img.toString();
        if (s.isNotEmpty) set.add(s);
      }
    }
    return set.toList();
  }

  List<String> get _allVideos {
    final v = widget.destination['videos'];
    if (v is! List) return [];
    return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  Future<void> _playVideo(String url) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _VideoPlayerScreen(videoUrl: url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    final images = _allImages;
    final heroTag = 'dest_${widget.destination['id']}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ===== IMAGE HEADER =====
          SliverAppBar(
            expandedHeight: height * 0.42,
            pinned: true,
            stretch: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            leading: _circleBtn(
              icon: Icons.arrow_back,
              onTap: () => Navigator.pop(context),
            ),
            actions: [
              _circleBtn(
                icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                color: _isLiked ? Colors.red : Colors.white,
                onTap: _toggleLike,
              ),
              _circleBtn(icon: Icons.share, onTap: _shareDestination),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  images.isEmpty
                      ? Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.image,
                        size: 80, color: Colors.white),
                  )
                      : Hero(
                    tag: heroTag,
                    child: PageView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: images.length,
                      onPageChanged: (i) =>
                          setState(() => _currentImageIndex = i),
                      itemBuilder: (context, i) {
                        return GestureDetector(
                          onTap: () => _openFullscreen(images, i),
                          child: CachedNetworkImage(
                            imageUrl: images[i],
                            fit: BoxFit.cover,
                            fadeInDuration:
                            const Duration(milliseconds: 250),
                            placeholder: (_, __) => Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image,
                                  size: 80, color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Gradient overlay
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.35),
                              Colors.transparent,
                              Colors.black.withOpacity(0.55),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            stops: const [0.0, 0.5, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Image counter
                  if (images.length > 1)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: _pill(
                        child: Text(
                          '${_currentImageIndex + 1} / ${images.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  // Dots
                  if (images.length > 1)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(images.length, (i) {
                          final active = i == _currentImageIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin:
                            const EdgeInsets.symmetric(horizontal: 3),
                            width: active ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.accentGold
                                  : Colors.white70,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ),

                  // View count
                  Positioned(
                    top: 80,
                    right: 16,
                    child: _pill(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility,
                              color: Colors.white, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$_viewCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
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

          // ===== CONTENT =====
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE + RATING
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.destination['name'] ?? 'Unnamed',
                          style: TextStyle(
                            fontSize: width * 0.07,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                      if ((widget.destination['rating'] ?? 0) is num &&
                          (widget.destination['rating'] as num) > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                            AppColors.accentGold.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star,
                                  color: AppColors.accentGold, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                (widget.destination['rating'] as num)
                                    .toStringAsFixed(1),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: height * 0.015),

                  // LOCATION
                  Row(
                    children: [
                      Icon(Icons.location_on,
                          color: AppColors.primary, size: width * 0.05),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: Text(
                          [
                            widget.destination['location'],
                            widget.destination['country'],
                          ]
                              .where((e) =>
                          e != null && e.toString().isNotEmpty)
                              .join(', '),
                          style: TextStyle(
                            fontSize: width * 0.038,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.02),

                  // FEATURED BADGE
                  if (widget.destination['featured'] == true)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 16, color: Colors.black),
                          SizedBox(width: 5),
                          Text(
                            'FEATURED DESTINATION',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: height * 0.025),

                  // DESCRIPTION
                  _sectionTitle('📖 About', width),
                  SizedBox(height: height * 0.01),
                  Text(
                    widget.destination['description'] ??
                        'No description available.',
                    style: TextStyle(
                      fontSize: width * 0.037,
                      color: Colors.grey.shade700,
                      height: 1.6,
                    ),
                  ),

                  SizedBox(height: height * 0.025),

                  // INFO CARDS
                  Row(
                    children: [
                      _selectableInfoCard(
                        icon: Icons.calendar_today,
                        label: 'Best Time',
                        value: widget.destination['bestTime'] ?? 'All Year',
                        color: Colors.blue,
                        width: width,
                        isSelected: _selectedBestTime == 'Best Time',
                        onTap: () {
                          setState(() {
                            _selectedBestTime =
                                _selectedBestTime == 'Best Time' ? null : 'Best Time';
                          });
                        },
                      ),
                      SizedBox(width: width * 0.03),
                      _selectableInfoCard(
                        icon: Icons.people,
                        label: 'Type',
                        value: widget.destination['type'] ?? 'Adventure',
                        color: Colors.orange,
                        width: width,
                        isSelected: _selectedType == 'Type',
                        onTap: () {
                          setState(() {
                            _selectedType = _selectedType == 'Type' ? null : 'Type';
                          });
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.025),

                  if (_selectedHighlights.isNotEmpty ||
                      _selectedBestTime != null ||
                      _selectedType != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, color: Colors.blue, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${_selectedHighlights.length + (_selectedBestTime != null ? 1 : 0) + (_selectedType != null ? 1 : 0)} selected',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedHighlights.clear();
                                _selectedBestTime = null;
                                _selectedType = null;
                              });
                            },
                            child: const Text(
                              'Clear',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: height * 0.02),
                  ],

                  // HIGHLIGHTS
                  Row(
                    children: [
                      _sectionTitle('✨ Highlights', width),
                      const Spacer(),
                      if (_selectedHighlights.isNotEmpty)
                        GestureDetector(
                          onTap: _clearHighlights,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.blue.withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.close, size: 14, color: Colors.blue),
                                const SizedBox(width: 4),
                                Text(
                                  'Clear (${_selectedHighlights.length})',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: height * 0.01),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ((widget.destination['highlights'] as List?) ??
                        const [
                          '🦁 Wildlife',
                          '📸 Photography',
                          '🚶 Walking',
                          '🏕️ Camping',
                          '🧗 Adventure',
                        ]).map((h) {
                      final label = h.toString();
                      final selected = _selectedHighlights.contains(label);
                      return GestureDetector(
                        onTap: () => _toggleHighlight(label),
                        child: _highlightChip(label, selected: selected),
                      );
                    }).toList(),
                  ),

                  SizedBox(height: height * 0.025),

                  // GALLERY
                  if (images.length > 1) ...[
                    _sectionTitle('📸 Gallery', width),
                    SizedBox(height: height * 0.01),
                    SizedBox(
                      height: height * 0.12,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        itemBuilder: (context, i) {
                          return GestureDetector(
                            onTap: () => _openFullscreen(images, i),
                            child: Container(
                              margin: EdgeInsets.only(right: width * 0.03),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Stack(
                                  children: [
                                    CachedNetworkImage(
                                      imageUrl: images[i],
                                      width: height * 0.12,
                                      height: height * 0.12,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          Container(
                                            color: Colors.grey.shade200,
                                            child: const Icon(
                                                Icons.broken_image),
                                          ),
                                    ),
                                    if (i == _currentImageIndex)
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: AppColors.primary,
                                              width: 3,
                                            ),
                                            borderRadius:
                                            BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // VIDEOS
                  if (_allVideos.isNotEmpty) ...[
                    _sectionTitle('🎥 Videos', width),
                    SizedBox(height: height * 0.01),
                    SizedBox(
                      height: height * 0.22,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _allVideos.length,
                        itemBuilder: (context, i) {
                          return GestureDetector(
                            onTap: () => _playVideo(_allVideos[i]),
                            child: Container(
                              width: width * 0.7,
                              margin:
                              EdgeInsets.only(right: width * 0.03),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      color: Colors.black87,
                                      child: Center(
                                        child: Icon(
                                            Icons.play_circle_fill,
                                            color: Colors.white
                                                .withOpacity(0.9),
                                            size: width * 0.15),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: _pill(
                                      child: const Text(
                                        '▶ Tap to play',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 11),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: height * 0.025),
                  ],

                  // SINGLE VIDEO
                  if ((widget.destination['videoUrl'] ?? '')
                      .toString()
                      .isNotEmpty) ...[
                    _sectionTitle('🎬 Video', width),
                    SizedBox(height: height * 0.01),
                    _buildVideoPlayer(widget.destination['videoUrl']),
                    SizedBox(height: height * 0.025),
                  ],

                  // MAP
                  _sectionTitle('📍 Location', width),
                  SizedBox(height: height * 0.01),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MapScreen(
                            destinationLat: (widget.destination['latitude'] as num?)?.toDouble(),
                            destinationLng: (widget.destination['longitude'] as num?)?.toDouble(),
                            destinationName: widget.destination['name'] ?? 'Destination',
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'View on Map',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: height * 0.025),

                  // ===== REVIEWS (REAL-TIME) =====
                  StreamBuilder<QuerySnapshot>(
                    stream: _reviewsStream(),
                    builder: (context, snapshot) {
                      final docs = snapshot.data?.docs ?? [];

                      // Calculate average
                      double avg = 0;
                      if (docs.isNotEmpty) {
                        double sum = 0;
                        for (final d in docs) {
                          final data = d.data() as Map<String, dynamic>;
                          sum += ((data['rating'] ?? 0) as num).toDouble();
                        }
                        avg = sum / docs.length;
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ===== HEADER =====
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    _sectionTitle('⭐ Reviews', width),
                                    SizedBox(width: width * 0.02),
                                    if (docs.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentGold.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star,
                                                color: AppColors.accentGold, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              avg.toStringAsFixed(1),
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              ' (${docs.length})',
                                              style: TextStyle(
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _openWriteReviewSheet,
                                icon: Icon(
                                  _hasUserReviewed ? Icons.edit : Icons.rate_review,
                                  size: 16,
                                  color: Colors.blue,
                                ),
                                label: Text(
                                  _hasUserReviewed ? 'Edit' : 'Write',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.012),

                          // ===== LOADING =====
                          if (snapshot.connectionState == ConnectionState.waiting)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )

                          // ===== EMPTY =====
                          else if (docs.isEmpty)
                            Container(
                              padding: EdgeInsets.all(width * 0.06),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.rate_review_outlined,
                                      size: width * 0.12, color: Colors.grey.shade400),
                                  SizedBox(height: height * 0.012),
                                  Text(
                                    'No reviews yet',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: width * 0.04,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  SizedBox(height: height * 0.005),
                                  Text(
                                    'Be the first to share your experience!',
                                    style: TextStyle(
                                      fontSize: width * 0.032,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  SizedBox(height: height * 0.015),
                                  TextButton.icon(
                                    onPressed: _openWriteReviewSheet,
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: const Text('Write a review'),
                                  ),
                                ],
                              ),
                            )

                          // ===== REVIEW LIST =====
                          else
                            ...docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final isMine = data['userId'] == _user?.uid;
                              return _buildReviewFromDoc(data, isMine, width);
                            }).toList(),
                        ],
                      );
                    },
                  ),

                  SizedBox(height: height * 0.025),

                  // SIMILAR DESTINATIONS
                  _sectionTitle('🎯 Similar Destinations', width),
                  SizedBox(height: height * 0.01),
                  SizedBox(
                    height: height * 0.2,
                    child: StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _firestoreService.getDestinations(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator(
                                  strokeWidth: 2));
                        }
                        final all = snapshot.data ?? [];
                        final similar = all
                            .where((d) =>
                        d['id'] != widget.destination['id'])
                            .take(8)
                            .toList();

                        if (similar.isEmpty) {
                          return Center(
                            child: Text(
                              'No similar destinations',
                              style:
                              TextStyle(color: Colors.grey.shade500),
                            ),
                          );
                        }

                        return ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: similar.length,
                          itemBuilder: (context, i) {
                            final dest = similar[i];
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        DestinationDetailsScreen(
                                            destination: dest),
                                  ),
                                );
                              },
                              child: Container(
                                width: width * 0.4,
                                margin:
                                EdgeInsets.only(right: width * 0.03),
                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(14),
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        dest['imageUrl'] ?? ''),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius:
                                    BorderRadius.circular(14),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                  child: Padding(
                                    padding:
                                    EdgeInsets.all(width * 0.03),
                                    child: Column(
                                      mainAxisAlignment:
                                      MainAxisAlignment.end,
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          dest['name'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          dest['country'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
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
                      },
                    ),
                  ),

                  SizedBox(height: height * 0.03),

                  // ACTION BUTTONS
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _toggleLike,
                        child: Container(
                          padding: EdgeInsets.all(width * 0.04),
                          decoration: BoxDecoration(
                            color: _isLiked
                                ? Colors.red.withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _isLiked
                                  ? Colors.red
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isLiked
                                ? Colors.red
                                : Colors.grey.shade600,
                            size: width * 0.07,
                          ),
                        ),
                      ),
                      SizedBox(width: width * 0.03),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingScreen(
                                  itemType: 'destination',
                                  itemId: widget.destination['id'],
                                  itemName:
                                  widget.destination['name'] ?? '',
                                  itemImage: widget
                                      .destination['imageUrl'] ??
                                      '',
                                  price: 0,
                                  currency: 'USD',
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                vertical: height * 0.022),
                            decoration: BoxDecoration(
                              gradient: AppColors.mainGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                'BOOK NOW',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: height * 0.05),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============ HELPERS ============

  void _openFullscreen(List<String> images, int index) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (_, __, ___) => FullscreenImageViewer(
          imageUrls: images,
          initialIndex: index,
        ),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      onPressed: onTap,
    );
  }

  Widget _pill({required Widget child}) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _highlightChip(String label, {bool selected = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.blue : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected
              ? Colors.blue.shade700
              : AppColors.primary.withOpacity(0.3),
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected) ...[
            const Icon(Icons.check, color: Colors.white, size: 14),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, double width) {
    return Text(
      title,
      style: TextStyle(
        fontSize: width * 0.05,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade900,
      ),
    );
  }

  Widget _selectableInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required double width,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.all(width * 0.04),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? Colors.blue.shade700
                  : Colors.transparent,
              width: isSelected ? 1.5 : 0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(width * 0.025),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withOpacity(0.25)
                      : color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected ? Icons.check : icon,
                  color: isSelected ? Colors.white : color,
                  size: width * 0.05,
                ),
              ),
              SizedBox(width: width * 0.02),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: width * 0.026,
                        color: isSelected
                            ? Colors.white70
                            : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: width * 0.032,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _infoCard(IconData icon, String label, String value, Color color,
      double width) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(width * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.025),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: width * 0.05),
            ),
            SizedBox(width: width * 0.02),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: width * 0.026,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: width * 0.032,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer(String videoUrl) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _VideoWidget(videoUrl: videoUrl),
        ),
      ),
    );
  }

  Widget _buildReviewFromDoc(Map<String, dynamic> data, bool isMine, double width) {
    final name = data['userName'] ?? 'Guest User';
    final comment = data['comment'] ?? '';
    final rating = ((data['rating'] ?? 5.0) as num).toDouble();

    String time = 'Recent';
    if (data['createdAt'] is Timestamp) {
      final dt = (data['createdAt'] as Timestamp).toDate();
      time = "${dt.day}/${dt.month}/${dt.year}";
    }

    return Container(
      margin: EdgeInsets.only(bottom: width * 0.03),
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: isMine ? Colors.blue.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isMine ? Border.all(color: Colors.blue.withOpacity(0.2)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: width * 0.045,
                backgroundColor: isMine ? Colors.blue : AppColors.primary,
                child: Text(
                  name.isNotEmpty ? name[0] : 'G',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'You',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < rating.floor() ? Icons.star : Icons.star_border,
                            color: AppColors.accentGold,
                            size: 14,
                          );
                        }),
                        SizedBox(width: width * 0.02),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.02),
          Text(
            comment,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(
      String name, String comment, double rating, String time, double width) {
    return Container(
      margin: EdgeInsets.only(bottom: width * 0.03),
      padding: EdgeInsets.all(width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: width * 0.045,
                backgroundColor: AppColors.primary,
                child: Text(
                  name[0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: width * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < rating.floor()
                                ? Icons.star
                                : Icons.star_border,
                            color: AppColors.accentGold,
                            size: 14,
                          );
                        }),
                        SizedBox(width: width * 0.02),
                        Text(
                          time,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: width * 0.02),
          Text(
            comment,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REVIEWS — Firestore Stream
  // ============================================================
  Stream<QuerySnapshot> _reviewsStream() {
    return _firestore
        .collection('destinations')
        .doc(widget.destination['id'])
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ============================================================
  // CHECK IF CURRENT USER ALREADY REVIEWED
  // ============================================================
  Future<void> _checkUserReview() async {
    if (_user == null) return;
    try {
      final snap = await _firestore
          .collection('destinations')
          .doc(widget.destination['id'])
          .collection('reviews')
          .where('userId', isEqualTo: _user!.uid)
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _hasUserReviewed = snap.docs.isNotEmpty;
          _userReviewId = snap.docs.isNotEmpty ? snap.docs.first.id : null;
        });
      }
    } catch (e) {
      debugPrint('🔥 checkUserReview: $e');
    }
  }

  // ============================================================
  // SUBMIT REVIEW (create or update)
  // ============================================================
  Future<void> _submitReview(double rating, String comment) async {
    if (_user == null) {
      _snack('Please login to write a review', Colors.orange);
      return;
    }

    if (comment.trim().isEmpty) {
      _snack('Please write something', Colors.orange);
      return;
    }

    try {
      final ref = _firestore
          .collection('destinations')
          .doc(widget.destination['id'])
          .collection('reviews');

      final data = {
        'userId': _user!.uid,
        'userName': _user!.displayName ?? 'Guest User',
        'userPhoto': _user!.photoURL ?? '',
        'rating': rating,
        'comment': comment.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (_hasUserReviewed && _userReviewId != null) {
        // UPDATE
        await ref.doc(_userReviewId).update({
          'rating': rating,
          'comment': comment.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // CREATE
        await ref.add(data);
      }

      // Update destination aggregate rating
      await _recalculateDestinationRating();

      // Log activity for admin
      await _firestore.collection('activities').add({
        'type': 'review',
        'action': _hasUserReviewed ? 'updated' : 'created',
        'title':
            '${_hasUserReviewed ? 'Updated' : 'New'} review: ${widget.destination['name']}',
        'description':
            '${_user!.displayName ?? 'User'} rated $rating ⭐',
        'userId': _user!.uid,
        'userName': _user!.displayName ?? 'User',
        'itemId': widget.destination['id'],
        'itemType': 'destination',
        'icon': '⭐',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _snack(
          _hasUserReviewed
              ? '✅ Review updated!'
              : '✅ Review posted!',
          Colors.green,
        );
        await _checkUserReview();
      }
    } catch (e) {
      debugPrint('🔥 submitReview: $e');
      _snack('Failed to post review', Colors.red);
    }
  }

  // ============================================================
  // DELETE REVIEW
  // ============================================================
  Future<void> _deleteReview() async {
    if (_user == null || _userReviewId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete review?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestore
          .collection('destinations')
          .doc(widget.destination['id'])
          .collection('reviews')
          .doc(_userReviewId)
          .delete();

      await _recalculateDestinationRating();

      if (mounted) {
        setState(() {
          _hasUserReviewed = false;
          _userReviewId = null;
        });
        _snack('🗑️ Review deleted', Colors.grey);
      }
    } catch (e) {
      debugPrint('🔥 deleteReview: $e');
    }
  }

  // ============================================================
  // RECALCULATE AVERAGE RATING ON DESTINATION DOC
  // ============================================================
  Future<void> _recalculateDestinationRating() async {
    try {
      final snap = await _firestore
          .collection('destinations')
          .doc(widget.destination['id'])
          .collection('reviews')
          .get();

      if (snap.docs.isEmpty) {
        await _firestore
            .collection('destinations')
            .doc(widget.destination['id'])
            .set({'rating': 0.0, 'reviewCount': 0},
                SetOptions(merge: true));
        return;
      }

      double sum = 0;
      for (final d in snap.docs) {
        sum += ((d.data()['rating'] ?? 0) as num).toDouble();
      }
      final avg = sum / snap.docs.length;

      await _firestore
          .collection('destinations')
          .doc(widget.destination['id'])
          .set({
        'rating': double.parse(avg.toStringAsFixed(1)),
        'reviewCount': snap.docs.length,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('🔥 recalc: $e');
    }
  }

  // ============================================================
  // OPEN WRITE REVIEW BOTTOM SHEET
  // ============================================================
  Future<void> _openWriteReviewSheet() async {
    if (_user == null) {
      _snack('Please login to write a review', Colors.orange);
      return;
    }

    // If user already reviewed, preload their existing review
    double currentRating = 5.0;
    String currentComment = '';

    if (_hasUserReviewed && _userReviewId != null) {
      try {
        final doc = await _firestore
            .collection('destinations')
            .doc(widget.destination['id'])
            .collection('reviews')
            .doc(_userReviewId)
            .get();
        if (doc.exists) {
          currentRating = (doc.data()?['rating'] ?? 5.0).toDouble();
          currentComment = (doc.data()?['comment'] ?? '').toString();
        }
      } catch (_) {}
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(
        initialRating: currentRating,
        initialComment: currentComment,
        isEdit: _hasUserReviewed,
        onSubmit: (rating, comment) => _submitReview(rating, comment),
        onDelete: _hasUserReviewed ? _deleteReview : null,
      ),
    );
  }
}

// ============================================================
// WRITE / EDIT REVIEW BOTTOM SHEET
// ============================================================
class _WriteReviewSheet extends StatefulWidget {
  final double initialRating;
  final String initialComment;
  final bool isEdit;
  final Future<void> Function(double rating, String comment) onSubmit;
  final Future<void> Function()? onDelete;

  const _WriteReviewSheet({
    required this.initialRating,
    required this.initialComment,
    required this.isEdit,
    required this.onSubmit,
    this.onDelete,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  late double _rating;
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.initialRating;
    _controller = TextEditingController(text: widget.initialComment);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _ratingLabel {
    if (_rating >= 4.5) return '⭐ Excellent';
    if (_rating >= 3.5) return '😊 Very Good';
    if (_rating >= 2.5) return '🙂 Good';
    if (_rating >= 1.5) return '😐 Fair';
    return '😞 Poor';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: EdgeInsets.all(width * 0.05),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: width * 0.04),

              // Title
              Text(
                widget.isEdit ? 'Edit your review' : 'Write a review',
                style: TextStyle(
                  fontSize: width * 0.055,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: width * 0.01),
              Text(
                'Share your experience to help others',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: width * 0.033,
                ),
              ),
              SizedBox(height: width * 0.05),

              // Stars
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final filled = i < _rating;
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _rating = i + 1.0);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              filled ? Icons.star : Icons.star_border,
                              color: AppColors.accentGold,
                              size: width * 0.11,
                            ),
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: width * 0.02),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _ratingLabel,
                        key: ValueKey(_ratingLabel),
                        style: TextStyle(
                          fontSize: width * 0.038,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: width * 0.05),

              // Comment field
              TextField(
                controller: _controller,
                maxLines: 5,
                maxLength: 500,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'What did you love? What could be better?',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: Colors.blue,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: EdgeInsets.all(width * 0.04),
                ),
              ),
              SizedBox(height: width * 0.02),

              // Actions
              Row(
                children: [
                  if (widget.isEdit && widget.onDelete != null) ...[
                    GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        await widget.onDelete!();
                      },
                      child: Container(
                        padding: EdgeInsets.all(width * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.delete, color: Colors.red, size: 22),
                      ),
                    ),
                    SizedBox(width: width * 0.03),
                  ],
                  Expanded(
                    child: GestureDetector(
                      onTap: _submitting
                          ? null
                          : () async {
                              setState(() => _submitting = true);
                              await widget.onSubmit(_rating, _controller.text);
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: width * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  widget.isEdit ? 'Update Review' : 'Post Review',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: width * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// FULLSCREEN IMAGE VIEWER — with page-change zoom reset
// ============================================================
class FullscreenImageViewer extends StatefulWidget {
  final List<String> imageUrls;
  final int initialIndex;

  const FullscreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
  });

  @override
  State<FullscreenImageViewer> createState() => _FullscreenImageViewerState();
}

class _FullscreenImageViewerState extends State<FullscreenImageViewer> {
  late final PageController _pageController;
  late int _index;

  // One transform controller per page so zoom resets on swipe
  final Map<int, TransformationController> _controllers = {};
  final AirZoomService _airZoomService = AirZoomService.instance;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);

    _airZoomService.zoomLevel.addListener(_onAirZoomChanged);
  }

  void _onAirZoomChanged() {
    if (!mounted) return;

    final controller = _getController(_index);
    final zoom = _airZoomService.zoomLevel.value;

    final currentScale = controller.value.getMaxScaleOnAxis();

    if ((zoom - currentScale).abs() < 0.01) {
      return;
    }

    final clampedZoom = zoom.clamp(1.0, 5.0);

    controller.value = Matrix4.identity()
      ..scale(clampedZoom);
  }

  @override
  void dispose() {
    _airZoomService.zoomLevel.removeListener(_onAirZoomChanged);
    _pageController.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TransformationController _getController(int i) {
    return _controllers.putIfAbsent(i, () => TransformationController());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final controller = _getController(i);
              return InteractiveViewer(
                transformationController: controller,
                minScale: 1.0,
                maxScale: 5.0,
                child: Center(
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrls[i],
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                    errorWidget: (_, __, ___) => const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image,
                            color: Colors.white, size: 60),
                        SizedBox(height: 10),
                        Text('Could not load image',
                            style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // Close button
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(Icons.close,
                    color: Colors.white, size: 22),
              ),
            ),
          ),

          // Counter
          if (widget.imageUrls.length > 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_index + 1} / ${widget.imageUrls.length}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// VIDEO WIDGETS
// ============================================================
class _VideoWidget extends StatefulWidget {
  final String videoUrl;
  const _VideoWidget({required this.videoUrl});

  @override
  State<_VideoWidget> createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<_VideoWidget> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _videoController =
    VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoController,
          autoPlay: false,
          looping: false,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.accentGold,
            backgroundColor: Colors.grey,
            bufferedColor: Colors.white70,
          ),
        );
        if (mounted) setState(() {});
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    }
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

class _VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  const _VideoPlayerScreen({required this.videoUrl});

  @override
  State<_VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<_VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller =
    VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        setState(() => _isInitialized = true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('🎥 Video'),
      ),
      body: Center(
        child: _isInitialized
            ? AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: const VideoProgressColors(
                  playedColor: Color(0xFFF5A623),
                ),
              ),
              IconButton(
                icon: Icon(
                  _controller.value.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  color: Colors.white,
                  size: 60,
                ),
                onPressed: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
              ),
            ],
          ),
        )
            : const CircularProgressIndicator(
          color: Color(0xFFF5A623),
        ),
      ),
    );
  }
}