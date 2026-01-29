import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/work.dart';

abstract class WorkRepository {
  Future<Either<Failure, List<Work>>> getWorks(String userId);
  Future<Either<Failure, void>> addWork(Work work, File? file);
  Future<Either<Failure, void>> updateWork(Work work);
  Future<Either<Failure, void>> deleteWork(String workId, String userId);
}
