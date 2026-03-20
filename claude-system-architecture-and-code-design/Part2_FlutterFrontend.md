# MedOrder — System Architecture & Code Design Guidelines

## Tech Stack: Flutter + Node.js + PostgreSQL

---

# PART 2: FRONTEND (FLUTTER) CODE DESIGN GUIDELINES

---

## 2.1 Architecture Pattern: Clean Architecture with BLoC

Flutter follows **Clean Architecture** with three layers, enforced by directory structure and dependency rules.

```
lib/
├── main.dart
├── app.dart                              # MaterialApp, theme, routing setup
│
├── core/                                 # Shared across all features
│   ├── constants/
│   │   ├── app_colors.dart               # Color palette constants
│   │   ├── app_text_styles.dart          # Typography presets
│   │   ├── app_spacing.dart              # Spacing scale (4, 8, 12, 16, 24, 32...)
│   │   ├── app_assets.dart               # Asset paths
│   │   ├── api_endpoints.dart            # All API endpoint strings
│   │   └── app_constants.dart            # Misc constants
│   ├── theme/
│   │   ├── app_theme.dart                # ThemeData configuration
│   │   └── app_theme_extensions.dart     # Custom theme extensions
│   ├── network/
│   │   ├── api_client.dart               # Dio instance, interceptors
│   │   ├── api_interceptors.dart         # Auth, logging, error interceptors
│   │   ├── api_response.dart             # Standardized response wrapper
│   │   └── network_info.dart             # Connectivity checker
│   ├── error/
│   │   ├── failures.dart                 # Failure classes (ServerFailure, CacheFailure...)
│   │   └── exceptions.dart               # Exception classes
│   ├── usecase/
│   │   └── usecase.dart                  # Base UseCase<Type, Params> abstract class
│   ├── utils/
│   │   ├── validators.dart               # Form validation functions
│   │   ├── formatters.dart               # Price, date, phone formatters
│   │   ├── debouncer.dart                # Search debounce utility
│   │   └── image_utils.dart              # Image compression, picker helpers
│   ├── widgets/                          # Shared reusable widgets
│   │   ├── app_button.dart               # Primary, secondary, text buttons
│   │   ├── app_text_field.dart           # Styled text input with validation
│   │   ├── app_loading.dart              # Shimmer skeletons, spinners
│   │   ├── app_error_widget.dart         # Error state with retry
│   │   ├── app_empty_state.dart          # Empty list illustration + CTA
│   │   ├── product_card.dart             # Reusable product card widget
│   │   ├── status_badge.dart             # Color-coded status pills
│   │   ├── cached_image.dart             # CachedNetworkImage wrapper
│   │   ├── quantity_selector.dart        # +/- stepper widget
│   │   ├── rating_stars.dart             # Star display + interactive rating
│   │   └── countdown_timer.dart          # Flash sale countdown widget
│   ├── extensions/
│   │   ├── context_extensions.dart       # BuildContext helpers (theme, media query)
│   │   ├── string_extensions.dart        # String utilities
│   │   └── datetime_extensions.dart      # Date formatting helpers
│   └── di/
│       └── injection_container.dart      # GetIt dependency injection setup
│
├── features/                             # Feature-based modules
│   ├── auth/
│   │   ├── data/
│   │   │   ├── models/                   # JSON serializable models (fromJson/toJson)
│   │   │   │   ├── login_request_model.dart
│   │   │   │   ├── register_request_model.dart
│   │   │   │   └── auth_response_model.dart
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart    # Secure token storage
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── doctor.dart                    # Pure entity, no JSON logic
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart           # Abstract contract
│   │   │   └── usecases/
│   │   │       ├── login_usecase.dart
│   │   │       ├── register_usecase.dart
│   │   │       ├── verify_otp_usecase.dart
│   │   │       └── logout_usecase.dart
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── auth_bloc.dart
│   │       │   ├── auth_event.dart
│   │       │   └── auth_state.dart
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   ├── register_page.dart
│   │       │   ├── otp_page.dart
│   │       │   └── pending_approval_page.dart
│   │       └── widgets/
│   │           ├── login_form.dart
│   │           ├── register_step_one.dart
│   │           ├── register_step_two.dart
│   │           └── register_step_three.dart
│   │
│   ├── home/
│   │   ├── data/ ...
│   │   ├── domain/ ...
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── home_bloc.dart
│   │       ├── pages/
│   │       │   └── home_page.dart
│   │       └── widgets/
│   │           ├── promo_slider.dart
│   │           ├── flash_sale_section.dart
│   │           ├── categories_grid.dart
│   │           ├── best_sellers_section.dart
│   │           └── welcome_banner.dart
│   │
│   ├── product/
│   │   ├── data/ ...
│   │   ├── domain/ ...
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   ├── product_list_bloc.dart
│   │       │   ├── product_detail_bloc.dart
│   │       │   └── search_bloc.dart
│   │       ├── pages/
│   │       │   ├── product_list_page.dart
│   │       │   ├── product_detail_page.dart
│   │       │   └── search_page.dart
│   │       └── widgets/
│   │           ├── product_grid.dart
│   │           ├── filter_bottom_sheet.dart
│   │           ├── bulk_pricing_table.dart
│   │           ├── medical_details_tab.dart
│   │           └── review_section.dart
│   │
│   ├── cart/
│   │   ├── data/ ...
│   │   ├── domain/ ...
│   │   └── presentation/ ...
│   │
│   ├── order/
│   │   ├── data/ ...
│   │   ├── domain/ ...
│   │   └── presentation/
│   │       ├── bloc/ ...
│   │       ├── pages/
│   │       │   ├── orders_list_page.dart
│   │       │   ├── order_detail_page.dart
│   │       │   └── order_tracking_page.dart
│   │       └── widgets/
│   │           ├── order_card.dart
│   │           ├── order_timeline.dart
│   │           └── tracking_map.dart
│   │
│   ├── review/ ...
│   ├── notification/ ...
│   ├── wishlist/ ...
│   └── profile/
│       ├── data/ ...
│       ├── domain/ ...
│       └── presentation/ ...
│
├── routing/
│   ├── app_router.dart                   # GoRouter configuration
│   ├── route_names.dart                  # Named route constants
│   └── route_guards.dart                 # Auth guards, approval guards
│
└── l10n/                                 # Localization
    ├── app_en.arb
    └── app_ar.arb
```

