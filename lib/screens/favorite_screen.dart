import 'package:flutter/material.dart';
import '../data/dummy_data.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/favorite_anime_card.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Get one anime from dummy data for display
    final favoriteAnime = DummyData.animeList.first;

    return AppScaffold(
      appBar: AppBar(
        title: Text(
          "Favorite Anime",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: screenWidth * 0.06,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar bisa dipakai ulang dari HomeScreen (opsional, sesuai selera)
          SizedBox(height: screenHeight * 0.01),

          // Favorite Anime List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight * 0.01,
              ),
              itemCount: 1,
              itemBuilder: (context, index) {
                return FavoriteAnimeCard(
                  title: favoriteAnime.title,
                  genre: favoriteAnime.genre,
                  rating: favoriteAnime.rating,
                  imagePath: favoriteAnime.imagePath,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}