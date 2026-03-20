import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:medorder/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart' as di;
import 'core/l10n/locale_cubit.dart';
import 'core/services/push_notification_service.dart';
import 'core/services/socket_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/cart/presentation/bloc/cart_bloc.dart';
import 'features/home/presentation/bloc/home_bloc.dart';
import 'features/notification/presentation/bloc/notification_bloc.dart';
import 'features/order/presentation/bloc/order_list_bloc.dart';
import 'features/wishlist/presentation/bloc/wishlist_bloc.dart';
import 'routing/app_router.dart';

class MedOrderApp extends StatefulWidget {
  const MedOrderApp({super.key});

  @override
  State<MedOrderApp> createState() => _MedOrderAppState();
}

class _MedOrderAppState extends State<MedOrderApp> {
  late final AuthBloc _authBloc;
  late final NotificationBloc _notificationBloc;
  late final GoRouter _router;
  final _socketService = di.sl<SocketService>();
  StreamSubscription<Map<String, dynamic>>? _notifSub;

  @override
  void initState() {
    super.initState();
    _authBloc = di.sl<AuthBloc>()..add(const AuthCheckRequested());
    _notificationBloc = di.sl<NotificationBloc>();
    _router = createRouter(_authBloc);
  }

  void _onAuthStateChanged(AuthState state) {
    if (state is AuthAuthenticated) {
      _connectSocket();
      di.sl<PushNotificationService>().initialize();
    } else if (state is AuthUnauthenticated) {
      _disconnectSocket();
    }
  }

  Future<void> _connectSocket() async {
    final token = await di.sl<FlutterSecureStorage>().read(key: AppConstants.accessTokenKey);
    if (token != null) {
      _socketService.connect(token);
      _notifSub?.cancel();
      _notifSub = _socketService.onNotification.listen((_) {
        _notificationBloc.add(const NotificationsFetched());
      });
    }
  }

  void _disconnectSocket() {
    _notifSub?.cancel();
    _notifSub = null;
    _socketService.disconnect();
  }

  @override
  void dispose() {
    _disconnectSocket();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(create: (_) => _authBloc),
        BlocProvider<HomeBloc>(create: (_) => di.sl<HomeBloc>()),
        BlocProvider<CartBloc>(create: (_) => di.sl<CartBloc>()),
        BlocProvider<NotificationBloc>(create: (_) => _notificationBloc),
        BlocProvider<OrderListBloc>(create: (_) => di.sl<OrderListBloc>()),
        BlocProvider<WishlistBloc>(create: (_) => di.sl<WishlistBloc>()),
        BlocProvider<LocaleCubit>(create: (_) => di.sl<LocaleCubit>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) => _onAuthStateChanged(state),
        child: BlocBuilder<LocaleCubit, Locale>(
          builder: (context, locale) {
            return MaterialApp.router(
              title: 'MedOrder',
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              locale: locale,
              routerConfig: _router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('ar'),
              ],
            );
          },
        ),
      ),
    );
  }
}
