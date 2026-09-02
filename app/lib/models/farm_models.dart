/// Farm memory and summary models matching API_CONTRACT §5 and DESIGN.md C2.

class GeoPoint {
  final double lat;
  final double lng;

  const GeoPoint({required this.lat, required this.lng});

  factory GeoPoint.fromJson(Map<String, dynamic> json) {
    return GeoPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
      };
}

class FarmModel {
  final String id;
  final String? farmerId;
  final String crop; // paddy
  final String? variety;
  final String growthStage; // nursery | tillering | vegetative | booting | flowering | maturity
  final String region;
  final GeoPoint? location;
  final String? createdAt;

  const FarmModel({
    required this.id,
    this.farmerId,
    required this.crop,
    this.variety,
    required this.growthStage,
    required this.region,
    this.location,
    this.createdAt,
  });

  factory FarmModel.fromJson(Map<String, dynamic> json) {
    return FarmModel(
      id: json['id'] as String,
      farmerId: json['farmer_id'] as String?,
      crop: json['crop'] as String? ?? 'paddy',
      variety: json['variety'] as String?,
      growthStage: json['growth_stage'] as String? ?? 'tillering',
      region: json['region'] as String,
      location: json['location'] != null
          ? GeoPoint.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        if (farmerId != null) 'farmer_id': farmerId,
        'crop': crop,
        if (variety != null) 'variety': variety,
        'growth_stage': growthStage,
        'region': region,
        if (location != null) 'location': location!.toJson(),
        if (createdAt != null) 'created_at': createdAt,
      };
}

class HealthModel {
  final String sentence;
  final String trend; // improving | worsening | stable

  const HealthModel({
    required this.sentence,
    required this.trend,
  });

  factory HealthModel.fromJson(Map<String, dynamic> json) {
    return HealthModel(
      sentence: json['sentence'] as String,
      trend: json['trend'] as String? ?? 'stable',
    );
  }

  Map<String, dynamic> toJson() => {
        'sentence': sentence,
        'trend': trend,
      };
}

class FarmSummaryModel {
  final FarmModel farm;
  final HealthModel health;
  final int openProblems;
  final int pendingFollowups;
  final int activeAlerts;
  final String? spokenSummary;

  int get activeProblemsCount => openProblems;
  int get pendingFollowUpsCount => pendingFollowups;
  int get activeAlertsCount => activeAlerts;

  const FarmSummaryModel({
    required this.farm,
    required this.health,
    int? openProblems,
    int? activeProblemsCount,
    int? pendingFollowups,
    int? pendingFollowUpsCount,
    int? activeAlerts,
    int? activeAlertsCount,
    this.spokenSummary,
  })  : openProblems = openProblems ?? activeProblemsCount ?? 0,
        pendingFollowups = pendingFollowups ?? pendingFollowUpsCount ?? 0,
        activeAlerts = activeAlerts ?? activeAlertsCount ?? 0;

  factory FarmSummaryModel.fromJson(Map<String, dynamic> json) {
    return FarmSummaryModel(
      farm: FarmModel.fromJson(json['farm'] as Map<String, dynamic>),
      health: HealthModel.fromJson(json['health'] as Map<String, dynamic>),
      openProblems: json['open_problems'] as int? ?? 0,
      pendingFollowups: json['pending_followups'] as int? ?? 0,
      activeAlerts: json['active_alerts'] as int? ?? 0,
      spokenSummary: json['spoken_summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'farm': farm.toJson(),
        'health': health.toJson(),
        'open_problems': openProblems,
        'pending_followups': pendingFollowups,
        'active_alerts': activeAlerts,
        if (spokenSummary != null) 'spoken_summary': spokenSummary,
      };
}
