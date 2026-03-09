// models/certificate_data.dart

class CertificateData {
  final String studentName;
  final String courseName;
  final String instructorName;
  final DateTime completionDate;
  final String certificateId;

  const CertificateData({
    required this.studentName,
    required this.courseName,
    required this.instructorName,
    required this.completionDate,
    required this.certificateId,
  });
}