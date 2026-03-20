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
        top: AppSpacing.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filters',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              TextButton(
                onPressed: _reset,
                child: const Text('Reset'),
              ),
            ],
          ),
          AppSpacing.verticalGapLg,
          // Category filter
          if (widget.categories.isNotEmpty) ...[
            Text('Category',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
            Text('Brand',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
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
          Text('Price Range',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          AppSpacing.verticalGapXs,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('EGP ${_priceRange.start.round()}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text('EGP ${_priceRange.end.round()}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
          AppSpacing.verticalGapMd,
          // In stock toggle
          SwitchListTile(
            title: const Text('In Stock Only'),
            value: _inStockOnly,
            onChanged: (value) => setState(() => _inStockOnly = value),
            contentPadding: EdgeInsets.zero,
          ),
          AppSpacing.verticalGapXl,
          AppButton(
            label: 'Apply Filters',
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
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedCategoryId = value),
      selectedColor: AppColors.primaryLight.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
      ),
    );
  }

  Widget _buildBrandChip({required String label, required String? value}) {
    final isSelected = _selectedBrandId == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedBrandId = value),
      selectedColor: AppColors.primaryLight.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        fontSize: 13,
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
