import 'package:cloud_firestore/cloud_firestore.dart';

import 'app_user.dart';

enum ProviderServiceType {
  towTruck,
  mechanic,
  fuelDelivery,
  flatTireChange,
  batteryBoost,
  serviceCenter,
}

extension ProviderServiceTypeX on ProviderServiceType {
  String get name => switch (this) {
    ProviderServiceType.towTruck => 'towTruck',
    ProviderServiceType.mechanic => 'mechanic',
    ProviderServiceType.fuelDelivery => 'fuelDelivery',
    ProviderServiceType.flatTireChange => 'flatTireChange',
    ProviderServiceType.batteryBoost => 'batteryBoost',
    ProviderServiceType.serviceCenter => 'serviceCenter',
  };

  String get label => switch (this) {
    ProviderServiceType.towTruck => 'Tow Truck',
    ProviderServiceType.mechanic => 'Mechanic',
    ProviderServiceType.fuelDelivery => 'Fuel Delivery',
    ProviderServiceType.flatTireChange => 'Flat Tire',
    ProviderServiceType.batteryBoost => 'Jump Start',
    ProviderServiceType.serviceCenter => 'Service Center',
  };

  String get iconAsset => switch (this) {
    ProviderServiceType.towTruck => 'assets/images/icon-towtruck.png',
    ProviderServiceType.mechanic => 'assets/images/icon-mechanic.png',
    ProviderServiceType.fuelDelivery => 'assets/images/icon-jerrycan.png',
    ProviderServiceType.flatTireChange => 'assets/images/icon-flattire.png',
    ProviderServiceType.batteryBoost => 'assets/images/icon-battery.png',
    ProviderServiceType.serviceCenter => '',
  };

  static ProviderServiceType fromString(String value) => switch (value) {
    'towTruck' => ProviderServiceType.towTruck,
    'mechanic' => ProviderServiceType.mechanic,
    'fuelDelivery' => ProviderServiceType.fuelDelivery,
    'flatTireChange' => ProviderServiceType.flatTireChange,
    'batteryBoost' => ProviderServiceType.batteryBoost,
    'serviceCenter' => ProviderServiceType.serviceCenter,
    _ => throw ArgumentError('Unknown provider service type: $value'),
  };
}

enum ServiceFieldInputType { text, number, multiline }

class ServiceFieldConfig {
  final String key;
  final String label;
  final ServiceFieldInputType inputType;

  const ServiceFieldConfig({
    required this.key,
    required this.label,
    this.inputType = ServiceFieldInputType.text,
  });
}

class ServiceTypeFormConfig {
  final List<ServiceFieldConfig> fields;
  final String titleFieldKey;
  final String subtitleFieldKey;

  const ServiceTypeFormConfig({
    required this.fields,
    required this.titleFieldKey,
    required this.subtitleFieldKey,
  });
}

