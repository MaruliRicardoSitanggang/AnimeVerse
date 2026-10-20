import 'dart:convert';

import 'package:animeverse/config/routes.dart';
import 'package:animeverse/data/dummy_data.dart';
import 'package:animeverse/providers/app_state_provider.dart';
import 'package:animeverse/screens/detail_screen.dart';
import 'package:animeverse/widgets/anime_card.dart';
import 'package:animeverse/widgets/favorite_anime_card.dart';
import 'package:animeverse/widgets/genre_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Favorites are unique, notify listeners, and toggle by ID', () async {
    final state = AppStateProvider();
    addTearDown(() async {
      await state.favoritesSaved;
      state.dispose();
    });
    await state.initialized;
    final anime = DummyData.animeList.first;
    var notifications = 0;
    state.addListener(() => notifications++);

    state.addFavorite(anime);
    state.addFavorite(anime);
    expect(state.favorites, [anime]);
    expect(notifications, 1);
    expect(() => state.favorites.clear(), throwsUnsupportedError);
    state.toggleFavorite(anime);
    expect(state.isFavorite(anime.id), isFalse);
    expect(state.favorites, isEmpty);
    expect(notifications, 2);
    state.toggleFavorite(anime);
    expect(state.isFavorite(anime.id), isTrue);
    expect(notifications, 3);
  });

  test('Favorites survive a provider restart and removals are saved', () async {
    final state = AppStateProvider();
    await state.initialized;
    final anime = DummyData.animeList.first;
    state.addFavorite(anime);
    await state.favoritesSaved;
    state.dispose();

    final restored = AppStateProvider();
    await restored.initialized;
    expect(restored.favorites.single.toJson(), anime.toJson());
    restored.removeFavorite(anime.id);
    await restored.favoritesSaved;
    restored.dispose();

    final afterRemoval = AppStateProvider();
    addTearDown(afterRemoval.dispose);
    await afterRemoval.initialized;
    expect(afterRemoval.favorites, isEmpty);
  });

  test(
    'Changes during startup preserve stored favorites and the latest toggle',
    () async {
      final savedAnime = DummyData.animeList.first;
      final newAnime = DummyData.animeList[1];
      SharedPreferences.setMockInitialValues({
        'favorite_anime_list': jsonEncode([savedAnime.toJson()]),
      });
      final state = AppStateProvider();
      state.addFavorite(newAnime);
      state.toggleFavorite(newAnime);
      state.toggleFavorite(newAnime);
      await state.favoritesSaved;
      state.dispose();

      final restored = AppStateProvider();
      addTearDown(restored.dispose);
      await restored.initialized;
      expect(restored.favorites.map((anime) => anime.id), [
        savedAnime.id,
        newAnime.id,
      ]);
    },
  );

  test(
    'Genre and title filters combine while favorite search stays separate',
    () async {
      final state = AppStateProvider();
      await state.initialized;
      addTearDown(() async {
        await state.favoritesSaved;
        state.dispose();
      });
      state.addFavorite(DummyData.animeList.first);
      state.addFavorite(DummyData.animeList[1]);
      state.setSelectedGenre('Action');
      state.setHomeSearchQuery('cLoVeR');
      expect(state.getFilteredAnimeForHome().single.title, 'Black Clover');
      state.setFavoriteSearchQuery('hErO');
      expect(state.getFilteredFavorites().single.title, 'My Hero Academia');
      expect(state.homeSearchQuery, 'cLoVeR');
      state.setSelectedGenre('Drama');
      expect(state.getFilteredAnimeForHome(), isEmpty);
      state.setSelectedGenre('All');
      state.setHomeSearchQuery('');
      expect(
        state.getFilteredAnimeForHome().length,
        DummyData.animeList.length,
      );
      expect(state.favoriteSearchQuery, 'hErO');
    },
  );

  testWidgets('Cards open details and favorites update across tabs', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppStateProvider();
    final router = createRouter();
    addTearDown(state.dispose);
    addTearDown(router.dispose);
    router.go(AppRoutes.home);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Initialize the favorites tab before changing the provider.
    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada anime favorit'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.home_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AnimeCard).first);
    await tester.pumpAndSettle();
    expect(find.byType(DetailScreen), findsOneWidget);
    expect(tester.widget<DetailScreen>(find.byType(DetailScreen)).id, '1');
    await tester.tap(find.text('Add to Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('Added to Favorites'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.favorite_rounded));
    await tester.pumpAndSettle();
    expect(find.byType(FavoriteAnimeCard), findsOneWidget);
    await tester.tap(find.byType(FavoriteAnimeCard));
    await tester.pumpAndSettle();
    expect(find.byType(DetailScreen), findsOneWidget);
    await tester.tap(find.text('Added to Favorites'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();
    expect(find.text('Belum ada anime favorit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Home search, genre highlight, clear, and tab state work together',
    (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final state = AppStateProvider();
      await tester.pump();
      await state.initialized;
      final router = createRouter();
      addTearDown(state.dispose);
      addTearDown(router.dispose);
      router.go(AppRoutes.home);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Action'));
      await tester.enterText(find.byType(TextField), 'cLoVeR');
      await tester.pumpAndSettle();
      expect(find.byType(AnimeCard), findsOneWidget);
      expect(
        tester.widget<GenreList>(find.byType(GenreList)).selected,
        'Action',
      );
      final chip = find
          .ancestor(of: find.text('Action'), matching: find.byType(Container))
          .first;
      expect(
        (tester.widget<Container>(chip).decoration as BoxDecoration).color,
        const Color(0xFF1976D2),
      );

      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
      await tester.tap(find.byIcon(Icons.home_rounded));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'cLoVeR',
      );
      expect(
        tester.widget<GenreList>(find.byType(GenreList)).selected,
        'Action',
      );
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();
      expect(state.homeSearchQuery, isEmpty);
      expect(find.byIcon(Icons.clear), findsNothing);
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.byType(AnimeCard), findsNWidgets(DummyData.animeList.length));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Favorite search distinguishes no results and an empty list', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final state = AppStateProvider();
    await tester.pump();
    await state.initialized;
    state.addFavorite(DummyData.animeList.first);
    state.addFavorite(DummyData.animeList[1]);
    state.setHomeSearchQuery('home query');
    final router = createRouter();
    addTearDown(state.dispose);
    addTearDown(router.dispose);
    router.go(AppRoutes.favorites);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'HERO');
    await tester.pumpAndSettle();
    expect(find.byType(FavoriteAnimeCard), findsOneWidget);
    expect(find.text('My Hero Academia'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'missing title');
    await tester.pumpAndSettle();
    expect(find.text('Anime tidak ditemukan'), findsOneWidget);
    expect(find.text('Belum ada anime favorit'), findsNothing);
    await tester.tap(find.byIcon(Icons.clear));
    await tester.pumpAndSettle();
    expect(find.byType(FavoriteAnimeCard), findsNWidgets(2));
    expect(state.homeSearchQuery, 'home query');
    for (final anime in state.favorites) {
      state.removeFavorite(anime.id);
    }
    await tester.pumpAndSettle();
    expect(find.text('Belum ada anime favorit'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Restored favorites show an active heart on the detail screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final anime = DummyData.animeList.first;
    SharedPreferences.setMockInitialValues({
      'favorite_anime_list': jsonEncode([anime.toJson()]),
    });
    final state = AppStateProvider();
    await tester.pump();
    await state.initialized;
    final router = createRouter();
    addTearDown(state.dispose);
    addTearDown(router.dispose);
    router.go('/details/${anime.id}');
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Added to Favorites'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unknown anime IDs show the existing not-found screen', (
    tester,
  ) async {
    final router = createRouter();
    addTearDown(router.dispose);
    router.go('/details/unknown');
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('Anime tidak ditemukan.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
