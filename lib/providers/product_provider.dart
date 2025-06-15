import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/api_service.dart';

// Product state class
class ProductState {
  final List<Product> products;
  final Product? selectedProduct;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;

  const ProductState({
    this.products = const [],
    this.selectedProduct,
    this.isLoading = false,
    this.error,
    this.selectedCategory,
  });

  ProductState copyWith({
    List<Product>? products,
    Product? selectedProduct,
    bool? isLoading,
    String? error,
    String? selectedCategory,
  }) {
    return ProductState(
      products: products ?? this.products,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  List<Product> get filteredProducts {
    if (selectedCategory == null || selectedCategory!.isEmpty) {
      return products;
    }
    return products.where((product) => product.category == selectedCategory).toList();
  }
}

// Product notifier
class ProductNotifier extends StateNotifier<ProductState> {
  final ApiService _apiService;

  ProductNotifier(this._apiService) : super(const ProductState());

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final products = await _apiService.getProducts();
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadProductById(int id) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final product = await _apiService.getProductById(id);
      state = state.copyWith(selectedProduct: product, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void selectCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSelectedProduct() {
    state = state.copyWith(selectedProduct: null);
  }
}

// Providers
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ProductNotifier(apiService);
});

// Convenience providers
final productsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productProvider).products;
});

final filteredProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productProvider).filteredProducts;
});

final selectedProductProvider = Provider<Product?>((ref) {
  return ref.watch(productProvider).selectedProduct;
});

final productLoadingProvider = Provider<bool>((ref) {
  return ref.watch(productProvider).isLoading;
});

final productErrorProvider = Provider<String?>((ref) {
  return ref.watch(productProvider).error;
});

final selectedCategoryProvider = Provider<String?>((ref) {
  return ref.watch(productProvider).selectedCategory;
}); 