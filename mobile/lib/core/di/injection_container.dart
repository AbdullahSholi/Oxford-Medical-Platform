import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/locale_cubit.dart';
import '../network/api_client.dart';
import '../network/network_info.dart';
import '../services/local_cache_service.dart';
import '../services/push_notification_service.dart';
import '../services/socket_service.dart';

// Auth
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/verify_otp_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

// Home
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home_data_usecase.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';

// Product
import '../../features/product/data/datasources/product_remote_datasource.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/domain/repositories/product_repository.dart';
import '../../features/product/domain/usecases/get_product_detail_usecase.dart';
import '../../features/product/domain/usecases/get_products_usecase.dart';
import '../../features/product/domain/usecases/search_products_usecase.dart';
import '../../features/product/presentation/bloc/product_detail_bloc.dart';
import '../../features/product/presentation/bloc/product_list_bloc.dart';
import '../../features/product/presentation/bloc/search_bloc.dart';

// Cart
import '../../features/cart/data/datasources/cart_remote_datasource.dart';
import '../../features/cart/data/repositories/cart_repository_impl.dart';
import '../../features/cart/domain/repositories/cart_repository.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';

// Order
import '../../features/order/data/datasources/order_remote_datasource.dart';
import '../../features/order/data/repositories/order_repository_impl.dart';
import '../../features/order/domain/repositories/order_repository.dart';
import '../../features/order/presentation/bloc/order_detail_bloc.dart';
import '../../features/order/presentation/bloc/order_list_bloc.dart';

// Notification & Wishlist
import '../../features/notification/presentation/bloc/notification_bloc.dart';
import '../../features/wishlist/presentation/bloc/wishlist_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ─── Core ─────────────────────────────────────────────
  const storage = FlutterSecureStorage();
  sl.registerLazySingleton<FlutterSecureStorage>(() => storage);
  sl.registerLazySingleton<ApiClient>(() => ApiClient(storage: sl()));
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(Connectivity()));
  sl.registerLazySingleton<SocketService>(() => SocketService());

  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<LocalCacheService>(() => LocalCacheService(prefs));
  sl.registerLazySingleton<PushNotificationService>(() => PushNotificationService(sl()));
  sl.registerLazySingleton<LocaleCubit>(() => LocaleCubit(prefs));

  // ─── Auth ─────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(sl(), apiClient: sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl(),
      local: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl(),
        registerUseCase: sl(),
        verifyOtpUseCase: sl(),
        logoutUseCase: sl(),
        authRepository: sl(),
      ));

  // ─── Home ─────────────────────────────────────────────
  sl.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(remote: sl(), networkInfo: sl(), cache: sl()),
  );
  sl.registerLazySingleton(() => GetHomeDataUseCase(sl()));
  sl.registerFactory(() => HomeBloc(sl()));

  // ─── Product ──────────────────────────────────────────
  sl.registerLazySingleton<ProductRemoteDataSource>(
    () => ProductRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(remote: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton(() => GetProductsUseCase(sl()));
  sl.registerLazySingleton(() => GetProductDetailUseCase(sl()));
  sl.registerLazySingleton(() => SearchProductsUseCase(sl()));
  sl.registerFactory(() => ProductListBloc(sl()));
  sl.registerFactory(() => ProductDetailBloc(sl(), sl()));
  sl.registerFactory(() => SearchBloc(sl()));

  // ─── Cart ─────────────────────────────────────────────
  sl.registerLazySingleton<CartRemoteDataSource>(
    () => CartRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<CartRepository>(
    () => CartRepositoryImpl(remote: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => CartBloc(sl()));

  // ─── Order ────────────────────────────────────────────
  sl.registerLazySingleton<OrderRemoteDataSource>(
    () => OrderRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<OrderRepository>(
    () => OrderRepositoryImpl(remote: sl(), networkInfo: sl()),
  );
  sl.registerFactory(() => OrderListBloc(sl()));
  sl.registerFactory(() => OrderDetailBloc(sl()));

  // ─── Notification & Wishlist ──────────────────────────
  sl.registerFactory(() => NotificationBloc(sl()));
  sl.registerFactory(() => WishlistBloc(sl()));
}
