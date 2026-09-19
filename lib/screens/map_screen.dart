import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/firestore_service.dart';
import '../utils/colors.dart';
import 'destination_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _openInGoogleMaps(
      double lat, double lng, String name) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Cannot open Google Maps for $name')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('📍 Explore Map'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getDestinations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final destinations = snapshot.data ?? [];
          if (destinations.isEmpty) {
            return const Center(
              child: Text('No destinations available'),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(width * 0.04),
            itemCount: destinations.length,
            itemBuilder: (context, index) {
              final dest = destinations[index];
              final lat = double.tryParse(
                  dest['latitude']?.toString() ?? '');
              final lng = double.tryParse(
                  dest['longitude']?.toString() ?? '');
              final hasLocation = lat != null &&
                  lng != null &&
                  lat != 0 &&
                  lng != 0;

              return Container(
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
                child: Column(
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: (dest['imageUrl'] ?? '').toString().isNotEmpty
                          ? Image.network(
                        dest['imageUrl'],
                        height: height * 0.15,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: height * 0.15,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image),
                        ),
                      )
                          : Container(
                        height: height * 0.15,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(width * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dest['name'] ?? 'Unnamed',
                            style: TextStyle(
                              fontSize: width * 0.045,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: height * 0.005),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: width * 0.04,
                                  color: Colors.grey.shade500),
                              SizedBox(width: width * 0.01),
                              Expanded(
                                child: Text(
                                  dest['location'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: width * 0.032,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: height * 0.015),
                          Row(
                            children: [
                              // View Details
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            DestinationDetailsScreen(
                                                destination: dest),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: height * 0.012),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.visibility,
                                            size: width * 0.04,
                                            color: AppColors.primary),
                                        SizedBox(width: width * 0.015),
                                        Text('Details',
                                            style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: width * 0.032)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: width * 0.02),
                              // Open in Maps
                              if (hasLocation)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => _openInGoogleMaps(
                                        lat, lng, dest['name'] ?? ''),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                          vertical: height * 0.012),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withOpacity(0.1),
                                        borderRadius:
                                        BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.map,
                                              size: width * 0.04,
                                              color: Colors.green),
                                          SizedBox(width: width * 0.015),
                                          Text('Map',
                                              style: TextStyle(
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: width * 0.032)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}