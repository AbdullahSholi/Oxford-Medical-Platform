import 'package:equatable/equatable.dart';

class Brand extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;

  const Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
  });

  @override
  List<Object?> get props => [id];
}
