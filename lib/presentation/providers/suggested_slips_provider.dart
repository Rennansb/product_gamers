// lib/presentation/providers/suggested_slips_provider.dart
import 'package:flutter/material.dart';
import 'package:product_gamers/core/config/failure.dart';
import 'package:product_gamers/domain/entities/entities/fixture.dart';
import 'package:product_gamers/domain/entities/entities/suggested_bet_slip.dart';
// <<< IMPORT CORRETO
import '../../domain/usecases/get_fixtures_usecase.dart';
import '../../domain/usecases/generate_suggested_slips_usecase.dart'; // <<< IMPORT CORRETO
import '../../core/config/app_constants.dart'; // Para AppConstants.popularLeagues

enum SuggestedSlipsStatus { initial, loading, loaded, error, empty }

class SuggestedSlipsProvider with ChangeNotifier {
  final GetFixturesUseCase _getFixturesUseCase;
  final GenerateSuggestedSlipsUseCase _generateSuggestedSlipsUseCase;

  SuggestedSlipsProvider(
    this._getFixturesUseCase,
    this._generateSuggestedSlipsUseCase,
  );

  SuggestedSlipsStatus _status = SuggestedSlipsStatus.initial;
  List<SuggestedBetSlip> _suggestedSlips = []; // <<< TIPO CORRETO
  String? _errorMessage;

  SuggestedSlipsStatus get status => _status;
  List<SuggestedBetSlip> get suggestedSlips =>
      _suggestedSlips; // <<< TIPO CORRETO
  String? get errorMessage => _errorMessage;

  bool _isFetching = false;

  Future<void> generateDailySlips({bool forceRefresh = false}) async {
    if (_isFetching && !forceRefresh) return;
    // Permite refresh mesmo se já carregado e com slips, se forceRefresh = true
    if (_status == SuggestedSlipsStatus.loaded &&
        _suggestedSlips.isNotEmpty &&
        !forceRefresh) {
      // print("Bilhetes já carregados, não buscando novamente a menos que forceRefresh seja true.");
      // return; // Comentei para permitir o refresh manual funcionar melhor
    }

    _isFetching = true;
    _status = SuggestedSlipsStatus.loading;
    if (forceRefresh) {
      // Limpa apenas se for refresh para não perder dados de erro anteriores
      _suggestedSlips = [];
      _errorMessage = null;
    }
    notifyListeners();

    try {
      final List<Fixture> todayFixtures = await _fetchTodayFixtures();

      if (todayFixtures.isEmpty) {
        _status = SuggestedSlipsStatus.empty;
        _errorMessage = "Nenhum jogo encontrado para hoje para gerar bilhetes.";
        _isFetching = false;
        notifyListeners();
        return;
      }

      final result = await _generateSuggestedSlipsUseCase(
        // Chamada ao UseCase
        fixturesForToday: todayFixtures,
        // targetTotalOdd e maxSelectionsPerSlip usam os defaults do UseCase
      );

      result.fold(
        (failure) {
          _errorMessage = _mapFailureToMessage(failure);
          _status = SuggestedSlipsStatus.error;
          _suggestedSlips = []; // Limpa em caso de erro
        },
        (slips) {
          _suggestedSlips = slips;
          if (_suggestedSlips.isEmpty) {
            _status = SuggestedSlipsStatus.empty;
            _errorMessage =
                "Não foi possível gerar bilhetes com os critérios e jogos de hoje.";
          } else {
            _status = SuggestedSlipsStatus.loaded;
            _errorMessage = null; // Limpa erro se sucesso
          }
        },
      );
    } catch (e, s) {
      print("Erro EXCEPCIONAL ao gerar bilhetes: $e\n$s");
      _errorMessage = "Erro inesperado ao gerar bilhetes: ${e.toString()}";
      _status = SuggestedSlipsStatus.error;
      _suggestedSlips = []; // Limpa em caso de erro
    } finally {
      _isFetching = false;
      notifyListeners();
    }
  }

  Future<List<Fixture>> _fetchTodayFixtures() async {
    List<Fixture> allFixturesForToday = [];
    final today = DateTime.now();
    final String season = today.year.toString();

    for (int leagueId in AppConstants.popularLeagues.values) {
      final fixtureResult = await _getFixturesUseCase(
        leagueId: leagueId,
        season: season,
        nextGames:
            25, // Aumentar um pouco para garantir jogos do dia em ligas grandes
      );
      fixtureResult.fold(
        (l) => print(
          "Falha ao buscar jogos para liga $leagueId para bilhetes: ${l.message}",
        ),
        (fixtures) {
          allFixturesForToday.addAll(
            fixtures.where((f) {
              final gameDate = f.date.toLocal();
              return gameDate.year == today.year &&
                  gameDate.month == today.month &&
                  gameDate.day == today.day &&
                  f.statusShort.toUpperCase() == 'NS';
            }),
          );
        },
      );
      // Pequena pausa para não sobrecarregar a API rapidamente se tiver muitas ligas
      await Future.delayed(const Duration(milliseconds: 200));
    }

    final uniqueFixtures =
        Map.fromEntries(
          allFixturesForToday.map((f) => MapEntry(f?.id, f)),
        ).values.toList();
    uniqueFixtures.sort((a, b) => a.date.compareTo(b!.date));
    print(
      "Encontrados ${uniqueFixtures.length} jogos de hoje para análise de bilhetes.",
    );
    return uniqueFixtures;
  }

  String _mapFailureToMessage(Failure failure) {
    if (failure is ServerFailure) return 'Servidor API: ${failure.message}';
    if (failure is NetworkFailure) return 'Rede: ${failure.message}';
    if (failure is AuthenticationFailure)
      return 'Autenticação API: ${failure.message}';
    if (failure is ApiFailure) return 'API: ${failure.message}';
    if (failure is NoDataFailure) return failure.message;
    return 'Erro ao gerar bilhetes: ${failure.message}';
  }
}
