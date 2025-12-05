import 'dart:async';


import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

//import 'package:optiq/util/routes.dart';

//import '../../NavBar.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SettingsScreenState();
  }

}

class _SettingsScreenState extends State<SettingsScreen> {

  final myController = TextEditingController();

  @override
  void initState() {
    super.initState();
    getSharedPrefs();

  }

  Future<Null> getSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? _tag = prefs.getString("Tag");
    setState(() {
      myController.text=_tag ?? "";
    });
  }

  Future<Null> savedSharedPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? _tag = myController.text ?? "";
    prefs.setString("Tag", _tag);

  }


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    var formatter = NumberFormat('#,##,##0.00');

    final ButtonStyle raisedButtonStyle = ElevatedButton.styleFrom(
      foregroundColor: Colors.black87, backgroundColor: Colors.grey[300],
      minimumSize: Size(88, 36),
      padding: EdgeInsets.symmetric(horizontal: 16),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(2)),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
          title: Text("Settings"),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          automaticallyImplyLeading: false,
          actions: <Widget>[
          /*  IconButton(
                icon: customIcon,
                tooltip: 'Search',
                onPressed: appBarSearch
            ),*/
          ]
      ),
      body: SingleChildScrollView(
          child: Container(
              padding: EdgeInsets.all(10),
              child: Column(
                children: <Widget>[
                    GestureDetector(
                    child: Container(
                      width: 300,
                      height: 300,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage('assets/images/optiq.png') ,
                                fit: BoxFit.contain,
                          ),
                        ),
                    ),
                    //onTap: (){ _showOptions(context); },
                  ),
                  Padding(
                      padding: EdgeInsets.only(top: 10.0),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                              Text("Optiq v1.4"),
                          ]
                    ),

                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, bottom: 8.0),
                    child: TextField(
                        controller: myController,
                        //controller: nameController,
                        onChanged: (v){ savedSharedPrefs(); },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Copper Tag',
                        )),
                  ),
                  /*ElevatedButton(
                    style: raisedButtonStyle,
                    onPressed: savedSharedPrefs,
                    child: Text('Save'),
                  )*/
              ]
            )
          )
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Sales',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_city),
            label: 'Field',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.hive),
            label: 'Operations',
          ),
        ],
        currentIndex: 0,
        selectedItemColor: Colors.amber[800],
        onTap: null, //_onItemTapped,
      ),

    );
  }
}


