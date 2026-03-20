import '../../domain/entities/address.dart';

class AddressModel extends Address {
  const AddressModel({
    required super.id, required super.label, required super.street, required super.city,
    super.area, super.building, super.floor, super.notes, super.isDefault, super.lat, super.lng,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
    id: json['id'] as String, label: json['label'] as String,
    street: json['street'] as String, city: json['city'] as String,
    area: json['area'] as String?, building: json['building'] as String?,
    floor: json['floor'] as String?, notes: json['notes'] as String?,
    isDefault: json['isDefault'] as bool? ?? false,
    lat: (json['lat'] as num?)?.toDouble(), lng: (json['lng'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'label': label, 'street': street, 'city': city,
    if (area != null) 'area': area, if (building != null) 'building': building,
    if (floor != null) 'floor': floor, if (notes != null) 'notes': notes,
    'isDefault': isDefault, if (lat != null) 'lat': lat, if (lng != null) 'lng': lng,
  };
}
