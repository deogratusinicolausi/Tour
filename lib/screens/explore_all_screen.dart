import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/colors.dart';
import '../services/image_service.dart';
import 'category_screen.dart';

class ExploreAllScreen extends StatefulWidget {
  const ExploreAllScreen({super.key, required String categoryFilter});

  @override
  State<ExploreAllScreen> createState() => _ExploreAllScreenState();
}

class _ExploreAllScreenState extends State<ExploreAllScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedRegion = 'Tanzania';

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

  List<Map<String, String>> get _filteredList {
    return allDestinations.where((item) {
      final matchCategory = _selectedCategory == 'All' ||
          item['category'] == _selectedCategory;
      final matchRegion = item['region'] == _selectedRegion;
      final matchSearch = _searchController.text.isEmpty ||
          item['name']!.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item['location']!.toLowerCase().contains(_searchController.text.toLowerCase());
      return matchCategory && matchRegion && matchSearch;
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            Container(
              padding: EdgeInsets.all(width * 0.04),
              decoration: BoxDecoration(
                gradient: AppColors.mainGradient,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      ),
                      Text(
                        '🌍',
                        style: TextStyle(fontSize: width * 0.07),
                      ),
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
                    ],
                  ),
                  SizedBox(height: height * 0.015),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search anything worldwide...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search, color: AppColors.primary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: height * 0.018),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.015),

            // ===== CATEGORY CHIPS =====
            SizedBox(
              height: height * 0.055,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                children: ['All', 'Hotels', 'Safari', 'Beaches', 'Mountains', 'Culture', 'Food']
                    .map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: width * 0.02),
                      padding: EdgeInsets.symmetric(horizontal: width * 0.04),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          cat,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
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

            SizedBox(height: height * 0.015),

            // ===== REGION TABS =====
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
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
                          color: isSelected ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ]
                              : [],
                        ),
                        child: Text(
                          region,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey.shade700,
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

            SizedBox(height: height * 0.015),

            // ===== COUNT =====
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Row(
                children: [
                  Text(
                    '${_filteredList.length} results in $_selectedRegion',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: width * 0.035,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: height * 0.01),

            // ===== LIST =====
            Expanded(
              child: _filteredList.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: width * 0.2, color: Colors.grey.shade300),
                    SizedBox(height: height * 0.02),
                    Text(
                      'No results found',
                      style: TextStyle(
                        fontSize: width * 0.05,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                itemCount: _filteredList.length,
                itemBuilder: (context, index) {
                  final item = _filteredList[index];
                  return _buildCard(item, width, height);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, String> item, double width, double height) {
    return GestureDetector(
      onTap: () => _openUrl(item['url']!),
      child: Container(
        margin: EdgeInsets.only(bottom: height * 0.02),
        padding: EdgeInsets.all(width * 0.03),
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
            // Image from API
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: width * 0.25,
                height: width * 0.25,
                child: _buildImage(item['name']!),
              ),
            ),
            SizedBox(width: width * 0.03),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(_getIconForCategory(item['category']!), style: TextStyle(fontSize: width * 0.04)),
                      SizedBox(width: width * 0.01),
                      Text(
                        item['category']!,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: width * 0.028,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.005),
                  Text(
                    item['name']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: width * 0.04,
                      color: Colors.grey.shade800,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: height * 0.005),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: width * 0.03, color: Colors.grey.shade500),
                      SizedBox(width: width * 0.01),
                      Text(
                        item['location']!,
                        style: TextStyle(color: Colors.grey.shade500, fontSize: width * 0.028),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: width * 0.04,
            ),
          ],
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
}