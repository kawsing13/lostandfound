import 'package:lostandfound/screens/files/new.dart';
import 'package:flutter/material.dart';
import 'package:lostandfound/screens/endpoints/list.dart';
import 'package:lostandfound/screens/endpoints/new.dart';

class Routes {
  static final routes = <String, WidgetBuilder>{
    "/Endpoints" : ( BuildContext context ) => EndpointsScreen(),
    "/newEndpoint" : ( BuildContext context ) => newEndpointScreen(),
    "/newEndpointFile": ( BuildContext context ) => newFilesScreen(),
//    "/productDetail": (BuildContext context) =>
    //Constants.ROUTE_PRODUCT_DETAIL: (BuildContext context) =>  ,

 //    Constants.ROUTE_SETTINGS_SCREEN: ( BuildContext context ) => SettingsScreen(),

  };
}


class ScreenArguments {
  final int id;
  final int subID;

  ScreenArguments(this.id,this.subID);
}