## 2.2 State Management: BLoC Pattern Rules

**Every feature has its own BLoC.** Never share BLoCs across unrelated features.

```dart
// ─── EVENTS: Describe what happened ─────────────────
abstract class ProductListEvent {}

class ProductListFetched extends ProductListEvent {
  final String? categoryId;
  final int page;
  ProductListFetched({this.categoryId, this.page = 1});
}

class ProductListFilterChanged extends ProductListEvent {
  final ProductFilter filter;
  ProductListFilterChanged(this.filter);
}

class ProductListSortChanged extends ProductListEvent {
  final SortOption sort;
  ProductListSortChanged(this.sort);
}


// ─── STATES: Describe the UI condition ──────────────
abstract class ProductListState {}

class ProductListInitial extends ProductListState {}

class ProductListLoading extends ProductListState {}

class ProductListLoaded extends ProductListState {
  final List<Product> products;
  final bool hasReachedMax;
  final int currentPage;
  final ProductFilter activeFilter;
  ProductListLoaded({
    required this.products,
    required this.hasReachedMax,
    required this.currentPage,
    required this.activeFilter,
  });
}

class ProductListError extends ProductListState {
  final String message;
  ProductListError(this.message);
}


// ─── BLOC: Transforms events into states ────────────
class ProductListBloc extends Bloc<ProductListEvent, ProductListState> {
  final GetProductsUseCase _getProducts;

  ProductListBloc(this._getProducts) : super(ProductListInitial()) {
    on<ProductListFetched>(_onFetched);
    on<ProductListFilterChanged>(_onFilterChanged);
  }

  Future<void> _onFetched(
    ProductListFetched event,
    Emitter<ProductListState> emit,
  ) async {
    emit(ProductListLoading());
    final result = await _getProducts(
      GetProductsParams(categoryId: event.categoryId, page: event.page),
    );
    result.fold(
      (failure) => emit(ProductListError(failure.message)),
      (data) => emit(ProductListLoaded(
        products: data.items,
        hasReachedMax: data.items.length < data.pageSize,
        currentPage: event.page,
        activeFilter: ProductFilter.empty(),
      )),
    );
  }
}
```

**BLoC Rules:**
- BLoCs never import Flutter widgets or `BuildContext`
- BLoCs only depend on UseCases (domain layer), never on DataSources or Repositories directly
- Every async operation returns `Either<Failure, Success>` (using the `dartz` package)
- BLoCs are provided via `BlocProvider` at the route level, not globally (unless truly app-wide like AuthBloc)

## 2.3 Networking Layer: Dio Configuration

