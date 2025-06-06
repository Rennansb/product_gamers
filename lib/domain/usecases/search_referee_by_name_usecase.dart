// lib/domain/usecases/search_referee_by_name_usecase.dart
import 'package:dartz/dartz.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/referee_stats.dart';
// Para RefereeBasicInfo
import '../repositories/football_repository.dart';

class SearchRefereeByNameUseCase {
  final FootballRepository repository;
  SearchRefereeByNameUseCase(this.repository);
  Future<Either<Failure, List<RefereeBasicInfo>>> call(
          {required String name}) async =>
      repository.searchRefereeByName(name: name);
}
