import 'package:equatable/equatable.dart';

class CompanyModel extends Equatable {
  final String companyId;
  final String companyName;
  final String address;
  final String gstNumber;
  final String ownerName;
  final String email;
  final String phone;
  final bool isApproved;
  final DateTime createdAt;

  const CompanyModel({
    required this.companyId,
    required this.companyName,
    required this.address,
    required this.gstNumber,
    required this.ownerName,
    required this.email,
    required this.phone,
    this.isApproved = false,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        companyId,
        companyName,
        address,
        gstNumber,
        ownerName,
        email,
        phone,
        isApproved,
        createdAt,
      ];

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

typedef CompanyEntity = CompanyModel;
