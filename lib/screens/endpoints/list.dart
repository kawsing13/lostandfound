import 'dart:async';


import 'package:flutter/material.dart';

import 'package:lostandfound/src/models/endpoints.dart';
import 'package:lostandfound/src/providers/db_provider.dart';
import 'package:lostandfound/util/routes.dart';

import 'package:lostandfound/screens/files/list.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:shared_preferences/shared_preferences.dart';



class EndpointsScreen extends StatefulWidget {
  const EndpointsScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _EndpointsScreenState();
  }

}

class _EndpointsScreenState extends State<EndpointsScreen> {

  List<Endpoints> endpoints = [];
  List<Endpoints> filteredEndpoints = [];

  Icon customIcon = const Icon(Icons.search);
  Widget customSearchBar = const Text('Endpoints');

  int _selectedEndpoint = 0;


  Future<void> initDB() async {

    print("loading data");
    List<Endpoints> listC = await DBProvider.db.getAllEndpoints();
    if (listC.isNotEmpty ) {
      endpoints=listC;
      filteredEndpoints = endpoints;
    }

  /*  int _endpoint_id = await DBProvider.db.getEndpointId();
    _endpoint_id++; */

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _selectedEndpoint = prefs.getInt("endpoint") ?? 1;

    setState(() {    });

  }

  Future<void> setSelectedEndpoint(int endpoint) async {

    SharedPreferences prefs = await SharedPreferences.getInstance();
    _selectedEndpoint = endpoint;
    prefs.setInt("endpoint", endpoint);
    setState(() {    });

  }

  @override
  void initState() {
    super.initState();
    initDB();
  }

     Future<void>removeEndpoints(int seq)  async{

    // print(seq);
    //delete action for this button
    DBProvider.db.deleteEndpoint(seq);
    filteredEndpoints.removeWhere((element){
      return element.id == seq;
    });  //go through the loop and match content to delete from list
    setState(() {
      //refresh UI after deleting element from list
    });


  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.



    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
          title: Text("Endpoints"),
          /* leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, "/sales", (route) => false),
          ),
          automaticallyImplyendpointing: false, */


      ),
      body: RefreshIndicator( //SingleChildScrollView(
          onRefresh: () async {
            print("Refreshing");
            initDB();
            await Future.delayed(Duration(seconds: 1));
            },
            child: SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              child: Container(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: filteredEndpoints.map((_endpoint){
                    return Slidable(
                      child: Card(
                        color: _selectedEndpoint == _endpoint.id?Colors.greenAccent:Colors.white,
                        child:ListTile(
                            title: _endpoint.name == null ?  Text("") : Text("${_endpoint.name}") ,
                            subtitle: _endpoint.url == null ? Text(""): Text("${_endpoint.url}" ),
                            onTap: (){ Navigator.of(context).push(MaterialPageRoute(builder: (context) =>   endpointFilesScreen(endpointID:_endpoint.id)));  },
                            onLongPress: () { setSelectedEndpoint(_endpoint.id); }
                        ),
                      ),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.3,
                        // dismissible: DismissiblePane(onDismissed: () {}),
                        children: [
                          SlidableAction(
                            // An action can be bigger than the others.
                            //flex: 2,
                            onPressed: (context)=>{ Navigator.pushNamed((context), '/newEndpoint', arguments: ScreenArguments(_endpoint.id,0)) },
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            icon: Icons.edit,
                            label: 'Edit',
                          ),
                          SlidableAction(
                            // An action can be bigger than the others.
                            //flex: 2,
                            onPressed: (context)=>{ removeEndpoints(_endpoint.id) },
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            icon: Icons.delete,
                            label: 'Delete',
                          ),

                        ],
                      ),
                    );
                  }).toList(),
                ),
                height: MediaQuery.of(context).size.height,
              )
            )
      ),
      floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              child: Icon(
                  Icons.add
              ),
              onPressed: (){ Navigator.pushNamed((context), '/newEndpoint', arguments: ScreenArguments(0,0)); },
              heroTag: null,
            ),
            SizedBox(
              height: 10,
            ),
          ]
      ),
     // drawer: NavBar()
    );
  }
}


