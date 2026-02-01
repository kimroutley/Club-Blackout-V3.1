class HallOfFameProfile {
  final String id;
  final String name;
  final int totalGames;
  final int totalWins;

  /// Games facilitated as Host (not a gameplay role).
  final int totalHostedGames;

  /// When hosting, how often each faction won.
  final int hostedDealerWins;
  final int hostedPartyWins;
  final int hostedOtherWins;
  // Breakdown of roles played (Role Name -> Count)
  final Map<String, int> roleStats;
  // Breakdown of "Shenanigan Awards" won (Award Title -> Count)
  final Map<String, int> awardStats;
  final DateTime lastPlayed;

  HallOfFameProfile({
    required this.id,
    required this.name,
    this.totalGames = 0,
    this.totalWins = 0,
    this.totalHostedGames = 0,
    this.hostedDealerWins = 0,
    this.hostedPartyWins = 0,
    this.hostedOtherWins = 0,
    Map<String, int>? roleStats,
    Map<String, int>? awardStats,
    DateTime? lastPlayed,
  })  : roleStats = roleStats ?? {},
        awardStats = awardStats ?? {},
        lastPlayed = lastPlayed ?? DateTime.now();

  double get winRate => totalGames == 0 ? 0.0 : totalWins / totalGames;

  double get dealerWinRateWhileHosting =>
      totalHostedGames == 0 ? 0.0 : hostedDealerWins / totalHostedGames;

  factory HallOfFameProfile.fromJson(Map<String, dynamic> json) {
    return HallOfFameProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      totalGames: (json['totalGames'] as num?)?.toInt() ?? 0,
      totalWins: (json['totalWins'] as num?)?.toInt() ?? 0,
      totalHostedGames: (json['totalHostedGames'] as num?)?.toInt() ?? 0,
      hostedDealerWins: (json['hostedDealerWins'] as num?)?.toInt() ?? 0,
      hostedPartyWins: (json['hostedPartyWins'] as num?)?.toInt() ?? 0,
      hostedOtherWins: (json['hostedOtherWins'] as num?)?.toInt() ?? 0,
      roleStats: (json['roleStats'] as Map?)?.cast<String, int>() ?? {},
      awardStats: (json['awardStats'] as Map?)?.cast<String, int>() ?? {},
      lastPlayed: DateTime.tryParse(json['lastPlayed'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'totalGames': totalGames,
        'totalWins': totalWins,
      'totalHostedGames': totalHostedGames,
      'hostedDealerWins': hostedDealerWins,
      'hostedPartyWins': hostedPartyWins,
      'hostedOtherWins': hostedOtherWins,
        'roleStats': roleStats,
        'awardStats': awardStats,
        'lastPlayed': lastPlayed.toIso8601String(),
      };

  HallOfFameProfile copyWith({
    String? name,
    int? totalGames,
    int? totalWins,
    int? totalHostedGames,
    int? hostedDealerWins,
    int? hostedPartyWins,
    int? hostedOtherWins,
    Map<String, int>? roleStats,
    Map<String, int>? awardStats,
    DateTime? lastPlayed,
  }) {
    return HallOfFameProfile(
      id: id,
      name: name ?? this.name,
      totalGames: totalGames ?? this.totalGames,
      totalWins: totalWins ?? this.totalWins,
      totalHostedGames: totalHostedGames ?? this.totalHostedGames,
      hostedDealerWins: hostedDealerWins ?? this.hostedDealerWins,
      hostedPartyWins: hostedPartyWins ?? this.hostedPartyWins,
      hostedOtherWins: hostedOtherWins ?? this.hostedOtherWins,
      roleStats: roleStats ?? this.roleStats,
      awardStats: awardStats ?? this.awardStats,
      lastPlayed: lastPlayed ?? this.lastPlayed,
    );
  }
}
