import 'dart:async';


import 'package:flutter/material.dart';

import 'package:lostandfound/src/models/endpoints.dart';

import 'package:lostandfound/src/providers/db_provider.dart';

import 'package:lostandfound/util/routes.dart';


class newEndpointScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _newEndpointScreenState();
  }
}

class _newEndpointScreenState extends State<newEndpointScreen> {

  ScreenArguments? args;
  final Endpoints Endpoint = new Endpoints(id: 0, name:'', url: '', endpoint: '' ) ;
  bool newEndpointFlag=true;

  final endpointName = TextEditingController();
  final endpointURL = TextEditingController();
  final endpointEndpoint = TextEditingController();

  Future<void> initDB() async {

      if (args!.id == 0) {
        Endpoint.id = await DBProvider.db.getEndpointId();
        Endpoint.name = '';
        Endpoint.url = '';
        Endpoint.endpoint = '';
      }
      else {
        List<Endpoints> _getEndpoint = await DBProvider.db.getEndpoint(args!.id);
        
        if (_getEndpoint.isNotEmpty) {
          Endpoint.id = _getEndpoint[0].id;
          Endpoint.name = _getEndpoint[0].name;
          endpointName.text=Endpoint.name ?? "";
          Endpoint.url = _getEndpoint[0].url;
          endpointURL.text = Endpoint.url  ?? "";
          Endpoint.endpoint = _getEndpoint[0].endpoint;
          endpointEndpoint.text = Endpoint.endpoint  ?? "";
          
        }
        newEndpointFlag=false;
      }
      setState(() {});
  }

    @override
  void initState() {
    super.initState();

    Endpoint.id = -1;
    print(Endpoint.id);
  }

 Future<Null> saveEndpoint() async {

   Endpoint.name = endpointName.text;
   Endpoint.endpoint = endpointEndpoint.text;
   Endpoint.url = endpointURL.text;

   print(Endpoint.toJson());



   if (Endpoint.url!.isEmpty || Endpoint.name!.isEmpty || Endpoint.endpoint!.isEmpty ) return;


    if (newEndpointFlag) {
      if (Endpoint.id==-1) { Endpoint.id=0; }
      Endpoint.id++;

      await DBProvider.db.saveEndpoint(Endpoint);
    } else {
      await DBProvider.db.updateEndpoint(Endpoint);
    }


   Navigator.pushNamedAndRemoveUntil(context, "/Endpoints", ModalRoute.withName('/'));

  }


  @override
  Widget build(BuildContext context) {

    this.args = ModalRoute.of(context)!.settings.arguments as ScreenArguments;
    if (Endpoint.id==-1 && args!=null ) { initDB(); }

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
          title: newEndpointFlag?Text("New Endpoint"):Text("Edit Endpoint"),
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
              onPressed: saveEndpoint,
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
                            controller: endpointName,
                            onChanged: (String? value){ print("Data"); Endpoint.name=value;},
                           // keyboardType: TextInputType.phone,
                           // inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              counterText: "",
                              labelText: "Endpoint Name",
                              floatingLabelBehavior: FloatingLabelBehavior.auto,
                              hintText: "Endpoint Name",
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
                            controller: endpointURL,
                            onChanged: (String? value){Endpoint.url=value;},
                            // keyboardType: TextInputType.phone,
                            // inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                                counterText: "",
                                labelText: "URL",
                                floatingLabelBehavior: FloatingLabelBehavior.auto,
                                hintText: "URL",
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
                    Padding(
                        padding: EdgeInsets.only(top: 10.0),
                        child: TextFormField(
                            controller: endpointEndpoint,
                            onChanged:  (String? value){Endpoint.endpoint=value;},
                            // keyboardType: TextInputType.phone,
                            // inputFormatters: [WhitelistingTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                                counterText: "",
                                labelText: "Endpoint",
                                floatingLabelBehavior: FloatingLabelBehavior.auto,
                                hintText: "Endpoint",
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


