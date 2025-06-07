import 'package:dartz/dartz.dart';
import 'package:product_gamers/domain/usecases/get_fixture_full_data_usecase.dart';
import '../../core/config/failure.dart';
import '../entities/entities/suggested_bet_slip.dart';
import '../entities/entities/fixture_full_data.dart';
import '../repositories/football_repository.dart';

import 'prognostic_engine.dart';

class GenerateSuggestedSlipsUseCase {
  final GetFixtureFullDataUseCase _getFixtureFullDataUseCase;
  final PrognosticEngine _prognosticEngine;

  GenerateSuggestedSlipsUseCase({
    required GetFixtureFullDataUseCase getFixtureFullDataUseCase,
  })  : _getFixtureFullDataUseCase = getFixtureFullDataUseCase,
        _prognosticEngine = PrognosticEngine();

  /// Chamada principal — gera SuggestedBetSlips para um fixtureId
  Future<Either<Failure, List<SuggestedBetSlip>>> call(int fixtureId) async {
    try {
      // Primeiro busca FixtureFullData
      final fixtureFullDataResult =
          await _getFixtureFullDataUseCase.call(fixtureId);

      return fixtureFullDataResult.fold(
        (failure) => Left(failure),
        (fixtureFullData) {
          // Se FixtureFullData foi carregado com sucesso, gera prognósticos
          final overUnderSlip =
              _prognosticEngine.suggestOverUnderGoals(fixtureFullData);
          final bttsSlip = _prognosticEngine.suggestBTTS(fixtureFullData);
          final cardsSlip = _prognosticEngine.suggestCards(fixtureFullData);
          final cornersSlip = _prognosticEngine.suggestCorners(fixtureFullData);

          // Filtra sugestões com confiança >= 0.5 (você pode ajustar isso)
          final suggestions = [
            overUnderSlip,
            bttsSlip,
            cardsSlip,
            cornersSlip,
          ].where((slip) => slip.confidence >= 0.5).toList();

          // Ordena por confiança decrescente (opcional)
          suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));

          return Right(suggestions);
        },
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Erro ao gerar prognósticos: $e'));
    }
  }
}
