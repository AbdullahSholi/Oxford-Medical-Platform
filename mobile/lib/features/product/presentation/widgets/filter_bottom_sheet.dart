import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../home/domain/entities/brand.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/product.dart';

class FilterBottomSheet extends StatefulWidget {
  final ProductFilter currentFilter;
  final ValueChanged<ProductFilter> onApply;
  final List<Category> categories;
  final List<Brand> brands;

  const FilterBottomSheet({
    super.key,
    required this.currentFilter,
    required this.onApply,
    this.categories = const [],
    this.brands = const [],
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _priceRange;
  late bool _inStockOnly;
  String? _selectedCategoryId;
  String? _selectedBrandId;

  @override
  void initState() {
    super.initState();
    _priceRange = RangeValues(
      widget.currentFilter.minPrice ?? 0,
      widget.currentFilter.maxPrice ?? 10000,
    );
    _inStockOnly = widget.currentFilter.inStockOnly ?? false;
    _selectedCategoryId = widget.currentFilter.categoryId;
    _selectedBrandId = widget.currentFilter.brandId;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.xl,
        right: AppSpacing.xl,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primarySurface,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.tune_rounded, size: 18, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Filters',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          AppSpacing.verticalGapLg,
          // Category filter
          if (widget.categories.isNotEmpty) ...[
            _SectionLabel(icon: Icons.category_outlined, label: 'Category'),
            AppSpacing.verticalGapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildChip(label: 'All', value: null),
                ...widget.categories.map((cat) =>
                    _buildChip(label: cat.name, value: cat.id)),
              ],
            ),
            AppSpacing.verticalGapLg,
          ],
          // Brand filter
          if (widget.brands.isNotEmpty) ...[
            _SectionLabel(icon: Icons.branding_watermark_outlined, label: 'Brand'),
            AppSpacing.verticalGapSm,
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildBrandChip(label: 'All', value: null),
                ...widget.brands.map((brand) =>
                    _buildBrandChip(label: brand.name, value: brand.id)),
              ],
            ),
            AppSpacing.verticalGapLg,
          ],
          // Price range
          _SectionLabel(icon: Icons.payments_outlined, label: 'Price Range'),
          AppSpacing.verticalGapXs,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'EGP ${_priceRange.start.round()}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  'EGP ${_priceRange.end.round()}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _priceRange,
            min: 0,
            max: 10000,
            divisions: 100,
            labels: RangeLabels(
              'EGP ${_priceRange.start.round()}',
              'EGP ${_priceRange.end.round()}',
            ),
            onChanged: (values) => setState(() => _priceRange = values),
          ),
          AppSpacing.verticalGapSm,
          // In stock toggle
          GestureDetector(
            onTap: () => setState(() => _inStockOnly = !_inStockOnly),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _inStockOnly ? AppColors.primarySurface : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: _inStockOnly ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _inStockOnly ? Icons.check_circle_rounded : Icons.circle_outlined,
                    color: _inStockOnly ? AppColors.primary : AppColors.textHint,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Text('In Stock Only', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          AppSpacing.verticalGapXl,
          AppButton(
            label: 'Apply Filters',
            variant: AppButtonVariant.gradient,
            onPressed: () {
              widget.onApply(ProductFilter(
                categoryId: _selectedCategoryId,
                brandId: _selectedBrandId,
                minPrice: _priceRange.start > 0 ? _priceRange.start : null,
                maxPrice: _priceRange.end < 10000 ? _priceRange.end : null,
                inStockOnly: _inStockOnly ? true : null,
              ));
              Navigator.pop(context);
            },
          ),
          AppSpacing.verticalGapLg,
        ],
      ),
    );
  }

  Widget _buildChip({required String label, required String? value}) {
    final isSelected = _selectedCategoryId == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBrandChip({required String label, required String? value}) {
    final isSelected = _selectedBrandId == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedBrandId = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primarySurface : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          border: Border.all(
            color: isSelected ? AppColors.primary.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _reset() {
    setState(() {
      _priceRange = const RangeValues(0, 10000);
      _inStockOnly = false;
      _selectedCategoryId = null;
      _selectedBrandId = null;
    });
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
