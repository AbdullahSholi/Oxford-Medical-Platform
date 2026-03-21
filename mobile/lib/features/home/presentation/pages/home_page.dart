import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_error_widget.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../notification/presentation/bloc/notification_bloc.dart';
import '../../../wishlist/presentation/bloc/wishlist_bloc.dart';
import '../bloc/home_bloc.dart';
import '../bloc/home_event.dart';
import '../bloc/home_state.dart';
import '../widgets/best_sellers_section.dart';
import '../widgets/categories_grid.dart';
import '../widgets/flash_sale_section.dart';
import '../widgets/promo_slider.dart';
import '../widgets/welcome_banner.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(
                    Icons.local_hospital_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  context.l10n.appTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            actions: [
              _ActionButton(
                icon: Icons.search_rounded,
                onPressed: () => context.push('/search'),
              ),
              BlocBuilder<NotificationBloc, NotificationState>(
                builder: (context, state) {
                  final unread = state is NotificationLoaded ? state.unreadCount : 0;
                  return _ActionButton(
                    icon: Icons.notifications_outlined,
                    badgeCount: unread,
                    onPressed: () => context.push('/notifications'),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
        body: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            if (state is HomeInitial) {
              context.read<HomeBloc>().add(const HomeDataFetched());
              context.read<NotificationBloc>().add(const NotificationsFetched());
              context.read<WishlistBloc>().add(const WishlistFetched());
              return const AppLoading();
            }
            if (state is HomeLoading) {
              return const AppLoading();
            }
            if (state is HomeError) {
              return AppErrorWidget(
                message: state.message,
                onRetry: () =>
                    context.read<HomeBloc>().add(const HomeDataFetched()),
              );
            }
            if (state is HomeLoaded) {
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  context.read<HomeBloc>().add(const HomeRefreshed());
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      AppSpacing.verticalGapLg,
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, authState) {
                          final name = authState is AuthAuthenticated
                              ? authState.doctor.fullName.replaceFirst(RegExp(r'^Dr\.?\s*', caseSensitive: false), '').split(' ').first
                              : '';
                          return WelcomeBanner(doctorName: name);
                        },
                      ),
                      AppSpacing.verticalGapXl,
                      PromoSlider(banners: state.banners),
                      AppSpacing.verticalGapXl,
                      CategoriesGrid(categories: state.categories),
                      AppSpacing.verticalGapXl,
                      if (state.flashSale != null) ...[
                        FlashSaleSection(flashSale: state.flashSale!),
                        AppSpacing.verticalGapXl,
                      ],
                      BestSellersSection(products: state.bestSellers),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final int badgeCount;

  const _ActionButton({
    required this.icon,
    required this.onPressed,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Badge(
              isLabelVisible: badgeCount > 0,
              label: Text(
                '$badgeCount',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
              backgroundColor: AppColors.secondary,
              child: Icon(icon, size: 22, color: AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
