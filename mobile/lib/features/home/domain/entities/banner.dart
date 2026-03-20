import 'package:equatable/equatable.dart';

class PromoBanner extends Equatable {
  final String id;
  final String title;
  final String imageUrl;
  final String? actionUrl;
  final bool isActive;

  const PromoBanner({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.actionUrl,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id];
}
