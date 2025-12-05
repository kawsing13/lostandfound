import 'dart:convert';

List<Files> filesFromJson(String str) =>
    List<Files>.from(json.decode(str).map((x) => Files.fromJson(x)));

String filesToJson(List<Files> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Files {
  int id;
  int endpoint;
  String? name;
  String? type;


  Files({
    required this.id,
    required this.endpoint,
    this.name,
    this.type
  });

  factory Files.fromJson(Map<String, dynamic> json) => Files(
      id: json["id"],
      endpoint: json["endpoint"],
      name: json["name"],
      type: json["type"],

  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "endpoint": endpoint,
    "name": name,
    "type": type

  };
}

