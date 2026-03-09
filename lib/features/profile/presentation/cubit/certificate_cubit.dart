import 'package:bloc/bloc.dart';
import 'package:e_learning/core/erros/app_exceptions.dart';
import 'package:e_learning/core/erros/network_exception_handler.dart';
import 'package:e_learning/features/profile/data/repo/certificate_repo.dart';
import 'package:e_learning/features/profile/presentation/cubit/certificate_states.dart';

class CertificateCubit extends Cubit<CertificateState> {
  final CertificateRepo _repo;

  CertificateCubit(this._repo) : super(CertificateInitial());

  Future<void> fetchCertificates(String userId) async {
    emit(CertificateLoading());
    try {
      final certificates = await _repo.fetchCertificates(userId);
      emit(CertificateLoaded(certificates));
    } on AppException catch (e) {
      emit(CertificateError(e));
    } catch (e) {
      emit(CertificateError(NetworkExceptionHandler.handle(e)));
    }
  }
}