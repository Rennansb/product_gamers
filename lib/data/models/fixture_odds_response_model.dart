// lib/data/models/fixture_odds_response_model.dart
import 'package:equatable/equatable.dart';
import 'bookmaker_odds_model.dart';
import 'package:product_gamers/domain/entities/entities/prognostic_market.dart';

class FixtureOddsResponseModel extends Equatable {
  final int fixtureId; // ID do fixture ao qual estas odds pertencem
  final List<BookmakerOddsModel> bookmakers;

  const FixtureOddsResponseModel({
    required this.fixtureId,
    required this.bookmakers,
  });

  // A API-Football para /odds?fixture={id} retorna uma lista,
  // e o primeiro (geralmente único) item dessa lista contém 'fixture' e 'bookmakers'.
  factory FixtureOddsResponseModel.fromApiResponse(
    List<dynamic> apiResponse,
    int requestedFixtureId,
  ) {
    if (apiResponse.isEmpty) {
      // Retorna um modelo vazio se a API não retornar dados de odds
      return FixtureOddsResponseModel(
        fixtureId: requestedFixtureId,
        bookmakers: [],
      );
    }

    // O objeto principal que contém 'fixture' (info do jogo) e 'bookmakers'
    final Map<String, dynamic> responseData =
        apiResponse.first as Map<String, dynamic>;

    // Pega o ID do fixture da resposta, se disponível, senão usa o ID solicitado
    final int parsedFixtureId =
        responseData['fixture']?['id'] as int? ?? requestedFixtureId;

    var bookmakersList =
        (responseData['bookmakers'] as List<dynamic>?)
            ?.map((b) => BookmakerOddsModel.fromJson(b as Map<String, dynamic>))
            .toList() ??
        [];

    return FixtureOddsResponseModel(
      fixtureId: parsedFixtureId,
      bookmakers: bookmakersList,
    );
  }

  // Método para converter para uma lista de entidades PrognosticMarket (geralmente do bookmaker preferido)
  List<PrognosticMarket> toEntityList({int? preferredBookmakerId}) {
    if (bookmakers.isEmpty) return [];

    BookmakerOddsModel? selectedBookmaker;
    if (preferredBookmakerId != null) {
      selectedBookmaker = bookmakers.firstWhere(
        (b) => b.id == preferredBookmakerId,
        orElse:
            () =>
                bookmakers
                    .first, // Fallback para o primeiro bookmaker se o preferido não for encontrado
      );
    } else {
      selectedBookmaker =
          bookmakers
              .first; // Pega o primeiro se nenhum preferido for especificado
    }

    return selectedBookmaker.bets
        .map((marketModel) => marketModel.toEntity())
        .toList();
  }

  @override
  List<Object?> get props => [fixtureId, bookmakers];
}
