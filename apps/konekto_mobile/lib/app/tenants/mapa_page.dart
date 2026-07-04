import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Função auxiliar para converter cor hexadecimal
Color hexToColor(String hexCode) {
  return Color(int.parse(hexCode.substring(1, 7), radix: 16) + 0xFF000000);
}

// Converte String de FontWeight para Flutter FontWeight
FontWeight _getFontWeight(String? weight) {
  switch (weight) {
    case 'w100':
      return FontWeight.w100;
    case 'w200':
      return FontWeight.w200;
    case 'w300':
      return FontWeight.w300;
    case 'w400':
      return FontWeight.w400;
    case 'w500':
      return FontWeight.w500;
    case 'w600':
      return FontWeight.w600;
    case 'w700':
      return FontWeight.w700;
    case 'w800':
      return FontWeight.w800;
    case 'w900':
      return FontWeight.w900;
    default:
      return FontWeight.normal;
  }
}

class MapaPage extends StatefulWidget {
  final Map<String, dynamic> tenantConfig;
  final Map<String, dynamic> pageData;

  const MapaPage({
    super.key,
    required this.tenantConfig,
    required this.pageData,
  });

  @override
  State<MapaPage> createState() => _MapaPageState();
}

class _MapaPageState extends State<MapaPage> {
  String? _activeMapImageUrl;

  @override
  void initState() {
    super.initState();
    // Define a imagem do mapa inicial
    final promoImages = widget.pageData['promoImages'] as List<dynamic>?;
    if (promoImages != null && promoImages.isNotEmpty) {
      _activeMapImageUrl = promoImages.first['mapImageUrl'];
    }
  }

