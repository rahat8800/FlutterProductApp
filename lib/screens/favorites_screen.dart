import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/favorites_provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';
import 'product_detail_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productProvider);
    final favoriteProducts = ref.watch(favoriteProductsProvider(productState.products));
    final favoriteCount = ref.watch(favoriteCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (favoriteCount > 0)
            IconButton(
              icon: const Icon(Icons.clear_all),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear All Favorites'),
                    content: const Text('Are you sure you want to remove all favorites?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          ref.read(favoritesProvider.notifier).clearFavorites();
                          Navigator.of(context).pop();
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _buildBody(context, ref, productState, favoriteProducts),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, dynamic productState, List<dynamic> favoriteProducts) {
    if (productState.isLoading) {
      return const LoadingWidget(message: 'Loading favorites...');
    }

    if (productState.error != null) {
      return CustomErrorWidget(
        message: productState.error!,
        onRetry: () => ref.read(productProvider.notifier).loadProducts(),
      );
    }

    if (favoriteProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the heart icon on any product to add it to your favorites',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.shopping_bag),
              label: const Text('Browse Products'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Favorites count header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.blue[50],
          child: Row(
            children: [
              const Icon(Icons.favorite, color: Colors.red),
              const SizedBox(width: 8),
              Text(
                '${favoriteProducts.length} favorite${favoriteProducts.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        // Favorites grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.6,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: favoriteProducts.length,
            itemBuilder: (context, index) {
              final product = favoriteProducts[index];
              return ProductCard(
                product: product,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductDetailScreen(productId: product.id),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
} 