import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'restaurant_detail_page.dart';

class RestaurantListPage extends StatelessWidget {
  final Map<String, dynamic> tenantConfig;
  final Map<String, dynamic> restaurantsData;

  const RestaurantListPage({
    Key? key,
    required this.tenantConfig,
    required this.restaurantsData,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final List<dynamic> restaurants = restaurantsData['restaurants'] ?? [];
    final Map<String, dynamic> pageConfig = restaurantsData['pageConfig'] ?? {};
    final String layoutType = pageConfig['layoutType'] ?? 'list';

    final String fontFamily = tenantConfig['typography']['fontFamily'];
    final Color primaryColor = Color(int.parse(tenantConfig['colorPalette']['primary'].substring(1, 7), radix: 16) + 0xFF000000);
    final Color backgroundColor = Color(int.parse(tenantConfig['colorPalette']['background'].substring(1, 7), radix: 16) + 0xFF000000);
    final Color cardBackgroundColor = Color(int.parse(tenantConfig['colorPalette']['cardBackground'].substring(1, 7), radix: 16) + 0xFF000000);
    final Color bodyTextColor = Color(int.parse(tenantConfig['typography']['bodyText']['color'].substring(1, 7), radix: 16) + 0xFF000000);
    final Color dividerColor = Color(int.parse(tenantConfig['colorPalette']['dividerColor'].substring(1, 7), radix: 16) + 0xFF000000);

    final String pageTitle = pageConfig['title'] ?? 'Restaurantes';
    final String bannerImageUrl = pageConfig['bannerImageUrl'] ?? 'assets/app_assets/images/placeholder.png';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      color: primaryColor,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Expanded(
                      child: Text(
                        pageTitle,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.getFont(
                          fontFamily,
                          color: primaryColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.16), blurRadius: 18, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      bannerImageUrl,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/app_assets/images/placeholder.png',
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Explore Nossos Restaurantes',
                  style: GoogleFonts.getFont(
                    fontFamily,
                    color: primaryColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                if (restaurants.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (layoutType == 'grid')
                  _buildRestaurantGrid(context, restaurants, fontFamily, primaryColor, bodyTextColor, cardBackgroundColor, dividerColor)
                else
                  _buildRestaurantList(context, restaurants, fontFamily, primaryColor, bodyTextColor, cardBackgroundColor, dividerColor),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRestaurantList(BuildContext context, List<dynamic> restaurants, String fontFamily, Color primaryColor, Color bodyTextColor, Color cardBackgroundColor, Color dividerColor) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: restaurants.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _buildRestaurantCard(
          context,
          restaurants[index],
          fontFamily,
          primaryColor,
          bodyTextColor,
          cardBackgroundColor,
          dividerColor,
        );
      },
    );
  }

  Widget _buildRestaurantGrid(BuildContext context, List<dynamic> restaurants, String fontFamily, Color primaryColor, Color bodyTextColor, Color cardBackgroundColor, Color dividerColor) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16.0,
        mainAxisSpacing: 16.0,
        childAspectRatio: 0.8,
      ),
      itemCount: restaurants.length,
      itemBuilder: (context, index) {
        return _buildRestaurantCard(
          context,
          restaurants[index],
          fontFamily,
          primaryColor,
          bodyTextColor,
          cardBackgroundColor,
          dividerColor,
          isGrid: true,
        );
      },
    );
  }
  
  Widget _buildRestaurantCard(
    BuildContext context,
    Map<String, dynamic> restaurant,
    String fontFamily,
    Color primaryColor,
    Color bodyTextColor,
    Color cardBackgroundColor,
    Color dividerColor, {
    bool isGrid = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantDetailPage(
              tenantConfig: tenantConfig,
              restaurant: restaurant,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: dividerColor.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(color: primaryColor.withValues(alpha: 0.10), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: isGrid
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                      child: Image.asset(
                        restaurant['imageUrl'] ?? 'assets/app_assets/images/placeholder.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, color: Colors.black54),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          restaurant['name'] ?? '',
                          style: GoogleFonts.getFont(
                            fontFamily,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          restaurant['description'] ?? '',
                          style: GoogleFonts.getFont(
                            fontFamily,
                            fontSize: 12,
                            color: bodyTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      restaurant['imageUrl'] ?? 'assets/app_assets/images/placeholder.png',
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          width: 120,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image_not_supported, color: Colors.black54),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            restaurant['name'] ?? '',
                            style: GoogleFonts.getFont(
                              fontFamily,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            restaurant['description'] ?? '',
                            style: GoogleFonts.getFont(
                              fontFamily,
                              fontSize: 14,
                              color: bodyTextColor,
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