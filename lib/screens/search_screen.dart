import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/search_service.dart';
import '../services/wishlist_service.dart';
import '../utils/colors.dart';
import 'destination_details_screen.dart';
import 'hotel_details_screen.dart';
import 'tour_details_screen.dart';
import 'beach_details_screen.dart';
import 'mountain_details_screen.dart';
import 'culture_details_screen.dart';
import 'food_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchService = SearchService();
  final _wishlistService = WishlistService();
  final _searchController = TextEditingController();
  final _user = FirebaseAuth.instance.currentUser;

  String _selectedCategory = 'all';
  String _sortBy = 'relevance';
  double _minPrice = 0;
  double _maxPrice = 100000;
  double _minRating = 0;
  String _selectedLocation = '';

  List<Map<String, dynamic>> _results = [];
  List<String> _suggestions = [];
  List<String> _searchHistory = [];
  List<String> _trendingSearches = [];
  List<String> _popularLocations = [];

  bool _isSearching = false;
  bool _isLoading = true;
  bool _showFilters = false;
  bool _hasSearched = false;

  final Set<String> _likedItems = {};

  final List<Map<String, String>> _categories = [
    {'value': 'all', 'label': '🌍 All', 'icon': '🌍'},
    {'value': 'hotels', 'label': '🏨 Hotels', 'icon': '🏨'},
    {'value': 'tours', 'label': '🦁 Tours', 'icon': '🦁'},
    {'value': 'beaches', 'label': '🏖️ Beaches', 'icon': '🏖️'},
    {'value': 'mountains', 'label': '⛰️ Mountains', 'icon': '⛰️'},
    {'value': 'culture', 'label': '🎭 Culture', 'icon': '🎭'},
    {'value': 'food', 'label': '🍛 Food', 'icon': '🍛'},
    {'value': 'destinations', 'label': '📍 Destinations', 'icon': '📍'},
    {'value': 'deals', 'label': '🎁 Deals', 'icon': '🎁'},
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadTrending();
    _loadPopularLocations();
    _loadLiked();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > 10) _searchHistory = _searchHistory.sublist(0, 10);

    await prefs.setStringList('search_history', _searchHistory);
    if (mounted) setState(() {});
  }

  Future<void> _loadTrending() async {
    final trending = await _searchService.getTrendingSearches();
    if (mounted) setState(() => _trendingSearches = trending);
  }

  Future<void> _loadPopularLocations() async {
    final locations = await _searchService.getPopularLocations();
    if (mounted) setState(() => _popularLocations = locations);
  }

  Future<void> _loadLiked() async {
    if (_user == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('wishlists')
          .where('userId', isEqualTo: _user!.uid)
          .get();
      setState(() {
        _likedItems.addAll(
            snapshot.docs.map((d) => d.data()['itemId'] as String));
      });
    } catch (e) {
      print('Error: $e');
    }
  }

  // ⭐️ Perform search
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
    });

    final results = await _searchService.universalSearch(
      query,
      category: _selectedCategory,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      minRating: _minRating,
      location: _selectedLocation,
      sortBy: _sortBy,
    );

    if (mounted) {
      setState(() {
        _results = results;
        _isSearching = false;
      });
    }

    _saveSearchHistory(query);
  }

  // ⭐️ Get suggestions
  Future<void> _getSuggestions(String query) async {
    if (query.length < 2) {
      setState(() => _suggestions = []);
      return;
    }

    final suggestions = await _searchService.getSuggestions(query);
    if (mounted) setState(() => _suggestions = suggestions);
  }

  void _applyFilters() async {
    if (_searchController.text.trim().isNotEmpty) {
      await _performSearch(_searchController.text.trim());
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'all';
      _minPrice = 0;
      _maxPrice = 100000;
      _minRating = 0;
      _selectedLocation = '';
      _sortBy = 'relevance';
    });
    _applyFilters();
  }

  Future<void> _toggleLike(Map<String, dynamic> item) async {
    if (_user == null) return;

    final wasAdded = await _wishlistService.addToWishlist(
      userId: _user!.uid,
      itemId: item['id'],
      itemType: item['type'],
      itemName: item['name'] ?? '',
      itemImage: item['imageUrl'] ?? '',
      price: (item['price'] ?? 0).toDouble(),
      currency: item['currency'] ?? 'USD',
    );

    setState(() {
      if (wasAdded) {
        _likedItems.add(item['id']);
      } else {
        _likedItems.remove(item['id']);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(wasAdded ? '❤️ Added to wishlist' : '💔 Removed'),
        backgroundColor: wasAdded ? Colors.red : Colors.grey,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Background Image
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage('https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?q=80&w=1000&auto=format&fit=crop'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 2. Dark Overlay
          Container(
            color: Colors.black.withOpacity(0.4),
          ),
          // 3. Main Content
          SafeArea(
            child: Column(
              children: [
                // SEARCH BAR SECTION
                Container(
                  padding: EdgeInsets.all(width * 0.04),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: const TextStyle(color: Colors.white),
                      onChanged: (v) {
                        _getSuggestions(v);
                        if (v.isEmpty) {
                          setState(() {
                            _results = [];
                            _hasSearched = false;
                          });
                        }
                      },
                      onSubmitted: (v) {
                        _suggestions = [];
                        _performSearch(v);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search hotels, tours, beaches...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        prefixIcon: const Icon(Icons.search, color: Colors.white),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: height * 0.018),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.white),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _suggestions = [];
                                    _results = [];
                                    _hasSearched = false;
                                  });
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                // CATEGORY CHIPS SECTION
                Container(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.04, vertical: height * 0.01),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat['value'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedCategory = cat['value']!);
                            if (_searchController.text.isNotEmpty) {
                              _performSearch(_searchController.text);
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: width * 0.02),
                            padding: EdgeInsets.symmetric(horizontal: width * 0.035, vertical: height * 0.008),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.accentGold : Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                            ),
                            child: Text(
                              cat['label']!,
                              style: TextStyle(
                                color: isSelected ? Colors.black : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: width * 0.026,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                if (_showFilters) _buildFiltersPanel(width, height),

                Expanded(
                  child: _isSearching
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : _suggestions.isNotEmpty
                          ? _buildSuggestions(width, height)
                          : !_hasSearched
                              ? _buildDiscover(width, height)
                              : _results.isEmpty
                                  ? _buildNoResults(width, height)
                                  : _buildResults(width, height),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ⭐️ Discover view (before search)
  Widget _buildDiscover(double width, double height) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (_searchHistory.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🕐 Recent Searches',
                    style: TextStyle(
                      fontSize: width * 0.04,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
                TextButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('search_history');
                    setState(() => _searchHistory = []);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  child: const Text('Clear'),
                ),
              ],
            ),
            SizedBox(height: height * 0.01),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _searchHistory.map((s) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = s;
                    _performSearch(s);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history,
                            size: width * 0.035, color: Colors.white70),
                        SizedBox(width: width * 0.015),
                        Text(s, style: TextStyle(fontSize: width * 0.03, color: Colors.white)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: height * 0.025),
          ],

          // Trending
          if (_trendingSearches.isNotEmpty) ...[
            Text('🔥 Trending Now',
                style: TextStyle(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )),
            SizedBox(height: height * 0.01),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _trendingSearches.map((s) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = s;
                    _performSearch(s);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(s,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.bold,
                        )),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: height * 0.025),
          ],

          // Popular locations
          if (_popularLocations.isNotEmpty) ...[
            Text('📍 Popular Locations',
                style: TextStyle(
                  fontSize: width * 0.04,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )),
            SizedBox(height: height * 0.01),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _popularLocations.map((s) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = s;
                    _performSearch(s);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(s,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.03,
                          fontWeight: FontWeight.w600,
                        )),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  // ⭐️ Suggestions
  Widget _buildSuggestions(double width, double height) {
    return ListView.builder(
      itemCount: _suggestions.length,
      itemBuilder: (context, i) {
        return ListTile(
          leading: const Icon(Icons.search, color: Colors.white70),
          title: Text(_suggestions[i], style: const TextStyle(color: Colors.white)),
          onTap: () {
            _searchController.text = _suggestions[i];
            _suggestions = [];
            _performSearch(_suggestions.isNotEmpty ? _suggestions[i] : _searchController.text);
          },
        );
      },
    );
  }

  // ⭐️ No results
  Widget _buildNoResults(double width, double height) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: width * 0.2, color: Colors.grey.shade300),
          SizedBox(height: height * 0.02),
          Text('No results found',
              style: TextStyle(
                fontSize: width * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              )),
          SizedBox(height: height * 0.01),
          Text('Try a different search',
              style: TextStyle(color: Colors.grey.shade400)),
        ],
      ),
    );
  }

  // ⭐️ Filters Panel
  Widget _buildFiltersPanel(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters',
                  style: TextStyle(
                    fontSize: width * 0.04,
                    fontWeight: FontWeight.bold,
                  )),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear'),
              ),
            ],
          ),
          SizedBox(height: height * 0.01),
          // Price range
          Text('💰 Price Range',
              style: TextStyle(
                fontSize: width * 0.035,
                fontWeight: FontWeight.bold,
              )),
          Row(
            children: [
              Text('\$${_minPrice.toStringAsFixed(0)}'),
              Expanded(
                child: RangeSlider(
                  values: RangeValues(_minPrice, _maxPrice),
                  min: 0,
                  max: 100000,
                  divisions: 100,
                  activeColor: AppColors.primary,
                  onChanged: (v) {
                    setState(() {
                      _minPrice = v.start;
                      _maxPrice = v.end;
                    });
                  },
                  onChangeEnd: (_) => _applyFilters(),
                ),
              ),
              Text('\$${_maxPrice.toStringAsFixed(0)}'),
            ],
          ),
          // Rating
          Text('⭐ Minimum Rating',
              style: TextStyle(
                fontSize: width * 0.035,
                fontWeight: FontWeight.bold,
              )),
          Row(
            children: [1, 2, 3, 4, 5].map((r) {
              final isSelected = _minRating == r;
              return GestureDetector(
                onTap: () {
                  setState(() => _minRating = isSelected ? 0 : r.toDouble());
                  _applyFilters();
                },
                child: Container(
                  margin: EdgeInsets.only(right: width * 0.02),
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.03, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.star,
                          color: isSelected
                              ? Colors.white
                              : AppColors.accentGold,
                          size: 14),
                      SizedBox(width: 3),
                      Text('$r',
                          style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: height * 0.01),
          // Sort
          Text('🔀 Sort By',
              style: TextStyle(
                fontSize: width * 0.035,
                fontWeight: FontWeight.bold,
              )),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              {'value': 'relevance', 'label': '🎯 Relevance'},
              {'value': 'price_low', 'label': '💰 Price ↑'},
              {'value': 'price_high', 'label': '💎 Price ↓'},
              {'value': 'rating', 'label': '⭐ Top Rated'},
              {'value': 'name', 'label': '🔤 A-Z'},
            ].map((s) {
              final isSelected = _sortBy == s['value'];
              return GestureDetector(
                onTap: () {
                  setState(() => _sortBy = s['value']!);
                  _applyFilters();
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: width * 0.035, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s['label']!,
                      style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                          fontSize: width * 0.028,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ⭐️ Results
  Widget _buildResults(double width, double height) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: width * 0.04, vertical: height * 0.01),
          child: Row(
            children: [
              Text('${_results.length} results',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontSize: width * 0.035,
                  )),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: width * 0.04),
            itemCount: _results.length,
            itemBuilder: (context, i) => _buildResultCard(_results[i], width, height),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> item, double width, double height) {
    final isLiked = _likedItems.contains(item['id']);

    return GestureDetector(
      onTap: () => _openDetails(item),
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.015),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: (item['imageUrl'] ?? '').toString().isNotEmpty
                  ? Image.network(
                item['imageUrl'],
                width: width * 0.28,
                height: width * 0.28,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: width * 0.28,
                  height: width * 0.28,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image),
                ),
              )
                  : Container(
                width: width * 0.28,
                height: width * 0.28,
                color: Colors.grey.shade200,
                child: const Icon(Icons.image),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(width * 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (item['type'] ?? '').toString().toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.005),
                    Text(
                      item['name'] ?? '',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.038,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: height * 0.005),
                    Row(
                      children: [
                        if ((item['rating'] ?? 0) > 0) ...[
                          Icon(Icons.star, color: AppColors.accentGold, size: 14),
                          SizedBox(width: 3),
                          Text(
                            (item['rating'] as num).toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.03,
                            ),
                          ),
                          SizedBox(width: width * 0.03),
                        ],
                        if ((item['price'] ?? 0) > 0)
                          Text(
                            '${item['currency']} ${(item['price'] as num).toStringAsFixed(0)}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.035,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: width * 0.03),
              child: GestureDetector(
                onTap: () => _toggleLike(item),
                child: Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.grey.shade400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(Map<String, dynamic> item) {
    Widget? screen;
    switch (item['type']) {
      case 'hotels':
        screen = HotelDetailsScreen(hotel: item);
        break;
      case 'tours':
        screen = TourDetailsScreen(tour: item);
        break;
      case 'beaches':
        screen = BeachDetailsScreen(beach: item);
        break;
      case 'mountains':
        screen = MountainDetailsScreen(mountain: item);
        break;
      case 'culture':
        screen = CultureDetailsScreen(culture: item);
        break;
      case 'food':
        screen = FoodDetailsScreen(food: item);
        break;
      case 'destinations':
        screen = DestinationDetailsScreen(destination: item);
        break;
    }

    if (screen != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen!));
    }
  }
}