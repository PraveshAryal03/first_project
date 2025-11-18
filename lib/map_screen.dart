import 'package:flutter/material.dart';
import 'dart:html' as html;

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  // Sample healthy restaurants data
  static final List<Map<String, dynamic>> _restaurants = [
    {
      'name': 'Green Leaf Cafe',
      'address': '456 Wellness Ave, Pocatello',
      'type': 'Vegan',
      'rating': 4.5,
      'distance': '0.3 mi',
      'image':
          'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
    },
    {
      'name': 'Ocean Fresh Seafood',
      'address': '789 Marine Dr, Pocatello',
      'type': 'Seafood',
      'rating': 4.3,
      'distance': '0.5 mi',
      'image':
          'https://images.unsplash.com/photo-1559339352-11d035aa65de?w=400',
    },
    {
      'name': 'Fresh Garden Bistro',
      'address': '123 Health St, Pocatello',
      'type': 'Organic',
      'rating': 4.7,
      'distance': '0.2 mi',
      'image':
          'https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?w=400',
    },
    {
      'name': 'Protein Paradise',
      'address': '321 Fitness Blvd, Pocatello',
      'type': 'Health Food',
      'rating': 4.4,
      'distance': '0.7 mi',
      'image':
          'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Healthy Restaurants'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildMapSection(),
        Expanded(child: _buildRestaurantList()),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        SizedBox(width: 400, child: _buildRestaurantList()),
        Expanded(child: _buildMapSection()),
      ],
    );
  }

  Widget _buildMapSection() {
    return Container(
      color: Colors.grey[200],
      child: Stack(
        children: [
          // Static Google Maps image
          Image.network(
            'https://maps.googleapis.com/maps/api/staticmap?'
            'center=42.8746,-112.4452&'
            'zoom=14&'
            'size=800x600&'
            'markers=color:green%7C42.8756,-112.4462&'
            'markers=color:green%7C42.8736,-112.4442&'
            'markers=color:green%7C42.8766,-112.4472&'
            'markers=color:green%7C42.8726,-112.4432&'
            'key=AIzaSyDIYDtCoZIwvJ3C1klogCQhNtLZSHcIWDo', // Replace with your API key
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) {
              // Fallback if API key is not set
              return Container(
                color: Colors.grey[300],
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text(
                      'Map Preview',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Add your Google Maps API key to display the actual map',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Info overlay
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Your Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Pocatello, Idaho',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () {
                        html.window.open(
                          'https://www.google.com/maps/search/healthy+restaurants+near+Pocatello,ID',
                          '_blank',
                        );
                      },
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Open in Maps'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantList() {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Healthy Restaurants',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_restaurants.length} locations nearby',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _restaurants.length,
              itemBuilder: (context, index) {
                return _RestaurantCard(restaurant: _restaurants[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Map<String, dynamic> restaurant;

  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showRestaurantDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: Image.network(
                restaurant['image'],
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 150,
                    color: Colors.grey[300],
                    child: const Icon(Icons.restaurant, size: 48),
                  );
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant['name'],
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          restaurant['type'],
                          style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '${restaurant['rating']}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.location_on,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant['distance'],
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant['address'],
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            html.window.open(
                              'https://www.google.com/maps/search/${Uri.encodeComponent(restaurant['name'])}+${Uri.encodeComponent(restaurant['address'])}',
                              '_blank',
                            );
                          },
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text('Directions'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _showRestaurantDetails(context),
                          icon: const Icon(Icons.info_outline, size: 18),
                          label: const Text('Details'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green,
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
      ),
    );
  }

  void _showRestaurantDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Stack(
                  children: [
                    Image.network(
                      restaurant['image'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.restaurant, size: 64),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurant['name'],
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            restaurant['type'],
                            style: TextStyle(
                              color: Colors.green[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 24),
                        const SizedBox(width: 8),
                        Text(
                          '${restaurant['rating']} Rating',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 24),
                        Icon(
                          Icons.location_on,
                          size: 24,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          restaurant['distance'] + ' away',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.place, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            restaurant['address'],
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              html.window.open(
                                'https://www.google.com/maps/search/${Uri.encodeComponent(restaurant['name'])}+${Uri.encodeComponent(restaurant['address'])}',
                                '_blank',
                              );
                            },
                            icon: const Icon(Icons.directions),
                            label: const Text('Get Directions'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Opening ${restaurant['name']} website...',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Visit Website'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.all(16),
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
        ),
      ),
    );
  }
}
