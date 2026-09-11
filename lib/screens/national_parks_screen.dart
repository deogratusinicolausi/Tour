import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/colors.dart';

class NationalParksScreen extends StatefulWidget {
  const NationalParksScreen({super.key});

  @override
  State<NationalParksScreen> createState() => _NationalParksScreenState();
}

class _NationalParksScreenState extends State<NationalParksScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  final List<Map<String, String>> allParks = [
    // ===== TANZANIA =====
    {
      'name': 'Serengeti National Park',
      'country': 'Tanzania',
      'region': 'Africa',
      'url': 'https://www.serengeti.com',
      'image': 'https://images.unsplash.com/photo-1516426122078-c23e76319801?w=800',
      'desc': 'Home of the Great Migration'
    },
    {
      'name': 'Ngorongoro Crater',
      'country': 'Tanzania',
      'region': 'Africa',
      'url': 'https://www.ngorongorocrater.org',
      'image': 'https://images.unsplash.com/photo-1523805009345-7448845a9e53?w=800',
      'desc': 'The 8th Wonder of the World'
    },
    {
      'name': 'Mount Kilimanjaro',
      'country': 'Tanzania',
      'region': 'Africa',
      'url': 'https://www.tanzaniaparks.go.tz/kilimanjaro',
      'image': 'https://images.unsplash.com/photo-1544731612-de6a63c6cf1a?w=800',
      'desc': 'Roof of Africa - 5,895m'
    },
    {
      'name': 'Tarangire National Park',
      'country': 'Tanzania',
      'region': 'Africa',
      'url': 'https://www.tanzaniaparks.go.tz/tarangire',
      'image': 'https://images.unsplash.com/photo-1547471080-7cc2caa01a7e?w=800',
      'desc': 'Land of Giants - Baobab trees'
    },
    {
      'name': 'Lake Manyara National Park',
      'country': 'Tanzania',
      'region': 'Africa',
      'url': 'https://www.tanzaniaparks.go.tz/manyara',
      'image': 'https://images.unsplash.com/photo-1501785888041-af3ef285b470?w=800',
      'desc': 'Tree-climbing lions'
    },
    {
      'name': 'Ruaha National Park',
      'country': 'Tanzania',
      'region': 'Africa',
      'url': 'https://www.tanzaniaparks.go.tz/ruaha',
      'image': 'https://images.unsplash.com/photo-1535941339077-2dd1c7963098?w=800',
      'desc': 'Largest park in Tanzania'
    },
    {
      'name': 'Selous Game Reserve',
      'country': 'Tanzania',
      'region': 'Africa',
      'url': 'https://www.tanzaniaparks.go.tz/selous',
      'image': 'https://images.unsplash.com/photo-1568393691084-201c1e9c0d0e?w=800',
      'desc': 'UNESCO World Heritage Site'
    },

    // ===== KENYA =====
    {
      'name': 'Maasai Mara',
      'country': 'Kenya',
      'region': 'Africa',
      'url': 'https://www.maasaimara.com',
      'image': 'https://images.unsplash.com/photo-1549366021-9f761d450615?w=800',
      'desc': 'Greatest wildlife spectacle'
    },
    {
      'name': 'Amboseli National Park',
      'country': 'Kenya',
      'region': 'Africa',
      'url': 'https://www.amboseli.com',
      'image': 'https://images.unsplash.com/photo-1547970810-dc1eac37d174?w=800',
      'desc': 'Home of giant elephants'
    },

    // ===== RWANDA =====
    {
      'name': 'Volcanoes National Park',
      'country': 'Rwanda',
      'region': 'Africa',
      'url': 'https://www.volcanoesnationalpark.org',
      'image': 'https://images.unsplash.com/photo-1580217593608-61931cefc821?w=800',
      'desc': 'Mountain gorillas'
    },

    // ===== UGANDA =====
    {
      'name': 'Bwindi Impenetrable Forest',
      'country': 'Uganda',
      'region': 'Africa',
      'url': 'https://www.bwindiforestnationalpark.com',
      'image': 'https://images.unsplash.com/photo-1571401835393-8c5f35328320?w=800',
      'desc': 'Gorilla trekking paradise'
    },

    // ===== SOUTH AFRICA =====
    {
      'name': 'Kruger National Park',
      'country': 'South Africa',
      'region': 'Africa',
      'url': 'https://www.sanparks.org/parks/kruger',
      'image': 'https://images.unsplash.com/photo-1523805009345-7448845a9e53?w=800',
      'desc': 'Big Five safari'
    },

    // ===== NAMIBIA =====
    {
      'name': 'Etosha National Park',
      'country': 'Namibia',
      'region': 'Africa',
      'url': 'https://www.etoshanationalpark.org',
      'image': 'https://images.unsplash.com/photo-1516026672322-bc52d61a55d5?w=800',
      'desc': 'Salt pan wildlife'
    },

    // ===== BOTSWANA =====
    {
      'name': 'Chobe National Park',
      'country': 'Botswana',
      'region': 'Africa',
      'url': 'https://www.chobenationalpark.com',
      'image': 'https://images.unsplash.com/photo-1521651201144-634f700b36ef?w=800',
      'desc': 'Elephant capital of the world'
    },

    // ===== USA =====
    {
      'name': 'Yellowstone National Park',
      'country': 'USA',
      'region': 'North America',
      'url': 'https://www.nps.gov/yell',
      'image': 'https://images.unsplash.com/photo-1533460004989-cef01064af7e?w=800',
      'desc': 'First national park in the world'
    },
    {
      'name': 'Yosemite National Park',
      'country': 'USA',
      'region': 'North America',
      'url': 'https://www.nps.gov/yose',
      'image': 'https://images.unsplash.com/photo-1426604966848-d7adac402bff?w=800',
      'desc': 'Giant sequoias and waterfalls'
    },
    {
      'name': 'Grand Canyon',
      'country': 'USA',
      'region': 'North America',
      'url': 'https://www.nps.gov/grca',
      'image': 'https://images.unsplash.com/photo-1615551043360-33de8b5f410c?w=800',
      'desc': 'One of the 7 Natural Wonders'
    },

    // ===== CANADA =====
    {
      'name': 'Banff National Park',
      'country': 'Canada',
      'region': 'North America',
      'url': 'https://www.pc.gc.ca/en/pn-np/ab/banff',
      'image': 'https://images.unsplash.com/photo-1503614472-8c93d56e92ce?w=800',
      'desc': 'Rocky Mountain beauty'
    },

    // ===== BRAZIL =====
    {
      'name': 'Iguaçu National Park',
      'country': 'Brazil',
      'region': 'South America',
      'url': 'https://www.iguassu.tur.br',
      'image': 'https://images.unsplash.com/photo-1583417319070-4a69db38a482?w=800',
      'desc': 'Massive waterfalls'
    },

    // ===== PERU =====
    {
      'name': 'Manú National Park',
      'country': 'Peru',
      'region': 'South America',
      'url': 'https://www.manupark.com',
      'image': 'https://images.unsplash.com/photo-1526392060635-9d6019884377?w=800',
      'desc': 'Amazon rainforest gem'
    },

    // ===== INDIA =====
    {
      'name': 'Jim Corbett National Park',
      'country': 'India',
      'region': 'Asia',
      'url': 'https://www.jimcorbettnationalpark.in',
      'image': 'https://images.unsplash.com/photo-1615963244664-5b845b2025ee?w=800',
      'desc': 'Land of tigers'
    },
    {
      'name': 'Kaziranga National Park',
      'country': 'India',
      'region': 'Asia',
      'url': 'https://www.kaziranganationalpark.com',
      'image': 'https://images.unsplash.com/photo-1589656966895-2f33e7653819?w=800',
      'desc': 'One-horned rhinos'
    },

    // ===== NEPAL =====
    {
      'name': 'Chitwan National Park',
      'country': 'Nepal',
      'region': 'Asia',
      'url': 'https://www.chitwannationalpark.gov.np',
      'image': 'https://images.unsplash.com/photo-1544735716-392fe2489ffa?w=800',
      'desc': 'Jungle safari in Nepal'
    },

    // ===== INDONESIA =====
    {
      'name': 'Komodo National Park',
      'country': 'Indonesia',
      'region': 'Asia',
      'url': 'https://www.komodonationalpark.org',
      'image': 'https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?w=800',
      'desc': 'Home of Komodo dragons'
    },

    // ===== AUSTRALIA =====
    {
      'name': 'Kakadu National Park',
      'country': 'Australia',
      'region': 'Oceania',
      'url': 'https://www.parksaustralia.gov.au/kakadu',
      'image': 'https://images.unsplash.com/photo-1529108190281-9a4f620bc2d8?w=800',
      'desc': 'Aboriginal culture & wildlife'
    },

    // ===== NEW ZEALAND =====
    {
      'name': 'Fiordland National Park',
      'country': 'New Zealand',
      'region': 'Oceania',
      'url': 'https://www.doc.govt.nz/fiordland',
      'image': 'https://images.unsplash.com/photo-1469521669194-babb45599def?w=800',
      'desc': 'Milford Sound paradise'
    },

    // ===== NORWAY =====
    {
      'name': 'Jotunheimen National Park',
      'country': 'Norway',
      'region': 'Europe',
      'url': 'https://www.nasjonalparken.no',
      'image': 'https://images.unsplash.com/photo-1601439678777-b2b3c56fa627?w=800',
      'desc': 'Home of the giants'
    },

    // ===== ICELAND =====
    {
      'name': 'Vatnajökull National Park',
      'country': 'Iceland',
      'region': 'Europe',
      'url': 'https://www.vatnajokullnationalpark.is',
      'image': 'https://images.unsplash.com/photo-1504893524553-b855bce32c67?w=800',
      'desc': 'Glaciers and volcanoes'
    },
  ];

  List<Map<String, String>> filteredParks = [];

  @override
  void initState() {
    super.initState();
    filteredParks = allParks;
  }

  void _filterParks(String query) {
    setState(() {
      filteredParks = allParks.where((park) {
        final matchesSearch = park['name']!.toLowerCase().contains(query.toLowerCase()) ||
            park['country']!.toLowerCase().contains(query.toLowerCase());

        final matchesFilter = _selectedFilter == 'All' ||
            park['region'] == _selectedFilter ||
            park['country'] == _selectedFilter;

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _openWebsite(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open: $url')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Column(
          children: [
            // ===== HEADER =====
            _buildHeader(width, height),

            // ===== SEARCH BAR =====
            _buildSearchBar(width, height),

            // ===== FILTER CHIPS =====
            _buildFilters(width, height),

            // ===== PARKS COUNT =====
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.05),
              child: Row(
                children: [
                  Text(
                    '${filteredParks.length} Parks Found',
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

            // ===== PARKS LIST =====
            Expanded(
              child: filteredParks.isEmpty
                  ? _buildEmptyState(width)
                  : ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: width * 0.05),
                itemCount: filteredParks.length,
                itemBuilder: (context, index) {
                  return _buildParkCard(filteredParks[index], width, height);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== HEADER =====
  Widget _buildHeader(double width, double height) {
    return Container(
      padding: EdgeInsets.all(width * 0.04),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary, AppColors.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌍 National Parks',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: width * 0.06,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Explore the world\'s greatest parks',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: width * 0.032,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(width * 0.025),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.public,
              color: Colors.white,
              size: width * 0.06,
            ),
          ),
        ],
      ),
    );
  }

  // ===== SEARCH BAR =====
  Widget _buildSearchBar(double width, double height) {
    return Padding(
      padding: EdgeInsets.all(width * 0.05),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filterParks,
          decoration: InputDecoration(
            hintText: 'Search any national park in the world...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: width * 0.035),
            prefixIcon: const Icon(Icons.search, color: AppColors.primary),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _filterParks('');
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: height * 0.018),
          ),
        ),
      ),
    );
  }

  // ===== FILTER CHIPS =====
  Widget _buildFilters(double width, double height) {
    final filters = ['All', 'Tanzania', 'Africa', 'North America', 'South America', 'Asia', 'Europe', 'Oceania'];

    return SizedBox(
      height: height * 0.055,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: width * 0.05),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = _selectedFilter == filter;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter = filter;
                _filterParks(_searchController.text);
              });
            },
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
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ]
                    : [],
              ),
              child: Center(
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                    fontSize: width * 0.03,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===== PARK CARD =====
  Widget _buildParkCard(Map<String, String> park, double width, double height) {
    return GestureDetector(
      onTap: () => _openWebsite(park['url']!),
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
            // ===== PARK IMAGE =====
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  Image.network(
                    park['image']!,
                    height: height * 0.18,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: height * 0.18,
                        color: Colors.grey.shade200,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: height * 0.18,
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image_not_supported, size: width * 0.15, color: Colors.grey),
                      );
                    },
                  ),
                  // Region Badge
                  Positioned(
                    top: width * 0.03,
                    left: width * 0.03,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.03,
                        vertical: height * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '🌍 ${park['region']!}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.025,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  // Country Badge
                  Positioned(
                    top: width * 0.03,
                    right: width * 0.03,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: width * 0.03,
                        vertical: height * 0.008,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        park['country']!,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: width * 0.025,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ===== PARK INFO =====
            Padding(
              padding: EdgeInsets.all(width * 0.04),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          park['name']!,
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
                              park['country']!,
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: width * 0.03,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: height * 0.005),
                        Text(
                          park['desc']!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: width * 0.03,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(width * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
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

  // ===== EMPTY STATE =====
  Widget _buildEmptyState(double width) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: width * 0.2,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: width * 0.05),
          Text(
            'No parks found',
            style: TextStyle(
              fontSize: width * 0.05,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: width * 0.02),
          Text(
            'Try searching with a different keyword',
            style: TextStyle(
              fontSize: width * 0.035,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}