import 'dart:async';



import 'package:flutter/material.dart';


import 'package:lostandfound/src/models/files.dart';
import 'package:lostandfound/src/providers/db_provider.dart';
import 'package:lostandfound/util/routes.dart';

import 'package:flutter_slidable/flutter_slidable.dart';


class endpointFilesScreen extends StatefulWidget {
  late int endpointID =0 ;

  endpointFilesScreen({Key? key, required this.endpointID}) ;

  @override
  State<StatefulWidget> createState() {
    return _endpointFilesScreenState(endpointID: endpointID);
  }

}

class _endpointFilesScreenState extends State<endpointFilesScreen> {
  int endpointID = 0;

  _endpointFilesScreenState({required this.endpointID});
  List<Files> endpointFiles = [];

  Future<void> initDB() async {

    print("loading data");
    List<Files> listC = await DBProvider.db.getAllFiles(endpointID);
    if (listC.isNotEmpty ) {
      endpointFiles=listC;
    }

    setState(() {    });

  }


  @override
  void initState() {
    super.initState();
    initDB();
  }


    Future<void>removeEndpointFiles(int seq)  async{

    // print(seq);
    //delete action for this button
    //DBProvider.db.deleteEndpoint(seq,endpointID);
    endpointFiles.removeWhere((element){
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
          title: Text("File Types")
         /* endpointing: IconButton(
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
                  children: endpointFiles.map((_files){
                    return Slidable(
                      child: Card(
                        color: Colors.white,
                        child:ListTile(
                          title: _files.name == null ?  Text("") : Text("${_files.name}"),
                          subtitle: _files.type == null ? Text(""): Text("${_files.type}" ),
                          onTap: (){ Navigator.pushNamed((context), '/newEndpointFile', arguments: ScreenArguments(endpointID, _files.id)).then( (value)=>setState((){}) ); },
                        ),
                      ),
                      endActionPane: ActionPane(
                        motion: const ScrollMotion(),
                        extentRatio: 0.15,
                        // dismissible: DismissiblePane(onDismissed: () {}),
                        children: [
                          SlidableAction(
                            // An action can be bigger than the others.
                            //flex: 2,
                            onPressed: (context)=>{ removeEndpointFiles(_files.id) },
                            backgroundColor: Color(0xFFFE4A49),
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
              onPressed: (){ Navigator.pushNamed((context), '/newEndpointFile', arguments: ScreenArguments(endpointID, 0 )).then( (value)=>setState((){}) ); },
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


