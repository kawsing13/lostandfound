import 'dart:io';

import 'package:lostandfound/src/providers/db_provider.dart';
import 'package:lostandfound/src/models/endpoints.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class QCgiAPIProvider {
  Future<bool> uploadFile(String? tph, String? docNo, String? imageFile,
      String latiTude, String? longiTude) async {
    print("${tph}---xxxx---");

    /* get default selected endpoint */
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int _selectedEndpoint = prefs.getInt("endpoint") ?? 1;
    prefs.setString("documentType", tph ?? "");

    List<Endpoints> _endpoint =
        await DBProvider.db.getEndpoint(_selectedEndpoint);
    String url = "https://jonathan.edu.ph/app/";
    String cf = "api.cf";

    String urlcf = "${url}/${cf}";

    print("uploadFile ${url}/${cf} - ${imageFile.toString()}");

    var request = await http.MultipartRequest('POST', Uri.parse(urlcf));

    request.fields['tpl'] = tph ?? "lsf";
    request.fields['doc_id'] = docNo ?? "";
    request.fields['latitude'] = latiTude ?? "";
    request.fields['longitude'] = longiTude ?? "";

    request.files.add(http.MultipartFile.fromBytes(
        'file', File(imageFile ?? "").readAsBytesSync(),
        filename: "${docNo}.jpg"));

    var response = await request.send();

    print("Status >>>");
    print(response.statusCode);

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  }
}
