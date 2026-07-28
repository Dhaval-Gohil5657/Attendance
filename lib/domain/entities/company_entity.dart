import 'package:equatable/equatable.dart';

class CompanyEntity extends Equatable {
  final String companyId;
  final String companyName;
  final String address;
  final String gstNumber;
  final String ownerName;
  final String email;
  final String phone;
  final bool isApproved;
  final DateTime createdAt;

  const CompanyEntity({
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
}
