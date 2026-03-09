import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/features/profile/data/models/certificate_data.dart';

abstract class CertificateState {}

class CertificateInitial extends CertificateState {}

class CertificateLoading extends CertificateState {}

class CertificateLoaded extends CertificateState {
  final List<CertificateData> certificates;
  CertificateLoaded(this.certificates);
}

class CertificateError extends CertificateState {
  final AppException exception;
  CertificateError(this.exception);
}