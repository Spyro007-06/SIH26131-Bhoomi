/// Referral and helpline wire models matching API_CONTRACT §14.

typedef KvkModel = ReferralModel;
typedef DistrictLabModel = ReferralModel;

class ReferralModel {
  final String kind; // kvk | lab | helpline
  final String name;
  final String phone;
  final double? distanceKm;
  final bool acceptsSamples;
  final String? address;

  const ReferralModel({
    String? kind,
    required this.name,
    required this.phone,
    this.distanceKm,
    this.acceptsSamples = false,
    this.address,
  }) : kind = kind ?? 'kvk';

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    return ReferralModel(
      kind: json['kind'] as String? ?? 'kvk',
      name: json['name'] as String,
      phone: json['phone'] as String,
      distanceKm: (json['distance_km'] as num?)?.toDouble(),
      acceptsSamples: json['accepts_samples'] as bool? ?? false,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'name': name,
        'phone': phone,
        if (distanceKm != null) 'distance_km': distanceKm,
        'accepts_samples': acceptsSamples,
        if (address != null) 'address': address,
      };
}

class ReferralsResponse {
  final List<ReferralModel> referrals;

  ReferralModel? get kvk => referrals.where((r) => r.kind == 'kvk').firstOrNull;
  List<ReferralModel> get districtLabs => referrals.where((r) => r.kind == 'lab').toList();
  String? get helpline => referrals.where((r) => r.kind == 'helpline').firstOrNull?.phone;

  ReferralsResponse({
    List<ReferralModel>? referrals,
    ReferralModel? kvk,
    List<ReferralModel>? districtLabs,
    String? helpline,
  }) : referrals = referrals ?? [
          if (kvk != null)
            ReferralModel(
              kind: 'kvk',
              name: kvk.name,
              phone: kvk.phone,
              distanceKm: kvk.distanceKm,
              acceptsSamples: kvk.acceptsSamples,
              address: kvk.address,
            ),
          if (districtLabs != null)
            ...districtLabs.map((lab) => ReferralModel(
                  kind: 'lab',
                  name: lab.name,
                  phone: lab.phone,
                  distanceKm: lab.distanceKm,
                  acceptsSamples: lab.acceptsSamples,
                  address: lab.address,
                )),
          if (helpline != null)
            ReferralModel(kind: 'helpline', name: 'Kisan Call Center', phone: helpline),
        ];

  factory ReferralsResponse.fromJson(Map<String, dynamic> json) {
    final list = (json['referrals'] as List<dynamic>?)
            ?.map((e) => ReferralModel.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return ReferralsResponse(referrals: list);
  }

  Map<String, dynamic> toJson() => {
        'referrals': referrals.map((e) => e.toJson()).toList(),
      };
}