  Widget _buildSection(
    Map<String, dynamic> sectionConfig,
    Map<String, dynamic> fullConfig,
    dynamic data,
  ) {
    final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(widget.tenantConfig['colorPalette']['primary']);
    final Color bodyTextColor = hexToColor(widget.tenantConfig['typography']['bodyText']['color']);
    final Color dividerColor = hexToColor(widget.tenantConfig['colorPalette']['dividerColor']);

    final String type = sectionConfig['type'];
    final Map<String, dynamic> layout = sectionConfig['layout'] ?? {};
    final Map<String, dynamic> pageStyles = fullConfig['textStyles'] ?? {};

    switch (type) {
      case 'carousel':
        final double height = (layout['height'] ?? 150).toDouble();
        final double imageHeight = (layout['imageHeight'] ?? 90).toDouble();
        final double itemSpacing = (layout['itemSpacing'] ?? 12).toDouble();
        final List<dynamic> promoImages = data as List<dynamic>;

        return SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: promoImages.length,
            separatorBuilder: (context, index) => SizedBox(width: itemSpacing),
            itemBuilder: (context, index) {
              final item = promoImages[index];
              final String? mapImageUrl = item['mapImageUrl'];
              return GestureDetector(
                onTap: () {
                  if (mapImageUrl != null) {
                    setState(() {
                      _activeMapImageUrl = mapImageUrl;
                    });
                  }
                },
                child: SizedBox(
                  width: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          item['imageUrl']!,
                          width: 160,
                          height: imageHeight,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 160,
                              height: imageHeight,
                              color: Colors.grey[200],
                              child: const Icon(Icons.error, color: Colors.grey),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: (layout['titleSpacing'] ?? 8).toDouble()),
                      Text(
                        item['label']!,
                        style: GoogleFonts.getFont(
                          fontFamily,
                          color: primaryColor,
                          fontSize: (pageStyles['carouselLabel']?['fontSize'] ?? 16).toDouble(),
                          fontWeight: _getFontWeight(pageStyles['carouselLabel']?['fontWeight']),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

      case 'services_list':
        final String servicesSectionTitle = fullConfig['servicesSectionTitle'] ?? "Serviços & Comodidades";
        final List<dynamic> serviceItems = data as List<dynamic>;
        final double itemSpacing = (layout['itemSpacing'] ?? 1).toDouble();
        final double titleSpacing = (layout['titleSpacing'] ?? 12).toDouble();

        final Map<String, dynamic> servicesTitleStyleJson = pageStyles['servicesSectionTitle'] ?? {};
        final TextStyle servicesTitleStyle = GoogleFonts.getFont(
          fontFamily,
          fontSize: (servicesTitleStyleJson['fontSize'] ?? 22).toDouble(),
          fontWeight: _getFontWeight(servicesTitleStyleJson['fontWeight']),
          color: hexToColor(servicesTitleStyleJson['color'] ?? '#0D1B2A'),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              servicesSectionTitle,
              style: servicesTitleStyle,
            ),
            SizedBox(height: titleSpacing),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: serviceItems.length,
              separatorBuilder: (context, index) => Divider(color: dividerColor, height: itemSpacing),
              itemBuilder: (context, index) {
                final item = serviceItems[index];
                final String? mapImageUrl = item['mapImageUrl'];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    item['label']!,
                    style: GoogleFonts.getFont(
                      fontFamily,
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  trailing: Icon(Icons.chevron_right, color: bodyTextColor),
                  onTap: () {
                    if (mapImageUrl != null) {
                      setState(() {
                        _activeMapImageUrl = mapImageUrl;
                      });
                    }
                  },
                );
              },
            ),
          ],
        );

      case 'map_view':
        final double aspectRatio = (layout['aspectRatio'] ?? 1.0).toDouble();
        final double borderRadius = (layout['borderRadius'] ?? 0).toDouble();

        return AspectRatio(
          aspectRatio: aspectRatio,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            clipBehavior: Clip.antiAlias,
            child: _activeMapImageUrl != null
                ? Image.asset(
                    _activeMapImageUrl!,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          "Imagem do mapa não encontrada.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.getFont(fontFamily, color: Colors.black54),
                        ),
                      );
                    },
                  )
                : Center(
                    child: Text(
                      "Mapa indisponível",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.getFont(fontFamily, color: Colors.black54),
                    ),
                  ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> pageConfig = widget.pageData['pageConfig'] ?? {};
    final String pageTitle = pageConfig['title'] ?? 'Mapa do Hotel';
    final Map<String, dynamic> pageLayout = pageConfig['layout'] ?? {};
    final double screenHorizontalPadding = (pageLayout['screenHorizontalPadding'] ?? 16).toDouble();
    final double pageTopPadding = (pageLayout['pageTopPadding'] ?? 16).toDouble();

    final String fontFamily = widget.tenantConfig['typography']['fontFamily'];
    final Color primaryColor = hexToColor(widget.tenantConfig['colorPalette']['primary']);

    final Map<String, dynamic> pageTitleStyleJson = pageConfig['textStyles']['pageTitle'] ?? {};
    final TextStyle pageTitleStyle = GoogleFonts.getFont(
      fontFamily,
      fontSize: (pageTitleStyleJson['fontSize'] ?? 18).toDouble(),
      fontWeight: _getFontWeight(pageTitleStyleJson['fontWeight']),
      color: hexToColor(pageTitleStyleJson['color'] ?? '#0D1B2A'),
    );

    final List<dynamic> sections = pageConfig['sections'] ?? [];
    final Map<String, dynamic> fixedSection = pageConfig['fixedSection'] ?? {};
    final double mapBottomPadding = (fixedSection['layout']?['bottomPadding'] ?? 0).toDouble();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(pageTitle, style: pageTitleStyle),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: screenHorizontalPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: pageTopPadding),
                    ...sections.map((section) {
                      final String dataKey = section['dataKey'];
                      final dynamic data = widget.pageData[dataKey];
                      final double verticalPadding = (section['layout']?['verticalPadding'] ?? 0).toDouble();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSection(section, pageConfig, data),
                          SizedBox(height: verticalPadding),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
          if (fixedSection.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: screenHorizontalPadding),
              child: _buildSection(fixedSection, pageConfig, widget.pageData[fixedSection['dataKey']]),
            ),
            SizedBox(height: mapBottomPadding),
          ]
        ],
      ),
    );
  }
}