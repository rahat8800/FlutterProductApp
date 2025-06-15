import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

// Favorites state class
class FavoritesState {
  final Set<int> favoriteProductIds;
  final bool isLoading;

  const FavoritesState({
    this.favoriteProductIds = const {},
    this.isLoading = false,
  });

  FavoritesState copyWith({
    Set<int>? favoriteProductIds,
    bool? isLoading,
  }) {
    return FavoritesState(
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool isFavorite(int productId) {
    return favoriteProductIds.contains(productId);
  }

  int get favoriteCount => favoriteProductIds.length;
}

// Favorites notifier
class FavoritesNotifier extends StateNotifier<FavoritesState> {
  FavoritesNotifier() : super(const FavoritesState());

  void toggleFavorite(int productId) {
    final newFavorites = Set<int>.from(state.favoriteProductIds);
    
    if (newFavorites.contains(productId)) {
      newFavorites.remove(productId);
    } else {
      newFavorites.add(productId);
    }
    
    state = state.copyWith(favoriteProductIds: newFavorites);
  }

  void addToFavorites(int productId) {
    if (!state.favoriteProductIds.contains(productId)) {
      final newFavorites = Set<int>.from(state.favoriteProductIds)..add(productId);
      state = state.copyWith(favoriteProductIds: newFavorites);
    }
  }

  void removeFromFavorites(int productId) {
    if (state.favoriteProductIds.contains(productId)) {
      final newFavorites = Set<int>.from(state.favoriteProductIds)..remove(productId);
      state = state.copyWith(favoriteProductIds: newFavorites);
    }
  }

  void clearFavorites() {
    state = state.copyWith(favoriteProductIds: {});
  }

  List<Product> getFavoriteProducts(List<Product> allProducts) {
    return allProducts.where((product) => state.favoriteProductIds.contains(product.id)).toList();
  }
}

// Providers
final favoritesProvider = StateNotifierProvider<FavoritesNotifier, FavoritesState>((ref) {
  return FavoritesNotifier();
});

// Convenience providers
final favoriteProductIdsProvider = Provider<Set<int>>((ref) {
  return ref.watch(favoritesProvider).favoriteProductIds;
});

final favoriteCountProvider = Provider<int>((ref) {
  return ref.watch(favoritesProvider).favoriteCount;
});

final isFavoriteProvider = Provider.family<bool, int>((ref, productId) {
  return ref.watch(favoritesProvider).isFavorite(productId);
});

final favoriteProductsProvider = Provider.family<List<Product>, List<Product>>((ref, allProducts) {
  final favoritesState = ref.watch(favoritesProvider);
  return allProducts.where((product) => favoritesState.favoriteProductIds.contains(product.id)).toList();
}); 