// lib/data/models/fixture_lineups_response_model.dart
import 'package:equatable/equatable.dart';
import 'package:product_gamers/domain/entities/entities/lineup.dart';
import 'team_lineup_model.dart';
// A entidade LineupsForFixture será o resultado da conversão

class FixtureLineupsResponseModel extends Equatable {
  // A API /fixtures/lineups retorna uma lista com 2 TeamLineupModel (home e away)
  final TeamLineupModel? homeTeamLineup;
  final TeamLineupModel? awayTeamLineup;

  const FixtureLineupsResponseModel({this.homeTeamLineup, this.awayTeamLineup});

  factory FixtureLineupsResponseModel.fromApiList(List<dynamic> jsonList,
      {required int homeTeamIdApi, required int awayTeamIdApi}) {
    TeamLineupModel? homeL, awayL;
    if (jsonList.length == 2) {
      final team1Json = jsonList[0] as Map<String, dynamic>?;
      final team2Json = jsonList[1] as Map<String, dynamic>?;

      if (team1Json != null && team2Json != null) {
        final team1Lineup = TeamLineupModel.fromJson(team1Json);
        final team2Lineup = TeamLineupModel.fromJson(team2Json);

        // Identificar pelo ID do time
        if (team1Lineup.team.id == homeTeamIdApi) {
          homeL = team1Lineup;
          awayL = (team2Lineup.team.id == awayTeamIdApi) ? team2Lineup : null;
        } else if (team1Lineup.team.id == awayTeamIdApi) {
          awayL = team1Lineup;
          homeL = (team2Lineup.team.id == homeTeamIdApi) ? team2Lineup : null;
        } else {
          // Fallback se IDs não baterem, assumir ordem (com cautela)
          homeL = team1Lineup; // Assume o primeiro como home
          awayL = team2Lineup; // Assume o segundo como away
        }
      }
    } else if (jsonList.length == 1) {
      // Caso raro de apenas uma lineup ser retornada
      final singleTeamJson = jsonList[0] as Map<String, dynamic>?;
      if (singleTeamJson != null) {
        final singleLineup = TeamLineupModel.fromJson(singleTeamJson);
        if (singleLineup.team.id == homeTeamIdApi)
          homeL = singleLineup;
        else if (singleLineup.team.id == awayTeamIdApi) awayL = singleLineup;
      }
    }
    return FixtureLineupsResponseModel(
        homeTeamLineup: homeL, awayTeamLineup: awayL);
  }

  LineupsForFixture toEntity() {
    return LineupsForFixture(
      homeTeamLineup: homeTeamLineup?.toEntity(),
      awayTeamLineup: awayTeamLineup?.toEntity(),
    );
  }

  @override
  List<Object?> get props => [homeTeamLineup, awayTeamLineup];
}
