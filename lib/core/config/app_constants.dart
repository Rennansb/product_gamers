// lib/core/config/app_constants.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String rapidApiKey =
      dotenv.env['RAPIDAPI_KEY'] ?? 'ERRO_KEY_NAO_CONFIGURADA';
  static String rapidApiHost =
      dotenv.env['RAPIDAPI_HOST'] ?? 'api-football-v1.p.rapidapi.com';
  static String baseUrl = 'https://$rapidApiHost';

  // IDs de algumas ligas populares para exemplo (você pode buscar todas ou permitir seleção)
  // Fonte: Documentação da API-Football ou chamando o endpoint /leagues
  static const Map<String, int> popularLeagues = {
    'Premier League (ING)': 39,
    'La Liga (ESP)': 140,
    'Serie A (ITA)': 135,
    'Bundesliga (ALE)': 78,
    'Ligue 1 (FRA)': 61,
    'Brasileirão Série A (BRA)': 71,
    'Champions League': 2,
    'Europa League': 3,
  };

  // IDs de alguns bookmakers (casas de apostas)
  // Verifique a documentação da API-Football para IDs corretos e disponibilidade regional/de mercado.
  // Ex: 8 = Bet365, 6 = Bwin, 1 = 1xBet.
  // É importante notar que a disponibilidade de odds de um bookmaker específico pode variar por jogo/liga.
  static const int preferredBookmakerId = 8; // Ex: Bet365
  // Você pode querer permitir que o usuário selecione ou ter uma lista de fallback.
}