const providerServiceFormConfig = <ProviderServiceType, ServiceTypeFormConfig>{
  ProviderServiceType.towTruck: ServiceTypeFormConfig(
    titleFieldKey: 'truckType', subtitleFieldKey: 'plateNumber', fields: [
      ServiceFieldConfig(key: 'contactName', label: 'Your Name *'),
      ServiceFieldConfig(key: 'truckType', label: 'Truck Type *'),
      ServiceFieldConfig(key: 'plateNumber', label: 'Plate NO *'),
      ServiceFieldConfig(key: 'capacity', label: 'Vehicles It Can Tow *'),
      ServiceFieldConfig(key: 'details', label: 'Details *', inputType: ServiceFieldInputType.multiline),
    ],
  ),
  ProviderServiceType.mechanic: ServiceTypeFormConfig(
    titleFieldKey: 'specialization', subtitleFieldKey: 'contactName', fields: [
      ServiceFieldConfig(key: 'contactName', label: 'Your Name *'),
      ServiceFieldConfig(key: 'specialization', label: 'Specialization *'),
      ServiceFieldConfig(key: 'experienceYears', label: 'Years of Experience *', inputType: ServiceFieldInputType.number),
      ServiceFieldConfig(key: 'details', label: 'Details *', inputType: ServiceFieldInputType.multiline),
    ],
  ),
  ProviderServiceType.fuelDelivery: ServiceTypeFormConfig(
    titleFieldKey: 'fuelTypes', subtitleFieldKey: 'plateNumber', fields: [
      ServiceFieldConfig(key: 'contactName', label: 'Your Name *'),
      ServiceFieldConfig(key: 'fuelTypes', label: 'Fuel Types Available *'),
      ServiceFieldConfig(key: 'plateNumber', label: 'Delivery Vehicle Plate NO *'),
      ServiceFieldConfig(key: 'details', label: 'Details *', inputType: ServiceFieldInputType.multiline),
    ],
  ),
  ProviderServiceType.flatTireChange: ServiceTypeFormConfig(
    titleFieldKey: 'toolsAvailable', subtitleFieldKey: 'plateNumber', fields: [
      ServiceFieldConfig(key: 'contactName', label: 'Your Name *'),
      ServiceFieldConfig(key: 'toolsAvailable', label: 'Tools Available *'),
      ServiceFieldConfig(key: 'plateNumber', label: 'Vehicle Plate NO *'),
      ServiceFieldConfig(key: 'details', label: 'Details *', inputType: ServiceFieldInputType.multiline),
    ],
  ),
  ProviderServiceType.batteryBoost: ServiceTypeFormConfig(
    titleFieldKey: 'equipment', subtitleFieldKey: 'plateNumber', fields: [
      ServiceFieldConfig(key: 'contactName', label: 'Your Name *'),
      ServiceFieldConfig(key: 'equipment', label: 'Equipment *'),
      ServiceFieldConfig(key: 'plateNumber', label: 'Vehicle Plate NO *'),
      ServiceFieldConfig(key: 'details', label: 'Details *', inputType: ServiceFieldInputType.multiline),
    ],
  ),
  ProviderServiceType.serviceCenter: ServiceTypeFormConfig(
    titleFieldKey: 'centerName', subtitleFieldKey: 'address', fields: [
      ServiceFieldConfig(key: 'centerName', label: 'Service Center Name *'),
      ServiceFieldConfig(key: 'address', label: 'Address *'),
      ServiceFieldConfig(key: 'operatingHours', label: 'Operating Hours *'),
      ServiceFieldConfig(key: 'servicesAvailable', label: 'Services Available *'),
      ServiceFieldConfig(key: 'details', label: 'Details *', inputType: ServiceFieldInputType.multiline),
    ],
  ),
};

class ProviderService {
  final String id;
  final String providerId;
  final ProviderServiceType serviceType;
  final Map<String, String> fields;
  final GeoLocation location;

  const ProviderService({
    required this.id,
    required this.providerId,
    required this.serviceType,
    required this.fields,
    this.location = const GeoLocation(latitude: 0, longitude: 0),
  });

  factory ProviderService.fromMap(String id, Map<String, dynamic> map) {
    final rawFields = map['fields'] as Map<String, dynamic>? ?? {};
    return ProviderService(
      id: id,
      providerId: map['providerId'] as String? ?? '',
      serviceType: ProviderServiceTypeX.fromString(map['serviceType'] as String? ?? 'towTruck'),
      fields: rawFields.map((key, value) => MapEntry(key, '$value')),
      location: GeoLocation.fromMap(map['location'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toMap() => {
    'providerId': providerId,
    'serviceType': serviceType.name,
    'fields': fields,
    'location': location.toMap(),
  };

  ServiceTypeFormConfig get formConfig => providerServiceFormConfig[serviceType]!;
  String get title => fields[formConfig.titleFieldKey] ?? '';
  String get subtitle => fields[formConfig.subtitleFieldKey] ?? '';
  String get displayLabel => subtitle.isEmpty ? title : '$title · $subtitle';
}

const _collection = 'provider_services';

Future<List<ProviderService>> fetchProviderServices(String providerId) async {
  final query = await FirebaseFirestore.instance.collection(_collection).where('providerId', isEqualTo: providerId).get();
  return query.docs.map((doc) => ProviderService.fromMap(doc.id, doc.data())).toList();
}

Future<ProviderService> addProviderService(ProviderService service) async {
  final ref = await FirebaseFirestore.instance.collection(_collection).add(service.toMap());
  return ProviderService(id: ref.id, providerId: service.providerId, serviceType: service.serviceType, fields: service.fields, location: service.location);
}

Future<void> updateProviderService(ProviderService service) => FirebaseFirestore.instance.collection(_collection).doc(service.id).set(service.toMap());
Future<void> deleteProviderService(String serviceId) => FirebaseFirestore.instance.collection(_collection).doc(serviceId).delete();
