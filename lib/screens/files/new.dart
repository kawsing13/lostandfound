import 'dart:async';


import 'package:flutter/material.dart';

import 'package:lostandfound/src/models/files.dart';

import 'package:lostandfound/src/providers/db_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


import 'package:lostandfound/util/routes.dart';


class newFilesScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _newFilesScreenState();
  }
}

class _newFilesScreenState extends State<newFilesScreen> {

  ScreenArguments? args;
  final Files files = new Files(id: 0, endpoint: 0, name:'', type: '' ) ;
  bool newFilesFlag=true;

  final filesName = TextEditingController();
  final filesType = TextEditingController();

  Future<void> initDB() async {

      if (args!.subID == 0) {
        files.id = await DBProvider.db.getFilesId(args!.subID);
        files.endpoint = args!.id;
        files.name = '';
        files.type = '';
      }
      else {
        List<Files> _getFiles = await DBProvider.db.getFile(args!.subID);
        
        if (_getFiles.isNotEmpty) {
          files.id = _getFiles[0].id;
          files.endpoint = _getFiles[0].endpoint;
          files.name = _getFiles[0].name;
          filesName.text=files.name ?? "";
          files.type = _getFiles[0].type;
          filesType.text = files.type  ?? "";
          
        }
        newFilesFlag=false;
      }
      setState(() {});
  }

    @override
  void initState() {
    super.initState();

    files.id = -1;
    print(files.id);
  }

 Future<Null> saveFiles() async {

   files.name = filesName.text;
   files.type = filesType.text;

   print(files.toJson());

   if (files.type!.isEmpty || files.name!.isEmpty ) return;

    if (newFilesFlag) {
      if (files.id==-1) { files.id=0; }
      files.id++;

      await DBProvider.db.saveFile(files);
    } else {
      await DBProvider.db.updateFile(files);
    }

   SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('documentType');

   Navigator.pop(context);

  }


  @override
  Widget build(BuildContext context) {

    this.args = ModalRoute.of(context)!.settings.arguments as ScreenArguments;
    if (files.id==-1 && args!=null ) { initDB(); }

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
          title: newFilesFlag?Text("New Files"):Text("Edit Files"),
          actions: <Widget>[
            TextButton(
              //style: style,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, textStyle: const TextStyle(fontSize: 20),
              ),
              onPressed: () { },
              child: Text(""), // placeholder for total sales
            ),
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Save',
              onPressed: saveFiles,
            ),
          ]
      ),
      body: SingleChildScrollView(
          child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                children: <Widget>[

                    Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: TextFormField(
                            controller: filesName,
                            onChanged: (String? value){ print("Data"); files.name=value;},
                           // keyboardType: TextInputType.phone,
                           // inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              counterText: "",
                              labelText: "File Description",
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              hintText: "File Description",
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Colors.grey,
                                  width: 0.3,
                                ),
                              ))

                        ),
                    ),

                    Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: TextFormField(
                            controller: filesType,
                            onChanged: (String? value){files.type=value;},
                            // keyboardType: TextInputType.phone,
                            // inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                                counterText: "",
                                labelText: "File Name",
                                floatingLabelBehavior: FloatingLabelBehavior.auto,
                                hintText: "File Name",
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey,
                                    width: 0.3,
                                  ),
                                ))

                          /* validator: (value) {
                                    if (value.isEmpty || value.length < 10) {
                                    return 'Please Enter 10 digit number';
                              }*/
                        ),
                    ),

                ]
              ),
          )
      )
    );
  }
}


