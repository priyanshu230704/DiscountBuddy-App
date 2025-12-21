import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../../widgets/blurred_ellipse_background.dart';
import '../../../widgets/common_search_bar.dart';
import '../../../widgets/border_gradient.dart';
import '../../../utils/constants.dart';

/// Events page showing list of events
class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  final TextEditingController _searchController = TextEditingController();

  final List<Event> _comedyEvents = [
    Event(
      id: '1',
      title: 'Chhoti Soch | Standup Comedy Solo Show',
      description: 'A hilarious standup comedy performance',
      date: DateTime.now().add(const Duration(days: 5)),
      time: '6:00 PM',
      location: 'Backspace Ahmedabad',
      imageUrl: 'https://via.placeholder.com/400x200?text=Comedy+Show',
      category: 'Comedy',
    ),
    Event(
      id: '2',
      title: 'Senti Mat Ho Yar - Standup Comedy Show',
      description: 'Standup comedy featuring Aaket Panchal',
      date: DateTime.now().add(const Duration(days: 2)),
      time: '9:00 PM',
      location: 'Rangmanch Creative',
      imageUrl: 'https://via.placeholder.com/400x200?text=Comedy+Show+2',
      category: 'Comedy',
    ),
    Event(
      id: '3',
      title: 'Laugh Out Loud',
      description: 'An evening of non-stop laughter',
      date: DateTime.now().add(const Duration(days: 7)),
      time: '8:00 PM',
      location: 'Comedy Club London',
      imageUrl: 'https://via.placeholder.com/400x200?text=Comedy+Show+3',
      category: 'Comedy',
    ),
  ];


  final List<ExploreCategory> _exploreCategories = [
    ExploreCategory(
      name: 'CHRISTMAS',
      icon: Icons.celebration,
    ),
    ExploreCategory(
      name: 'MUSIC',
      icon: Icons.music_note,
    ),
    ExploreCategory(
      name: 'COMEDY',
      icon: Icons.mic,
    ),
    ExploreCategory(
      name: 'FOOD & DRINKS',
      icon: Icons.restaurant,
    ),
    ExploreCategory(
      name: 'NEW YEAR',
      icon: Icons.calendar_today,
    ),
    ExploreCategory(
      name: 'NIGHTLIFE',
      icon: Icons.nightlife,
    ),
    ExploreCategory(
      name: 'PERFORMANCES',
      icon: Icons.theater_comedy,
    ),
    ExploreCategory(
      name: 'FESTIVALS & FAIRS',
      icon: Icons.festival,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // Blurred ellipse at the top center background
          const BlurredEllipseBackground(),
          // Main content scrollable
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppConstants.paddingMedium,
                    vertical: AppConstants.paddingSmall,
                  ),
                  child: CommonSearchBar(
                      controller: _searchController,
                        hintText: 'Search for events...',
                  ),
                ),
                // Events List
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Comedy Events Section
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppConstants.paddingMedium,
                            top: AppConstants.paddingMedium,
                            bottom: AppConstants.paddingSmall,
                          ),
                          child: const Text(
                            'Comedy events',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 240,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppConstants.paddingMedium,
                            ),
                            itemCount: _comedyEvents.length,
                            itemBuilder: (context, index) {
                              final event = _comedyEvents[index];
                              return Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: AppConstants.paddingMedium),
                                child: _buildSmallEventCard(event),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingLarge),
                        // Banner Image
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                            child: Image.asset(
                              'assets/png/banner-sm.png',
                              width: double.infinity,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingLarge),
                        // Explore Events Section
                        Padding(
                          padding: const EdgeInsets.only(
                            left: AppConstants.paddingMedium,
                            top: AppConstants.paddingMedium,
                            bottom: AppConstants.paddingSmall,
                          ),
                          child: const Text(
                            'Explore events',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConstants.paddingMedium,
                            ),
                            itemCount: _exploreCategories.length,
                            itemBuilder: (context, index) {
                              final category = _exploreCategories[index];
                              return Container(
                                width: 90,
                                margin: const EdgeInsets.only(right: AppConstants.paddingMedium),
                                child: _buildExploreCategoryCard(category),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: AppConstants.paddingLarge),
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

  Widget _buildSmallEventCard(Event event) {
    final dateFormat = DateFormat('EEE, dd MMM');
    final formattedDate = dateFormat.format(event.date);
    final fullDate = '$formattedDate, ${event.time}';

    return BorderGradient(
      borderWidth: 0.5,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B1F),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppConstants.radiusMedium),
                      topRight: Radius.circular(AppConstants.radiusMedium),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: event.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: const Color(0xFF2B2D30),
                        child: Center(
                          child: Icon(
                            Icons.event,
                            size: 32,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: const Color(0xFF2B2D30),
                        child: Center(
                          child: Icon(
                            Icons.event,
                            size: 32,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Bookmark Icon
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.bookmark_border,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Event Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingSmall),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            event.location,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    // Title
                    Text(
                      event.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Date and Time
                    Text(
                      fullDate,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildExploreCategoryCard(ExploreCategory category) {
    return BorderGradient(
      borderWidth: 0.5,
      borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1B1F),
          borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 28,
              color: const Color(0xFF3E25F6),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
              category.name,
              style: const TextStyle(
                color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Event {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final String time;
  final String location;
  final String imageUrl;
  final String category;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.imageUrl,
    required this.category,
  });
}

class ExploreCategory {
  final String name;
  final IconData icon;

  const ExploreCategory({
    required this.name,
    required this.icon,
  });
}
