/// Alerts and surveillance wire models matching API_CONTRACT §10.

class AlertModel {
  final String id;
  final String triggerType; // weather | seasonal | spread | combined
  final String target; // blast | brown_spot | bacterial_leaf_blight | yellow_stem_borer | brown_planthopper
  final String riskLevel; // high | medium | low
  final String reason;
  final List<String> inspectionTasks; // Invariant: non-empty list
  final String issuedAt;
  final String? outcome; // nothing_found | found | snoozed | null
  final String? spokenSummary;
  final String? farmId;

  String get createdAt => issuedAt;

  const AlertModel({
    required this.id,
    required this.triggerType,
    required this.target,
    required this.riskLevel,
    required this.reason,
    required this.inspectionTasks,
    String? issuedAt,
    String? createdAt,
    this.outcome,
    this.spokenSummary,
    this.farmId,
  }) : issuedAt = issuedAt ?? createdAt ?? '';

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    final tasksList = (json['inspection_tasks'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return AlertModel(
      id: json['id'] as String,
      triggerType: json['trigger_type'] as String,
      target: json['target'] as String,
      riskLevel: json['risk_level'] as String,
      reason: json['reason'] as String,
      inspectionTasks: tasksList,
      issuedAt: json['issued_at'] as String? ?? json['created_at'] as String? ?? '',
      outcome: json['outcome'] as String?,
      spokenSummary: json['spoken_summary'] as String?,
      farmId: json['farm_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'trigger_type': triggerType,
        'target': target,
        'risk_level': riskLevel,
        'reason': reason,
        'inspection_tasks': inspectionTasks,
        'issued_at': issuedAt,
        if (outcome != null) 'outcome': outcome,
        if (spokenSummary != null) 'spoken_summary': spokenSummary,
        if (farmId != null) 'farm_id': farmId,
      };
}

class AlertsResponse {
  final List<AlertModel> alerts;
  final String? nextCursor;
  int get count => alerts.length;

  const AlertsResponse({
    required this.alerts,
    this.nextCursor,
    int? count,
  });

  factory AlertsResponse.fromJson(Map<String, dynamic> json) {
    final alertsList = (json['alerts'] as List<dynamic>?)
            ?.map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];

    return AlertsResponse(
      alerts: alertsList,
      nextCursor: json['next_cursor'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'alerts': alerts.map((e) => e.toJson()).toList(),
        if (nextCursor != null) 'next_cursor': nextCursor,
      };
}

class AlertRespondResponse {
  final String alertId;
  final String outcome; // nothing_found | found | snoozed
  final bool? diagnoseSuggested;
  final String? recordedAt;

  String get status => outcome;

  const AlertRespondResponse({
    required this.alertId,
    String? outcome,
    String? status,
    this.diagnoseSuggested,
    this.recordedAt,
  }) : outcome = outcome ?? status ?? 'recorded';

  factory AlertRespondResponse.fromJson(Map<String, dynamic> json) {
    return AlertRespondResponse(
      alertId: json['alert_id'] as String,
      outcome: json['outcome'] as String? ?? json['status'] as String? ?? 'recorded',
      diagnoseSuggested: json['diagnose_suggested'] as bool?,
      recordedAt: json['recorded_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'alert_id': alertId,
        'outcome': outcome,
        if (diagnoseSuggested != null) 'diagnose_suggested': diagnoseSuggested,
        if (recordedAt != null) 'recorded_at': recordedAt,
      };
}
