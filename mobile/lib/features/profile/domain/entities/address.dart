import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final String id;
  final String label;
  final String street;
  final String city;
  final String? area;
  final String? building;
  final String? floor;
  final String? notes;
  final bool isDefault;
  final double? lat;
  final double? lng;

  const Address({
    required this.id,
    required this.label,
    required this.street,
    required this.city,
    this.area,
    this.building,
    this.floor,
    this.notes,
    this.isDefault = false,
    this.lat,
    this.lng,
  });

  String get fullAddress => [street, area, building, floor, city].where((s) => s != null && s.isNotEmpty).join(', ');

  @override
  List<Object?> get props => [id];
}
