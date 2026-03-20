import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final String? iconUrl;
  final String? parentId;
  final int productCount;
  final List<Category> subcategories;

  const Category({
    required this.id,
    required this.name,
    this.imageUrl,
    this.iconUrl,
    this.parentId,
    this.productCount = 0,
    this.subcategories = const [],
  });

  @override
  List<Object?> get props => [id];
}
