import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../config/routes.dart';
import '../data/dummy_data.dart';
import '../models/anime.dart';
import '../widgets/app_scaffold.dart';
import '../providers/app_state_provider.dart';

class DetailScreen extends StatelessWidget {
  final String id;

  const DetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final Anime? anime = DummyData.animeList.cast<Anime?>().firstWhere(
      (a) => a?.id == id,
      orElse: () => null,
    );

    if (anime == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Anime Not Found')),
        body: const Center(child: Text('Anime tidak ditemukan.')),
      );
    }

    return AppScaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: screenHeight * 0.3,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Container(
              margin: EdgeInsets.all(screenWidth * 0.02),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.home);
                  }
                },
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  Image.asset(anime.imagePath, fit: BoxFit.cover),
                  // Gradient overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.7),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // Title at the bottom of the image
                  Positioned(
                    bottom: screenHeight * 0.02,
                    left: screenWidth * 0.04,
                    right: screenWidth * 0.04,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anime.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.07,
                            fontWeight: FontWeight.w900,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenHeight * 0.005),
                        Text(
                          anime.genre,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: screenWidth * 0.04,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                offset: const Offset(0, 1),
                                blurRadius: 2,
                                color: Colors.black.withValues(alpha: 0.7),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(screenWidth * 0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // MENGGUNAKAN WRAP SEBAGAI SOLUSI OVERFLOW
                  Wrap(
                    spacing: screenWidth * 0.04, // Jarak horizontal antar kotak
                    runSpacing:
                        screenHeight *
                        0.015, // Jarak vertikal jika elemen turun ke baris baru
                    children: [
                      // 1. Rating
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: screenWidth * 0.02,
                              offset: Offset(0, screenHeight * 0.005),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.02,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              color: Colors.white,
                              size: screenWidth * 0.04,
                            ),
                            SizedBox(width: screenWidth * 0.01),
                            Text(
                              anime.rating,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: screenWidth * 0.035,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. Total Episodes
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.03,
                          vertical: screenHeight * 0.01,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0b395e),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: screenWidth * 0.02,
                              offset: Offset(0, screenHeight * 0.005),
                            ),
                          ],
                          borderRadius: BorderRadius.circular(
                            screenWidth * 0.02,
                          ),
                        ),
                        child: Text(
                          '${anime.totalEpisodes} Episodes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: screenWidth * 0.035,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      // 3. Add to Favorites
                      Consumer<AppStateProvider>(
                        builder: (context, favoriteProvider, child) {
                          final isFavorite = favoriteProvider.isFavorite(
                            anime.id,
                          );

                          return GestureDetector(
                            onTap: () {
                              favoriteProvider.toggleFavorite(anime);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.03,
                                vertical: screenHeight * 0.01,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: screenWidth * 0.02,
                                    offset: Offset(0, screenHeight * 0.005),
                                  ),
                                ],
                                borderRadius: BorderRadius.circular(
                                  screenWidth * 0.02,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: Colors.white,
                                    size: screenWidth * 0.04,
                                  ),
                                  SizedBox(width: screenWidth * 0.01),
                                  Text(
                                    isFavorite
                                        ? 'Added to Favorites'
                                        : 'Add to Favorites',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.035,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  SizedBox(height: screenHeight * 0.03),

                  // Description
                  Text(
                    'Synopsis',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: screenWidth * 0.05,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  Text(
                    anime.description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: screenWidth * 0.038,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: screenHeight * 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
