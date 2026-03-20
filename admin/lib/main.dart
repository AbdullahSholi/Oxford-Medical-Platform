import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'features/auth/cubit/auth_cubit.dart';

void main() {
  const storage = FlutterSecureStorage();
  final apiClient = ApiClient(storage: storage);

  runApp(AdminApp(apiClient: apiClient, storage: storage));
}

class AdminApp extends StatelessWidget {
  final ApiClient apiClient;
  final FlutterSecureStorage storage;

  const AdminApp({super.key, required this.apiClient, required this.storage});

  @override
  Widget build(BuildContext context) {
    final authCubit = AuthCubit(apiClient: apiClient, storage: storage)..checkAuth();
    final router = AppRouter.createRouter(authCubit);

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authCubit),
      ],
      child: MaterialApp.router(
        title: 'MedOrder Admin',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.light,
          ),
          fontFamily: 'Inter',
        ),
        routerConfig: router,
      ),
    );
  }
}
