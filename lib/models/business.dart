class Business {
  String? id;
  String? orgName;

  Business({
    required this.id,
    required this.orgName,
  });

  Business copyWith({
    String? id,
    String? orgName,
  }) =>
      Business(
        id: id ?? this.id,
        orgName: orgName ?? this.orgName,
      );

  factory Business.fromJson(Map<String, dynamic> json) => Business(
        id: json['id'],
        orgName: json['OrgName'],
      );
}
