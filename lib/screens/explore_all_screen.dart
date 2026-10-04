import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../utils/colors.dart';
import '../services/image_service.dart';
import 'hotel_details_screen.dart';
import 'tours_list_screen.dart';
import 'beaches_list_screen.dart';
import 'mountains_list_screen.dart';
import 'culture_list_screen.dart';
import 'food_list_screen.dart';
import 'destination_details_screen.dart';

class ExploreAllScreen extends StatefulWidget {
  final String categoryFilter;
  const ExploreAllScreen({super.key, required this.categoryFilter});

  @override
  State<ExploreAllScreen> createState() => _ExploreAllScreenState();
}

class _ExploreAllScreenState extends State<ExploreAllScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedRegion = 'Tanzania';
  bool _isGridView = true;

  final List<Map<String, String>> allDestinations = [
    // ===== TANZANIA - HOTELS =====
    {'name': 'Four Seasons Safari Lodge', 'category': 'Hotels', 'region': 'Tanzania', 'location': 'Serengeti', 'url': 'https://www.fourseasons.com/serengeti'},
    {'name': 'Serena Hotels', 'category': 'Hotels', 'region': 'Tanzania', 'location': 'Dar es Salaam', 'url': 'https://www.serenahotels.com'},
    {'name': 'Hyatt Regency', 'category': 'Hotels', 'region': 'Tanzania', 'location': 'Dar es Salaam', 'url': 'https://www.hyatt.com'},
    {'name': 'Meliá Zanzibar', 'category': 'Hotels', 'region': 'Tanzania', 'location': 'Zanzibar', 'url': 'https://www.melia.com'},
    {'name': 'Arusha Coffee Lodge', 'category': 'Hotels', 'region': 'Tanzania', 'location': 'Arusha', 'url': 'https://www.arushacoffeelodge.com'},

    // ===== TANZANIA - SAFARI =====
    {'name': 'Serengeti National Park', 'category': 'Safari', 'region': 'Tanzania', 'location': 'Mara Region', 'url': 'https://www.serengeti.com'},
    {'name': 'Ngorongoro Crater', 'category': 'Safari', 'region': 'Tanzania', 'location': 'Arusha', 'url': 'https://www.ngorongorocrater.org'},
    {'name': 'Tarangire National Park', 'category': 'Safari', 'region': 'Tanzania', 'location': 'Manyara', 'url': 'https://www.tanzaniaparks.go.tz'},
    {'name': 'Ruaha National Park', 'category': 'Safari', 'region': 'Tanzania', 'location': 'Iringa', 'url': 'https://www.tanzaniaparks.go.tz'},
    {'name': 'Lake Manyara', 'category': 'Safari', 'region': 'Tanzania', 'location': 'Manyara', 'url': 'https://www.tanzaniaparks.go.tz'},

    // ===== TANZANIA - BEACHES =====
    {'name': 'Nungwi Beach', 'category': 'Beaches', 'region': 'Tanzania', 'location': 'Zanzibar', 'url': 'https://www.zanzibartourism.go.tz'},
    {'name': 'Kendwa Beach', 'category': 'Beaches', 'region': 'Tanzania', 'location': 'Zanzibar', 'url': 'https://www.zanzibartourism.go.tz'},
    {'name': 'Paje Beach', 'category': 'Beaches', 'region': 'Tanzania', 'location': 'Zanzibar', 'url': 'https://www.zanzibartourism.go.tz'},
    {'name': 'Kigamboni Beach', 'category': 'Beaches', 'region': 'Tanzania', 'location': 'Dar es Salaam', 'url': 'https://www.tanzaniatourism.go.tz'},

    // ===== TANZANIA - MOUNTAINS =====
    {'name': 'Mount Kilimanjaro', 'category': 'Mountains', 'region': 'Tanzania', 'location': 'Kilimanjaro', 'url': 'https://www.tanzaniaparks.go.tz/kilimanjaro'},
    {'name': 'Mount Meru', 'category': 'Mountains', 'region': 'Tanzania', 'location': 'Arusha', 'url': 'https://www.tanzaniaparks.go.tz/arusha'},
    {'name': 'Mount Hanang', 'category': 'Mountains', 'region': 'Tanzania', 'location': 'Manyara', 'url': 'https://www.tanzaniatourism.go.tz'},
    {'name': 'Usambara Mountains', 'category': 'Mountains', 'region': 'Tanzania', 'location': 'Tanga', 'url': 'https://www.tanzaniatourism.go.tz'},

    // ===== TANZANIA - CULTURE =====
    {'name': 'Maasai Boma', 'category': 'Culture', 'region': 'Tanzania', 'location': 'Ngorongoro', 'url': 'https://www.tanzaniatourism.go.tz'},
    {'name': 'Stone Town', 'category': 'Culture', 'region': 'Tanzania', 'location': 'Zanzibar', 'url': 'https://www.zanzibartourism.go.tz'},
    {'name': 'Hadza Tribe', 'category': 'Culture', 'region': 'Tanzania', 'location': 'Lake Eyasi', 'url': 'https://www.tanzaniatourism.go.tz'},

    // ===== TANZANIA - FOOD =====
    {'name': 'Zanzibar Pizza', 'category': 'Food', 'region': 'Tanzania', 'location': 'Zanzibar', 'url': 'https://www.zanzibartourism.go.tz'},
    {'name': 'Ugali & Nyama Choma', 'category': 'Food', 'region': 'Tanzania', 'location': 'Nationwide', 'url': 'https://www.tanzaniatourism.go.tz'},
    {'name': 'Pilau & Biryani', 'category': 'Food', 'region': 'Tanzania', 'location': 'Dar es Salaam', 'url': 'https://www.tanzaniatourism.go.tz'},

    // ===== AFRICA =====
    {'name': 'Maasai Mara', 'category': 'Safari', 'region': 'Africa', 'location': 'Kenya', 'url': 'https://www.maasaimara.com'},
    {'name': 'Kruger National Park', 'category': 'Safari', 'region': 'Africa', 'location': 'South Africa', 'url': 'https://www.sanparks.org'},
    {'name': 'Mount Kenya', 'category': 'Mountains', 'region': 'Africa', 'location': 'Kenya', 'url': 'https://www.magicalkenya.com'},
    {'name': 'Mount Rwenzori', 'category': 'Mountains', 'region': 'Africa', 'location': 'Uganda', 'url': 'https://www.ugandawildlife.org'},
    {'name': 'Diani Beach', 'category': 'Beaches', 'region': 'Africa', 'location': 'Kenya', 'url': 'https://www.magicalkenya.com'},
    {'name': 'Giraffe Manor', 'category': 'Hotels', 'region': 'Africa', 'location': 'Kenya', 'url': 'https://www.thesafaricollection.com'},
    {'name': 'Singita', 'category': 'Hotels', 'region': 'Africa', 'location': 'South Africa', 'url': 'https://www.singita.com'},
    {'name': 'Pyramids of Giza', 'category': 'Culture', 'region': 'Africa', 'location': 'Egypt', 'url': 'https://www.egypt.travel'},
    {'name': 'Jollof Rice', 'category': 'Food', 'region': 'Africa', 'location': 'West Africa', 'url': 'https://www.africa.com'},
    {'name': 'Moroccan Tagine', 'category': 'Food', 'region': 'Africa', 'location': 'Morocco', 'url': 'https://www.visitmorocco.com'},

    // ===== WORLD =====
    {'name': 'Mount Everest', 'category': 'Mountains', 'region': 'World', 'location': 'Nepal', 'url': 'https://www.nepal-tourism.com'},
    {'name': 'Matterhorn', 'category': 'Mountains', 'region': 'World', 'location': 'Switzerland', 'url': 'https://www.myswitzerland.com'},
    {'name': 'Mount Fuji', 'category': 'Mountains', 'region': 'World', 'location': 'Japan', 'url': 'https://www.japan.travel'},
    {'name': 'Yellowstone', 'category': 'Safari', 'region': 'World', 'location': 'USA', 'url': 'https://www.nps.gov/yell'},
    {'name': 'Kaziranga', 'category': 'Safari', 'region': 'World', 'location': 'India', 'url': 'https://www.kaziranganationalpark.com'},
    {'name': 'Maldives', 'category': 'Beaches', 'region': 'World', 'location': 'Maldives', 'url': 'https://www.visitmaldives.com'},
    {'name': 'Bora Bora', 'category': 'Beaches', 'region': 'World', 'location': 'French Polynesia', 'url': 'https://www.tahititourisme.com'},
    {'name': 'Burj Al Arab', 'category': 'Hotels', 'region': 'World', 'location': 'Dubai', 'url': 'https://www.jumeirah.com'},
    {'name': 'Marina Bay Sands', 'category': 'Hotels', 'region': 'World', 'location': 'Singapore', 'url': 'https://www.marinabaysands.com'},
    {'name': 'Taj Mahal', 'category': 'Culture', 'region': 'World', 'location': 'India', 'url': 'https://www.incredibleindia.org'},
    {'name': 'Machu Picchu', 'category': 'Culture', 'region': 'World', 'location': 'Peru', 'url': 'https://www.peru.travel'},
    {'name': 'Sushi', 'category': 'Food', 'region': 'World', 'location': 'Japan', 'url': 'https://www.japan.travel'},
    {'name': 'Pasta', 'category': 'Food', 'region': 'World', 'location': 'Italy', 'url': 'https://www.italia.it'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.categoryFilter.isNotEmpty && widget.categoryFilter != 'All') {
      _selectedCategory = widget.categoryFilter;
    }
  }

  String _getIconForCategory(String category) {
    switch (category) {
      case 'Hotels':
        return '🏨';
      case 'Safari':
        return '🦁';
      case 'Beaches':
        return '🏖️';
      case 'Mountains':
        return '⛰️';
      case 'Culture':
        return '🎭';
      case 'Food':
        return '🍛';
      default:
        return '🌍';
    }
  }

  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ============================================================
  // COMBINED STREAM
  // ============================================================
  Stream<List<Map<String, dynamic>>> _combinedStream() async* {
    final collections = [
      {'name': 'destinations', 'category': 'Safari'},
      {'name': 'hotels', 'category': 'Hotels'},
      {'name': 'tours', 'category': 'Safari'},
      {'name': 'beaches', 'category': 'Beaches'},
      {'name': 'mountains', 'category': 'Mountains'},
      {'name': 'culture', 'category': 'Culture'},
      {'name': 'food', 'category': 'Food'},
      {'name': 'activities', 'category': 'Safari'},
    ];

    final latest = <String, List<Map<String, dynamic>>>{};

    Stream<List<Map<String, dynamic>>> watch(String col, String cat) {
      return FirebaseFirestore.instance
          .collection(col)
          .snapshots()
          .map((snap) => snap.docs.map((doc) {
        final data = doc.data();
        final Map<String, dynamic> rawData =
        Map<String, dynamic>.from(data);
        rawData['id'] = doc.id;
        rawData['name'] = (rawData['name'] ?? rawData['title'] ?? 'Unnamed').toString();
        rawData['location'] = (rawData['location'] ?? 'Unknown Location').toString();
        rawData['description'] = (rawData['description'] ?? 'No description available.').toString();
        rawData['imageUrl'] = (rawData['imageUrl'] ?? rawData['image'] ?? '').toString();
        rawData['price'] = rawData['price'] ?? rawData['priceFrom'] ?? 0.0;
        rawData['rating'] = rawData['rating'] ?? 0.0;
        rawData['category'] = cat;

        return {
          'id': doc.id,
          'name': (data['name'] ?? data['title'] ?? '').toString(),
          'category': cat,
          'region': _inferRegion(data),
          'location': (data['location'] ?? '').toString(),
          'imageUrl': (data['imageUrl'] ?? '').toString(),
          'price': data['price'] ?? data['priceFrom'] ?? 0,
          'currency': (data['currency'] ?? 'USD').toString(),
          'rating': data['rating'] ?? 0,
          'status': data['status'] ?? 'active',
          'raw': rawData,
          'collection': col,
        };
      }).where((d) =>
      d['status'] == 'active' &&
          (d['name'] as String).isNotEmpty).toList());
    }

    final mergedController = StreamController<List<Map<String, dynamic>>>();

    for (var c in collections) {
      watch(c['name']!, c['category']!).listen((data) {
        latest[c['name']!] = data;
        final combined = <Map<String, dynamic>>[];
        for (var entry in latest.values) {
          combined.addAll(entry);
        }
        if (!mergedController.isClosed) {
          mergedController.add(combined);
        }
      });
    }

    yield* mergedController.stream;
  }

  String _inferRegion(Map<String, dynamic> data) {
    final country =
    (data['country'] ?? data['location'] ?? '').toString().toLowerCase();
    final region = (data['region'] ?? '').toString().toLowerCase();

    if (region == 'tanzania' ||
        country.contains('tanzania') ||
        country.contains('zanzibar') ||
        country.contains('arusha') ||
        country.contains('serengeti') ||
        country.contains('ngorongoro') ||
        country.contains('kilimanjaro') ||
        country.contains('dar es salaam')) {
      return 'Tanzania';
    }

    const africaCountries = [
      'kenya', 'uganda', 'rwanda', 'south africa', 'egypt',
      'morocco', 'ghana', 'nigeria', 'ethiopia', 'namibia',
      'botswana', 'zambia', 'mozambique', 'tunisia', 'senegal',
    ];
    for (var c in africaCountries) {
      if (country.contains(c)) return 'Africa';
    }

    return 'World';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
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
          Container(color: Colors.black.withOpacity(0.75)),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ===== APP BAR =====
              SliverAppBar(
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                automaticallyImplyLeading: false,
                expandedHeight: 165,
                toolbarHeight: 165,
                flexibleSpace: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: width * 0.03,
                      vertical: width * 0.02,
                    ),
                    child: _buildGlassHeader(width, height),
                  ),
                ),
              ),

              // ===== CATEGORY CHIPS =====
              SliverToBoxAdapter(
                child: SizedBox(
                  height: height * 0.055,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                    children: ['All', 'Hotels', 'Safari', 'Beaches', 'Mountains', 'Culture', 'Food'].map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = cat),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(right: width * 0.02),
                          padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentGold
                                : Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.accentGold
                                  : Colors.white.withOpacity(0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                              BoxShadow(
                                color: AppColors.accentGold.withOpacity(0.4),
                                blurRadius: 12,
                              ),
                            ]
                                : [],
                          ),
                          child: Center(
                            child: Text(
                              cat,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: width * 0.032,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ===== REGION TABS =====
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.04, vertical: height * 0.01),
                  child: Row(
                    children: ['Tanzania', 'Africa', 'World'].map((region) {
                      final isSelected = _selectedRegion == region;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedRegion = region),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(horizontal: width * 0.01),
                            padding: EdgeInsets.symmetric(vertical: height * 0.015),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.accentGold
                                  : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.accentGold
                                    : Colors.white.withOpacity(0.3),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                BoxShadow(
                                  color: AppColors.accentGold.withOpacity(0.4),
                                  blurRadius: 12,
                                ),
                              ]
                                  : [],
                            ),
                            child: Text(
                              region,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: width * 0.035,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // ===== COMBINED STREAM =====
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: _combinedStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: CircularProgressIndicator(
                              color: AppColors.accentGold),
                        ),
                      ),
                    );
                  }

                  final currentDestinations = snapshot.data ?? [];

                  final filteredList = currentDestinations.where((item) {
                    final matchCategory = _selectedCategory == 'All' ||
                        (item['category'] ?? '').toString() == _selectedCategory;
                    final matchRegion = (item['region'] ?? '').toString() ==
                        _selectedRegion;
                    final q = _searchController.text.toLowerCase();
                    final matchSearch = q.isEmpty ||
                        (item['name'] ?? '').toString().toLowerCase().contains(q) ||
                        (item['location'] ?? '').toString().toLowerCase().contains(q);
                    return matchCategory && matchRegion && matchSearch;
                  }).toList();

                  if (filteredList.isEmpty) {
                    return SliverToBoxAdapter(
                      child: _buildGlassEmptyState(width, height),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      // Result count
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: width * 0.05,
                            vertical: height * 0.01),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                '${filteredList.length} results in $_selectedRegion',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: width * 0.032,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Grid OR List
                      if (_isGridView)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: width * 0.06,
                              mainAxisSpacing: width * 0.06,
                              childAspectRatio: 0.69, // Decreased from 0.75 to make cards taller
                            ),
                            itemCount: filteredList.length,
                            itemBuilder: (context, index) {
                              return _buildGridCard(
                                  filteredList[index], width, height);
                            },
                          ),
                        )
                      else
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                          child: Column(
                            children: filteredList
                                .map((item) => _buildCard(item, width, height))
                                .toList(),
                          ),
                        ),

                      SizedBox(height: height * 0.04),
                    ]),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // GRID CARD (compact — like Deals card)
  // ============================================================
  Widget _buildGridCard(Map<String, dynamic> item, double width, double height) {
    return GestureDetector(
      onTap: () => _navigateToDetails(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ⭐ IMAGE — smaller, fixed height
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16)),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: height * 0.18,   // Increased from 0.14 to fill the larger card
                        width: double.infinity,
                        child: (item['imageUrl'] ?? '').toString().isNotEmpty
                            ? Image.network(
                          item['imageUrl'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _imageFallback(item['category'] ?? ''),
                        )
                            : _buildImage(item['name'] ?? ''),
                      ),
                      // Category badge
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.75),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accentGold.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _getIconForCategory(item['category'] ?? ''),
                                style: const TextStyle(fontSize: 10),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                (item['category'] ?? '').toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Rating
                      if ((item['rating'] ?? 0) > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star,
                                    size: 9, color: Colors.black),
                                const SizedBox(width: 2),
                                Text(
                                  (item['rating'] as num).toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
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
                // ⭐ CONTENT — compact, no Expanded
                Padding(
                  padding: EdgeInsets.all(width * 0.025),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,   // ⭐ KEY — no gap
                    children: [
                      // Title
                      Text(
                        (item['name'] ?? '').toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.032,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Location
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: width * 0.025, color: Colors.white70),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              (item['location'] ?? '').toString(),
                              style: TextStyle(
                                fontSize: width * 0.022,
                                color: Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      // Price
                      if ((item['price'] ?? 0) > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${item['currency']} ${(item['price'] as num).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.accentGold,
                            fontSize: width * 0.03,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassEmptyState(double width, double height) {
    return Center(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: width * 0.1),
        padding: EdgeInsets.all(width * 0.08),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(width * 0.06),
              decoration: BoxDecoration(
                gradient: AppColors.goldGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentGold.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.search_off,
                  size: width * 0.12, color: Colors.black),
            ),
            SizedBox(height: height * 0.025),
            Text(
              'No results found',
              style: TextStyle(
                fontSize: width * 0.048,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: height * 0.01),
            Text(
              'Try a different search or region',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: width * 0.032,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, double width, double height) {
    return GestureDetector(
      onTap: () => _navigateToDetails(item),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            margin: EdgeInsets.only(bottom: height * 0.015),
            padding: EdgeInsets.all(width * 0.03),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.13),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: width * 0.33, // Increased from 0.28
                    height: width * 0.33, // Increased from 0.28
                    child: (item['imageUrl'] ?? '').toString().isNotEmpty
                        ? Image.network(
                      item['imageUrl'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _imageFallback(item['category'] ?? ''),
                    )
                        : _buildImage(item['name'] ?? ''),
                  ),
                ),
                SizedBox(width: width * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(_getIconForCategory(item['category'] ?? ''),
                              style: TextStyle(fontSize: width * 0.04)),
                          SizedBox(width: width * 0.01),
                          Text(
                            (item['category'] ?? '').toString(),
                            style: TextStyle(
                              color: AppColors.accentGold,
                              fontSize: width * 0.028,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if ((item['rating'] ?? 0) > 0) ...[
                            const Spacer(),
                            const Icon(Icons.star,
                                color: AppColors.accentGold, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              (item['rating'] as num).toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: height * 0.005),
                      Text(
                        (item['name'] ?? '').toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.04,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: height * 0.005),
                      Row(
                        children: [
                          Icon(Icons.location_on,
                              size: width * 0.03, color: Colors.white70),
                          SizedBox(width: width * 0.01),
                          Expanded(
                            child: Text(
                              (item['location'] ?? '').toString(),
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: width * 0.028),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if ((item['price'] ?? 0) > 0) ...[
                        SizedBox(height: height * 0.005),
                        Text(
                          '${item['currency']} ${(item['price'] as num).toStringAsFixed(0)}',
                          style: TextStyle(
                            color: AppColors.accentGold,
                            fontSize: width * 0.032,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.accentGold,
                  size: width * 0.04,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToDetails(Map<String, dynamic> item) {
    final collection = (item['collection'] ?? '').toString();
    final raw = item['raw'] as Map<String, dynamic>? ?? item;

    Widget? page;
    switch (collection) {
      case 'hotels':
        page = HotelDetailsScreen(hotel: raw, hotelData: raw);
        break;
      case 'tours':
      case 'activities':
        page = const ToursListScreen();
        break;
      case 'beaches':
        page = const BeachesListScreen();
        break;
      case 'mountains':
        page = const MountainsListScreen();
        break;
      case 'culture':
        page = const CultureListScreen();
        break;
      case 'food':
        page = const FoodListScreen();
        break;
      case 'destinations':
        page = DestinationDetailsScreen(destination: raw);
        break;
      default:
        page = const ToursListScreen();
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => page!));
  }

  Widget _imageFallback(String category) {
    return Container(
      color: Colors.white.withOpacity(0.1),
      child: Center(
        child: Text(
          _getIconForCategory(category),
          style: const TextStyle(fontSize: 40),
        ),
      ),
    );
  }

  Widget _buildImage(String query) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: ImageService().searchPhotos(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.image, color: Colors.grey),
          );
        }
        return Image.network(
          snapshot.data![0]['src']['large'],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        );
      },
    );
  }

  // ============================================================
  // GLASS HEADER
  // ============================================================
  Widget _buildGlassHeader(double width, double height) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: width * 0.04, vertical: width * 0.03),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
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
                  Text('🌍', style: TextStyle(fontSize: width * 0.07)),
                  SizedBox(width: width * 0.02),
                  Expanded(
                    child: Text(
                      'Explore All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: width * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isGridView = !_isGridView),
                    child: AnimatedRotation(
                      turns: _isGridView ? 0 : 0.5,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isGridView ? Icons.view_list : Icons.grid_view,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: height * 0.015),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(color: Colors.white),
                    cursorColor: AppColors.accentGold,
                    decoration: InputDecoration(
                      hintText: 'Search anything worldwide...',
                      hintStyle: const TextStyle(color: Colors.white54),
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.accentGold),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear,
                            color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                            color: AppColors.accentGold, width: 1.5),
                      ),
                      contentPadding:
                      EdgeInsets.symmetric(vertical: height * 0.012),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}