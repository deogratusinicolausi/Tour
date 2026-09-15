import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/colors.dart';
import '../services/image_service.dart';
import 'hotels_list_screen.dart';
import 'explore_all_screen.dart';
import 'tours_list_screen.dart';
import 'beaches_list_screen.dart';
import 'mountains_list_screen.dart';
import 'culture_list_screen.dart';
import 'food_list_screen.dart';

class CategoryScreen extends StatefulWidget {
  final String categoryName;
  final String icon;

  const CategoryScreen({
    super.key,
    required this.categoryName,
    required this.icon,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedRegion = 'Tanzania';
  bool _isSearching = false;
  bool _isLoadingRegion = false;
  final Map<String, int> _galleryIndices = {};

  // All data organized by region
  final Map<String, List<Map<String, String>>> _data = {
    'Tanzania': [],
    'Africa': [],
    'World': [],
  };

  @override
  void initState() {
    super.initState();
    _loadCategoryData();
  }

  void _loadCategoryData() {
    // This will be populated based on category
    final data = _getDataForCategory(widget.categoryName);
    _data['Tanzania'] = data['Tanzania']!;
    _data['Africa'] = data['Africa']!;
    _data['World'] = data['World']!;
  }

  Map<String, List<Map<String, String>>> _getDataForCategory(String category) {
    switch (category) {
      case 'Mountains':
        return _mountainsData();
      case 'Safari':
        return _safariData();
      case 'Beaches':
        return _beachesData();
      case 'Hotels':
        return _hotelsData();
      case 'Culture':
        return _cultureData();
      case 'Food':
        return _foodData();
      default:
        return _mountainsData();
    }
  }

  // ⭐ MOUNTAINS DATA
  Map<String, List<Map<String, String>>> _mountainsData() {
    return {
      'Tanzania': [
        {
          'name': 'Mount Kilimanjaro',
          'location': 'Kilimanjaro Region',
          'height': '5,895 m',
          'url': 'https://www.tanzaniaparks.go.tz/kilimanjaro',
        },
        {
          'name': 'Mount Meru',
          'location': 'Arusha',
          'height': '4,566 m',
          'url': 'https://www.tanzaniaparks.go.tz/arusha',
        },
        {
          'name': 'Mount Hanang',
          'location': 'Manyara',
          'height': '3,420 m',
          'url': 'https://www.tanzaniaparks.go.tz',
        },
        {
          'name': 'Usambara Mountains',
          'location': 'Tanga',
          'height': '2,440 m',
          'url': 'https://www.tanzaniatourism.go.tz',
        },
      ],
      'Africa': [
        {
          'name': 'Mount Kenya',
          'location': 'Kenya',
          'height': '5,199 m',
          'url': 'https://www.magicalkenya.com',
        },
        {
          'name': 'Mount Rwenzori',
          'location': 'Uganda',
          'height': '5,109 m',
          'url': 'https://www.ugandawildlife.org',
        },
        {
          'name': 'Atlas Mountains',
          'location': 'Morocco',
          'height': '4,167 m',
          'url': 'https://www.visitmorocco.com',
        },
        {
          'name': 'Drakensberg',
          'location': 'South Africa',
          'height': '3,482 m',
          'url': 'https://www.southafrica.net',
        },
      ],
      'World': [
        {
          'name': 'Mount Everest',
          'location': 'Nepal/China',
          'height': '8,848 m',
          'url': 'https://www.nepal tourism.com',
        },
        {
          'name': 'Matterhorn',
          'location': 'Switzerland',
          'height': '4,478 m',
          'url': 'https://www.myswitzerland.com',
        },
        {
          'name': 'Mount Fuji',
          'location': 'Japan',
          'height': '3,776 m',
          'url': 'https://www.japan.travel',
        },
        {
          'name': 'Rocky Mountains',
          'location': 'USA',
          'height': '4,401 m',
          'url': 'https://www.nps.gov',
        },
      ],
    };
  }

  // ⭐ SAFARI DATA
  Map<String, List<Map<String, String>>> _safariData() {
    return {
      'Tanzania': [
        {
          'name': 'Serengeti National Park',
          'location': 'Mara Region',
          'height': 'Great Migration',
          'url': 'https://www.serengeti.com',
        },
        {
          'name': 'Ngorongoro Crater',
          'location': 'Arusha',
          'height': 'UNESCO Site',
          'url': 'https://www.ngorongorocrater.org',
        },
        {
          'name': 'Tarangire National Park',
          'location': 'Manyara',
          'height': 'Elephant Paradise',
          'url': 'https://www.tanzaniaparks.go.tz',
        },
        {
          'name': 'Ruaha National Park',
          'location': 'Iringa',
          'height': 'Largest Park',
          'url': 'https://www.tanzaniaparks.go.tz',
        },
      ],
      'Africa': [
        {
          'name': 'Maasai Mara',
          'location': 'Kenya',
          'height': 'Big Five',
          'url': 'https://www.maasaimara.com',
        },
        {
          'name': 'Kruger National Park',
          'location': 'South Africa',
          'height': 'Big Five',
          'url': 'https://www.sanparks.org',
        },
        {
          'name': 'Chobe National Park',
          'location': 'Botswana',
          'height': 'Elephant Capital',
          'url': 'https://www.botswana tourism.com',
        },
        {
          'name': 'Etosha National Park',
          'location': 'Namibia',
          'height': 'Salt Pan',
          'url': 'https://www.namibia tourism.com',
        },
      ],
      'World': [
        {
          'name': 'Yellowstone',
          'location': 'USA',
          'height': 'First National Park',
          'url': 'https://www.nps.gov/yell',
        },
        {
          'name': 'Kaziranga',
          'location': 'India',
          'height': 'Rhino Home',
          'url': 'https://www.kaziranganationalpark.com',
        },
        {
          'name': 'Komodo National Park',
          'location': 'Indonesia',
          'height': 'Dragon Home',
          'url': 'https://www.komodonationalpark.org',
        },
        {
          'name': 'Kakadu',
          'location': 'Australia',
          'height': 'Aboriginal Culture',
          'url': 'https://www.parksaustralia.gov.au',
        },
      ],
    };
  }

  // ⭐ BEACHES DATA
  Map<String, List<Map<String, String>>> _beachesData() {
    return {
      'Tanzania': [
        {
          'name': 'Nungwi Beach',
          'location': 'Zanzibar',
          'height': 'White Sand',
          'url': 'https://www.zanzibartourism.go.tz',
        },
        {
          'name': 'Kendwa Beach',
          'location': 'Zanzibar',
          'height': 'Sunset Views',
          'url': 'https://www.zanzibartourism.go.tz',
        },
        {
          'name': 'Paje Beach',
          'location': 'Zanzibar',
          'height': 'Kitesurfing',
          'url': 'https://www.zanzibartourism.go.tz',
        },
        {
          'name': 'Kigamboni Beach',
          'location': 'Dar es Salaam',
          'height': 'Local Favorite',
          'url': 'https://www.tanzaniatourism.go.tz',
        },
      ],
      'Africa': [
        {
          'name': 'Diani Beach',
          'location': 'Kenya',
          'height': 'White Sand',
          'url': 'https://www.magicalkenya.com',
        },
        {
          'name': 'Cape Town Beaches',
          'location': 'South Africa',
          'height': 'Camps Bay',
          'url': 'https://www.southafrica.net',
        },
        {
          'name': 'Sharm El Sheikh',
          'location': 'Egypt',
          'height': 'Red Sea',
          'url': 'https://www.egypt.travel',
        },
      ],
      'World': [
        {
          'name': 'Maldives',
          'location': 'Maldives',
          'height': 'Overwater Bungalows',
          'url': 'https://www.visitmaldives.com',
        },
        {
          'name': 'Bora Bora',
          'location': 'French Polynesia',
          'height': 'Lagoon Paradise',
          'url': 'https://www.tahititourisme.com',
        },
        {
          'name': 'Bondi Beach',
          'location': 'Australia',
          'height': 'Surfing',
          'url': 'https://www.australia.com',
        },
      ],
    };
  }

  // ⭐ HOTELS DATA
  Map<String, List<Map<String, String>>> _hotelsData() {
    return {
      'Tanzania': [
        {
          'name': 'Four Seasons Safari Lodge',
          'location': 'Serengeti',
          'height': 'Luxury',
          'url': 'https://www.fourseasons.com/serengeti',
        },
        {
          'name': 'Serena Hotels',
          'location': 'Dar es Salaam',
          'height': '5-Star',
          'url': 'https://www.serenahotels.com',
        },
        {
          'name': 'Hyatt Regency',
          'location': 'Dar es Salaam',
          'height': '5-Star',
          'url': 'https://www.hyatt.com',
        },
        {
          'name': 'Meliá Zanzibar',
          'location': 'Zanzibar',
          'height': 'Resort',
          'url': 'https://www.melia.com',
        },
        {
          'name': 'Kilimanjaro Kempinski',
          'location': 'Dar es Salaam',
          'height': '5-Star',
          'url': 'https://www.kempinski.com',
        },
        {
          'name': 'Arusha Coffee Lodge',
          'location': 'Arusha',
          'height': 'Boutique',
          'url': 'https://www.arushacoffeelodge.com',
        },
        {
          'name': 'Ngorongoro Serena',
          'location': 'Ngorongoro',
          'height': 'Safari Lodge',
          'url': 'https://www.serenahotels.com',
        },
        {
          'name': 'Mount Meru Hotel',
          'location': 'Arusha',
          'height': '4-Star',
          'url': 'https://www.mountmeruhotel.com',
        },
      ],
      'Africa': [
        {
          'name': 'Giraffe Manor',
          'location': 'Kenya',
          'height': 'Unique',
          'url': 'https://www.thesafaricollection.com',
        },
        {
          'name': 'Singita',
          'location': 'South Africa',
          'height': 'Ultra Luxury',
          'url': 'https://www.singita.com',
        },
        {
          'name': 'The Silo Hotel',
          'location': 'Cape Town',
          'height': '5-Star',
          'url': 'https://www.thesilohotel.com',
        },
        {
          'name': 'Angama Mara',
          'location': 'Kenya',
          'height': 'Luxury',
          'url': 'https://www.angama.com',
        },
        {
          'name': 'Bisate Lodge',
          'location': 'Rwanda',
          'height': 'Eco Luxury',
          'url': 'https://www.wilderness-safaris.com',
        },
      ],
      'World': [
        {
          'name': 'Burj Al Arab',
          'location': 'Dubai',
          'height': '7-Star',
          'url': 'https://www.jumeirah.com',
        },
        {
          'name': 'Marina Bay Sands',
          'location': 'Singapore',
          'height': '5-Star',
          'url': 'https://www.marinabaysands.com',
        },
        {
          'name': 'Ritz Paris',
          'location': 'France',
          'height': 'Palace',
          'url': 'https://www.ritzparis.com',
        },
        {
          'name': 'The Plaza',
          'location': 'New York',
          'height': 'Historic',
          'url': 'https://www.theplazany.com',
        },
        {
          'name': 'Atlantis The Palm',
          'location': 'Dubai',
          'height': 'Resort',
          'url': 'https://www.atlantis.com',
        },
      ],
    };
  }

  // ⭐ CULTURE DATA
  Map<String, List<Map<String, String>>> _cultureData() {
    return {
      'Tanzania': [
        {
          'name': 'Maasai Boma',
          'location': 'Ngorongoro',
          'height': 'Indigenous',
          'url': 'https://www.tanzaniatourism.go.tz',
        },
        {
          'name': 'Stone Town',
          'location': 'Zanzibar',
          'height': 'UNESCO',
          'url': 'https://www.zanzibartourism.go.tz',
        },
        {
          'name': 'Hadza Tribe',
          'location': 'Lake Eyasi',
          'height': 'Hunter-Gatherers',
          'url': 'https://www.tanzaniatourism.go.tz',
        },
      ],
      'Africa': [
        {
          'name': 'Pyramids of Giza',
          'location': 'Egypt',
          'height': 'Ancient Wonder',
          'url': 'https://www.egypt.travel',
        },
        {
          'name': 'Great Zimbabwe',
          'location': 'Zimbabwe',
          'height': 'Ancient City',
          'url': 'https://www.zimbabwetourism.net',
        },
      ],
      'World': [
        {
          'name': 'Taj Mahal',
          'location': 'India',
          'height': 'Wonder',
          'url': 'https://www.incredibleindia.org',
        },
        {
          'name': 'Machu Picchu',
          'location': 'Peru',
          'height': 'Inca Empire',
          'url': 'https://www.peru.travel',
        },
      ],
    };
  }

  // ⭐ FOOD DATA
  Map<String, List<Map<String, String>>> _foodData() {
    return {
      'Tanzania': [
        {
          'name': 'Zanzibar Pizza',
          'location': 'Zanzibar',
          'height': 'Street Food',
          'url': 'https://www.zanzibartourism.go.tz',
        },
        {
          'name': 'Ugali & Nyama Choma',
          'location': 'Nationwide',
          'height': 'National Dish',
          'url': 'https://www.tanzaniatourism.go.tz',
        },
        {
          'name': 'Pilau & Biryani',
          'location': 'Dar es Salaam',
          'height': 'Swahili Cuisine',
          'url': 'https://www.tanzaniatourism.go.tz',
        },
      ],
      'Africa': [
        {
          'name': 'Jollof Rice',
          'location': 'West Africa',
          'height': 'Signature',
          'url': 'https://www.africa.com',
        },
        {
          'name': 'Moroccan Tagine',
          'location': 'Morocco',
          'height': 'Traditional',
          'url': 'https://www.visitmorocco.com',
        },
      ],
      'World': [
        {
          'name': 'Sushi',
          'location': 'Japan',
          'height': 'Iconic',
          'url': 'https://www.japan.travel',
        },
        {
          'name': 'Pasta',
          'location': 'Italy',
          'height': 'Classic',
          'url': 'https://www.italia.it',
        },
      ],
    };
  }

  List<Map<String, String>> get _currentList {
    final list = _data[_selectedRegion] ?? [];
    if (_searchController.text.isEmpty) return list;

    return list.where((item) {
      return item['name']!.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item['location']!.toLowerCase().contains(_searchController.text.toLowerCase());
    }).toList();
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
                        widget.icon,
                        style: TextStyle(fontSize: width * 0.07),
                      ),
                      SizedBox(width: width * 0.02),
                      Expanded(
                        child: Text(
                          widget.categoryName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: width * 0.06,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: height * 0.02),

                  // Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _isSearching = true;
                        });
                        // Simulate search delay
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            setState(() {
                              _isSearching = false;
                            });
                          }
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search ${widget.categoryName.toLowerCase()} worldwide...',
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search, color: AppColors.primary),
                        suffixIcon: _isSearching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
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

            SizedBox(height: height * 0.02),

            // ===== REGION TABS =====
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Row(
                children: ['Tanzania', 'Africa', 'World'].map((region) {
                  final isSelected = _selectedRegion == region;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        setState(() => _isLoadingRegion = true);
                        // Artificial delay for smooth transition
                        await Future.delayed(const Duration(milliseconds: 300));
                        if (mounted) {
                          setState(() {
                            _selectedRegion = region;
                            _isLoadingRegion = false;
                          });
                        }
                      },
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

            SizedBox(height: height * 0.02),

            // ===== RESULTS COUNT =====
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Row(
                children: [
                  Text(
                    '${_currentList.length} ${widget.categoryName} in $_selectedRegion',
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
              child: _isLoadingRegion
                  ? const Center(child: CircularProgressIndicator())
                  : _currentList.isEmpty
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
                itemCount: _currentList.length,
                itemBuilder: (context, index) {
                  final item = _currentList[index];
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
     onTap: () {
       if (widget.categoryName == 'Hotels') {
         Navigator.push(
           context,
           MaterialPageRoute(builder: (_) => const HotelsListScreen()),
         );
       } else if (widget.categoryName == 'Safari') {
         Navigator.push(
           context,
           MaterialPageRoute(builder: (_) => const ToursListScreen()),
         );
       } else if (widget.categoryName == 'Beaches') {
         Navigator.push(
           context,
           MaterialPageRoute(builder: (_) => const BeachesListScreen()),
         );
       } else if (widget.categoryName == 'Mountains') {
         Navigator.push(
           context,
           MaterialPageRoute(builder: (_) => const MountainsListScreen()),
         );
       } else if (widget.categoryName == 'Culture') {
         Navigator.push(
           context,
           MaterialPageRoute(builder: (_) => const CultureListScreen()),
         );
       } else if (widget.categoryName == 'Food') {
         Navigator.push(
           context,
           MaterialPageRoute(builder: (_) => const FoodListScreen()),
         );
       } else {
         Navigator.push(
           context,
           MaterialPageRoute(
             builder: (_) => CategoryScreen(
               categoryName: widget.categoryName,
               icon: widget.icon,
             ),
           ),
         );

       }
     },
     child: Container(
       margin: EdgeInsets.only(bottom: height * 0.02),
       decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(20),
         boxShadow: [
           BoxShadow(
             color: Colors.black.withOpacity(0.08),
             blurRadius: 15,
             offset: const Offset(0, 5),
           ),
         ],
       ),
       child: Column(
         children: [
           // ⭐ Multi-image gallery with loading
           ClipRRect(
             borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
             child: _buildImageGallery(item['name']!, width, height),
           ),
           Padding(
             padding: EdgeInsets.all(width * 0.04),
             child: Row(
               children: [
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         item['name']!,
                         style: TextStyle(
                           fontSize: width * 0.045,
                           fontWeight: FontWeight.bold,
                           color: Colors.grey.shade800,
                         ),
                       ),
                       SizedBox(height: height * 0.005),
                       Row(
                         children: [
                           Icon(Icons.location_on, size: width * 0.035, color: Colors.grey.shade500),
                           SizedBox(width: width * 0.01),
                           Text(
                             item['location']!,
                             style: TextStyle(color: Colors.grey.shade500, fontSize: width * 0.03),
                           ),
                         ],
                       ),
                     ],
                   ),
                 ),
                 Container(
                   padding: EdgeInsets.all(width * 0.03),
                   decoration: BoxDecoration(
                     color: AppColors.primary.withOpacity(0.1),
                     shape: BoxShape.circle,
                   ),
                   child: Icon(
                     Icons.arrow_forward,
                     color: AppColors.primary,
                     size: width * 0.05,
                   ),
                 ),
               ],
             ),
           ),
         ],
       ),
     ),
   );
 }

 Widget _buildImageGallery(String query, double width, double height) {
   return _CardImageGallery(query: query, height: height * 0.25);
 }
}