```dart
class ApiClient {
  late final Dio _dio;

  ApiClient({required TokenStorage tokenStorage}) {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,      // e.g., https://api.medorder.com/api/v1
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-App-Version': AppConstants.appVersion,
        'X-Platform': Platform.isIOS ? 'ios' : 'android',
      },
    ));

    _dio.interceptors.addAll([
      AuthInterceptor(tokenStorage: tokenStorage, dio: _dio),
      LoggingInterceptor(),
      RetryInterceptor(dio: _dio, retries: 2),
    ]);
  }

  Future<ApiResponse<T>> get<T>(String path, {
    Map<String, dynamic>? queryParams,
    required T Function(dynamic) parser,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParams);
      return ApiResponse.success(parser(response.data['data']));
    } on DioException catch (e) {
      return ApiResponse.error(_mapDioError(e));
    }
  }

  // POST, PATCH, DELETE follow the same pattern...
}
```

## 2.4 Navigation: GoRouter with Guards

```dart
final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final authState = context.read<AuthBloc>().state;
    final isOnAuthPage = state.matchedLocation.startsWith('/auth');

    if (authState is AuthUnauthenticated && !isOnAuthPage) {
      return '/auth/welcome';
    }
    if (authState is AuthPendingApproval) {
      return '/auth/pending';
    }
    if (authState is AuthAuthenticated && isOnAuthPage) {
      return '/home';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/auth/welcome', builder: (_, __) => const WelcomePage()),
    GoRoute(path: '/auth/login', builder: (_, __) => const LoginPage()),
    GoRoute(path: '/auth/register', builder: (_, __) => const RegisterPage()),
    GoRoute(path: '/auth/pending', builder: (_, __) => const PendingApprovalPage()),

    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),   // Bottom nav bar
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomePage()),
        GoRoute(path: '/categories', builder: (_, __) => const CategoriesPage()),
        GoRoute(path: '/cart', builder: (_, __) => const CartPage()),
        GoRoute(path: '/orders', builder: (_, __) => const OrdersPage()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfilePage()),
      ],
    ),

    GoRoute(
      path: '/products/:id',
      builder: (_, state) => ProductDetailPage(id: state.pathParameters['id']!),
    ),
    GoRoute(path: '/checkout', builder: (_, __) => const CheckoutPage()),
    GoRoute(
      path: '/orders/:id',
      builder: (_, state) => OrderDetailPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/orders/:id/tracking',
      builder: (_, state) => OrderTrackingPage(id: state.pathParameters['id']!),
    ),
  ],
);
```

## 2.5 Flutter Code Style Rules

**Naming:**
- Files: `snake_case.dart` — always
- Classes: `PascalCase`
- Variables/functions: `camelCase`
- Constants: `camelCase` (Dart convention, not SCREAMING_SNAKE)
- BLoC events: past tense verb (`ProductListFetched`, `CartItemRemoved`)
- BLoC states: adjective/condition (`ProductListLoaded`, `CartEmpty`)
- Widgets: noun describing what it renders (`ProductCard`, `OrderTimeline`)

**Widget Rules:**
- Extract widgets into separate files when they exceed 80 lines
- Never put business logic in widgets — delegate to BLoC
- Use `const` constructors everywhere possible for performance
- Every list screen must implement: loading state (shimmer), error state (retry button), empty state (illustration + CTA)
- Never hardcode strings — use the l10n localization system
- Never hardcode colors or text styles — reference the theme

**Package Dependencies (recommended):**

```yaml
dependencies:
  flutter_bloc: ^8.1.0          # State management
  go_router: ^14.0.0            # Navigation
  dio: ^5.4.0                   # HTTP client
  get_it: ^7.6.0                # Dependency injection
  dartz: ^0.10.1                # Functional programming (Either type)
  cached_network_image: ^3.3.0  # Image caching
  flutter_secure_storage: ^9.0.0 # Secure token storage
  json_annotation: ^4.8.0       # JSON serialization
  equatable: ^2.0.5             # Value equality for states
  shimmer: ^3.0.0               # Loading skeletons
  google_maps_flutter: ^2.5.0   # Order tracking map
  firebase_messaging: ^14.7.0   # Push notifications
  image_picker: ^1.0.0          # Camera/gallery access
  intl: ^0.19.0                 # Date/number formatting
  flutter_svg: ^2.0.0           # SVG icons
  url_launcher: ^6.2.0          # External links
  connectivity_plus: ^5.0.0     # Network status

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.7.0
  bloc_test: ^9.1.0
  mocktail: ^1.0.0
  very_good_analysis: ^5.1.0    # Lint rules
```
