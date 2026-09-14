import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import 'hotel_details_screen.dart';

class HotelsListScreen extends StatefulWidget {
  const HotelsListScreen({super.key});

  @override
  State<HotelsListScreen> createState() => _HotelsListScreenState();
}

class _HotelsListScreenState extends State<HotelsListScreen> {
  final _service = FirestoreService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'recent'; // recent, price_low, price_high, rating
  bool _isGridView = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterAndSort(
      List<Map<String, dynamic>> all) {
    var list = all.where((h) {
      final matchSearch = _searchQuery.isEmpty ||
          (h['name'] ?? '').toString().toLowerCase().contains(_searchQuery) ||
          (h['location'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery) ||
          (h['destinationName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(_searchQuery);
      return matchSearch;
    }).toList();

    switch (_sortBy) {
      case 'price_low':
        list.sort((a, b) =>
            ((a['priceFrom'] ?? 0) as num)
                .compareTo((b['priceFrom'] ?? 0) as num));
        break;
      case 'price_high':
        list.sort((a, b) =>
            ((b['priceFrom'] ?? 0) as num)
                .compareTo((a['priceFrom'] ?? 0) as num));
        break;
      case 'rating':
        list.sort((a, b) =>
            ((b['rating'] ?? 0) as num).compareTo((a['rating'] ?? 0) as num));
        break;
      default:
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('🏨 Hotels & Lodges'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
        ],
      ),
      body: Column(
        children: [
          // ⭐️ SEARCH + SORT
          Container(
            padding: EdgeInsets.all(width * 0.04),
            color: AppColors.primary,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search hotels...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(vertical: height * 0.015),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                          : null,
                    ),
                  ),
                ),
                SizedBox(height: height * 0.015),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      {'key': 'recent', 'label': '🕐 Recent', 'val': 'recent'},
                      {'key': 'price_low', 'label': '💰 Price ↑', 'val': 'price_low'},
                      {'key': 'price_high', 'label': '💎 Price ↓', 'val': 'price_high'},
                      {'key': 'rating', 'label': '⭐ Top Rated', 'val': 'rating'},
                    ].map((sort) {
                      final isSelected = _sortBy == sort['val'];
                      return GestureDetector(
                        onTap: () => setState(() => _sortBy = sort['val']!),
                        child: Container(
                          margin: EdgeInsets.only(right: width * 0.02),
                          padding: EdgeInsets.symmetric(
                              horizontal: width * 0.035,
                              vertical: height * 0.008),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accentGold
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            sort['label']!,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.black
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.026,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ⭐️ COUNT
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: width * 0.04, vertical: height * 0.01),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getHotels(),
              builder: (context, snapshot) {
                final count = snapshot.data?.length ?? 0;
                return Row(
                  children: [
                    Text(
                      '${_filterAndSort(snapshot.data ?? []).length} hotels',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: width * 0.035,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // ⭐️ LIST/GRID
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.getHotels(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final all = snapshot.data ?? [];
                final hotels = _filterAndSort(all);

                if (hotels.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(width * 0.1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.hotel_outlined,
                            size: width * 0.15,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: height * 0.03),
                        Text(
                          _searchQuery.isEmpty ? 'No hotels yet' : 'No results found',
                          style: TextStyle(
                            fontSize: width * 0.05,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        SizedBox(height: height * 0.01),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: width * 0.1),
                          child: Text(
                            _searchQuery.isEmpty
                                ? 'Hotels added by admin will appear here'
                                : 'Try a different search',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: width * 0.035,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (_isGridView) {
                  return GridView.builder(
                    padding: EdgeInsets.all(width * 0.04),
                    gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: width * 0.03,
                      mainAxisSpacing: width * 0.03,
                      childAspectRatio: 0.72,
                    ),
                    itemCount: hotels.length,
                    itemBuilder: (context, i) =>
                        _buildGridCard(hotels[i], width, height),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(width * 0.04),
                  itemCount: hotels.length,
                  itemBuilder: (context, i) =>
                      _buildListCard(hotels[i], width, height),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ⭐️ GRID CARD
  Widget _buildGridCard(
      Map<String, dynamic> h, double width, double height) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HotelDetailsScreen(hotel: h),
          ),
        );
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  (h['imageUrl'] ?? '').toString().isNotEmpty
                      ? Image.network(
                    h['imageUrl'],
                    height: height * 0.13,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          height: height * 0.13,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.primary.withOpacity(0.2),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.hotel_outlined,
                                size: width * 0.1, color: AppColors.primary),
                          ),
                        ),
                  )
                      : Container(
                          height: height * 0.13,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.1),
                                AppColors.primary.withOpacity(0.2),
                              ],
                            ),
                          ),
                          child: Center(
                            child: Icon(Icons.hotel_outlined,
                                size: width * 0.1, color: AppColors.primary),
                          ),
                        ),
                  if (h['featured'] == true)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '⭐ FEATURED',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  if (h['rating'] != null && (h['rating'] as num) > 0)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star,
                                color: AppColors.accentGold, size: 11),
                            const SizedBox(width: 3),
                            Text(
                              (h['rating'] as num).toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
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

            // Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(width * 0.025),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h['name'] ?? 'Unnamed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.032,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: width * 0.025,
                            color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            h['location'] ?? h['destinationName'] ?? '',
                            style: TextStyle(
                              fontSize: width * 0.022,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.005),
                    if ((h['priceFrom'] ?? 0) > 0)
                      Text(
                        '${h['currency'] ?? 'USD'} ${(h['priceFrom'] as num).toStringAsFixed(0)}+',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.032,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ⭐️ LIST CARD
  Widget _buildListCard(
      Map<String, dynamic> h, double width, double height) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => HotelDetailsScreen(hotel: h),
          ),
        );
      },
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
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16)),
              child: Stack(
                children: [
                  (h['imageUrl'] ?? '').toString().isNotEmpty
                      ? Image.network(
                    h['imageUrl'],
                    width: width * 0.3,
                    height: width * 0.3,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: width * 0.3,
                      height: width * 0.3,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.hotel),
                    ),
                  )
                      : Container(
                    width: width * 0.3,
                    height: width * 0.3,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.hotel),
                  ),
                  if (h['featured'] == true)
                    Positioned(
                      top: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          '⭐',
                          style: TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(width * 0.03),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h['name'] ?? 'Unnamed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: width * 0.04,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: height * 0.005),
                    Row(
                      children: [
                        Icon(Icons.location_on,
                            size: width * 0.03,
                            color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            h['location'] ?? h['destinationName'] ?? '',
                            style: TextStyle(
                              fontSize: width * 0.028,
                              color: Colors.grey.shade500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.005),
                    if ((h['rating'] ?? 0) > 0)
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.accentGold, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            (h['rating'] as num).toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: width * 0.03,
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    if ((h['priceFrom'] ?? 0) > 0)
                      Text(
                        '${h['currency'] ?? 'USD'} ${(h['priceFrom'] as num).toStringAsFixed(0)}+',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.035,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}