class _CardImageGallery extends StatefulWidget {
  final String query;
  final double height;

  const _CardImageGallery({required this.query, required this.height});

  @override
  State<_CardImageGallery> createState() => _CardImageGalleryState();
}

class _CardImageGalleryState extends State<_CardImageGallery> {
  Future<List<Map<String, dynamic>>>? _future;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = ImageService().searchPhotos(widget.query);
  }

  @override
  void didUpdateWidget(covariant _CardImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      _future = ImageService().searchPhotos(widget.query);
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        // ⭐ LOADING
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: widget.height,
            color: Colors.grey.shade100,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0D47A1)),
                  SizedBox(height: 10),
                  Text('Loading from Pexels...',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          );
        }

        // ⭐ ERROR
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            height: widget.height,
            color: Colors.grey.shade100,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
                  SizedBox(height: 5),
                  Text('No images from Pexels',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          );
        }

        // ⭐ SHOW IMAGE GALLERY (Swipeable Carousel)
        final photos = snapshot.data!;
        final displayCount = photos.length > 5 ? 5 : photos.length;

        return Stack(
          alignment: Alignment.bottomCenter,
          children: [
            SizedBox(
              height: widget.height,
              child: PageView.builder(
                itemCount: displayCount,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return Image.network(
                    photos[index]['src']['large'],
                    height: widget.height,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: widget.height,
                        color: Colors.grey.shade100,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: widget.height,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
            if (displayCount > 1)
              Positioned(
                bottom: 10,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(displayCount, (index) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 12 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _currentIndex == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
    );
  }
}