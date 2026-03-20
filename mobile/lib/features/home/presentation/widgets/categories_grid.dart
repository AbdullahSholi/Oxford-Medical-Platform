import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../product/domain/entities/category.dart';

class CategoriesGrid extends StatelessWidget {
  final List<Category> categories;

  const CategoriesGrid({super.key, required this.categories});

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.pagePadding,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.homeCategories,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              TextButton(
                onPressed: () => context.push('/categories'),
                child: Text(context.l10n.homeViewAll),
              ),
            ],
          ),
        ),
        AppSpacing.verticalGapSm,
        SizedBox(
          height: 200,
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            scrollDirection: Axis.horizontal,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.0,
            ),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              return _CategoryTile(category: category);
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;

  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/products?categoryId=${category.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: AppColors.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.medical_services_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            AppSpacing.verticalGapSm,
            Text(
              category.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
