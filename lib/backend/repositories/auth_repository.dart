import '../models/company_model.dart';
import '../models/employee_model.dart';

abstract class AuthRepository {
  Future<EmployeeEntity?> login({
    required String email,
    required String password,
    required String role, // 'company' or 'employee'
  });

  Future<EmployeeEntity?> registerEmployee({
    required String email,
    required String password,
    required String name,
    String? companyId,
    String? companyName,
  });

  Future<CompanyEntity?> registerCompany({
    required String companyName,
    required String address,
    required String gstNumber,
    required String ownerName,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> updateCompanyApprovalStatus({
    required String companyId,
    required bool isApproved,
  });

  Future<void> logout();

  Future<EmployeeEntity?> getCurrentUser();

  Stream<EmployeeEntity?> get authStateChanges;
}
