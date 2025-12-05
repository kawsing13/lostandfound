import 'dart:convert';

List<Endpoints> endpointsFromJson(String str) =>
    List<Endpoints>.from(json.decode(str).map((x) => Endpoints.fromJson(x)));

String filesToJson(List<Endpoints> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Endpoints {
  int id;
  String? name;
  String? url;
  String? endpoint;

  Endpoints({
    required this.id,
    this.name,
    this.url,
    this.endpoint,
  });

  factory Endpoints.fromJson(Map<String, dynamic> json) => Endpoints(
      id: json["id"],
      name: json["name"],
      url: json["url"],
      endpoint: json["endpoint"]
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "url": url,
    "endpoint": endpoint
  };
}

