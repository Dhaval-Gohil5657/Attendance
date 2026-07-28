import '../../domain/entities/company_entity.dart';

class CompanyModel extends CompanyEntity {
  const CompanyModel({
    required super.companyId,
    required super.companyName,
    required super.address,
    required super.gstNumber,
    required super.ownerName,
    required super.email,
    required super.phone,
    super.isApproved = false,
    required super.createdAt,
  });

  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'address': address,
      'gstNumber': gstNumber,
      'ownerName': ownerName,
      'email': email,
      'phone': phone,
      'isApproved': isApproved,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CompanyModel.fromMap(Map<String, dynamic> map, String companyId) {
    return CompanyModel(
      companyId: companyId,
      companyName: map['companyName'] ?? '',
      address: map['address'] ?? '',
      gstNumber: map['gstNumber'] ?? '',
      ownerName: map['ownerName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      isApproved: map['isApproved'] ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
