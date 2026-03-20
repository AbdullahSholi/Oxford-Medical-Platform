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
                      letterSpacing: -0.3,
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
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
              return _CategoryTile(
                category: category,
                colorIndex: index,
              );
            },
          ),
        ),
      ],
    );
  }
}

// Each category gets a unique accent color for visual richness
const _categoryColors = [
  Color(0xFF1565C0), // blue
  Color(0xFF7C3AED), // violet
  Color(0xFF059669), // emerald
  Color(0xFFEA580C), // orange
  Color(0xFFDB2777), // pink
  Color(0xFF0891B2), // cyan
  Color(0xFFCA8A04), // amber
  Color(0xFF4F46E5), // indigo
];

class _CategoryTile extends StatelessWidget {
  final Category category;
  final int colorIndex;

  const _CategoryTile({required this.category, required this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final color = _categoryColors[colorIndex % _categoryColors.length];
    return GestureDetector(
      onTap: () => context.push('/products?categoryId=${category.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                Icons.medical_services_outlined,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color.withOpacity(0.9),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
