import 'dart:developer';
import 'dart:io';

import 'package:flutter_image_gallery_saver/flutter_image_gallery_saver.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lostandfound/src/providers/api_provider.dart';
import 'package:lostandfound/src/providers/db_provider.dart';
import 'package:lostandfound/src/models/files.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rflutter_alert/rflutter_alert.dart';
import 'package:image/image.dart' as img;


import '../main.dart';

import 'package:lostandfound/util/constants.dart';


import 'package:image_cropper/image_cropper.dart';


class CameraScreen extends StatefulWidget {
  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? controller;
  GlobalKey _globalKey = GlobalKey();

  var _imageFile;
  // Initial values
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  bool _isRearCameraSelected = true;
  double _minAvailableExposureOffset = 0.0;
  double _maxAvailableExposureOffset = 0.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  double _currentScale = 1.0;
  double _baseScale = 1.0;
  int _pointers = 0;

  // Current values
  double _currentZoomLevel = 1.0;
  double _currentExposureOffset = 0.0;
  FlashMode? _currentFlashMode;

  List<File> allFileList = [];

  String _selectedDocType = "";

  File? _image;

  final resolutionPresets = ResolutionPreset.values;

  String latitude = "";
  String longitude = "";

  ResolutionPreset currentResolutionPreset = ResolutionPreset.high;

  getPermissionStatus() async {
    await Permission.camera.request();
    var status = await Permission.camera.status;

    if (status.isGranted) {
      log('Camera Permission: GRANTED');
      setState(() {
        _isCameraPermissionGranted = true;
      });
      // Set and initialize the new camera
      onNewCameraSelected(cameras[0]);
     // refreshAlreadyCapturedImages();
    } else {
      log('Camera Permission: DENIED');
    }
  }
  getLocationPermission()async{
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    // Check for permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => log('Location permission denied'));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() => log('Location permission permanently denied'));
      return;
    }
    // Get location
    Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    // Convert to address
    List<Placemark> placemarks =
    await placemarkFromCoordinates(pos.latitude, pos.longitude);

    Placemark place = placemarks.first;

    setState(() {
      //print('Lat: ${pos.latitude}, Lng: ${pos.longitude}\n${place.locality}, ${place.country} ,Address: ${placemarks}');
      latitude = pos.latitude.toString();
      longitude = pos.longitude.toString();
    });


  }

  refreshAlreadyCapturedImages() async {
    final directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> fileList = await directory.list().toList();
    allFileList.clear();
    List<Map<int, dynamic>> fileNames = [];

    fileList.forEach((file) {
      if (file.path.contains('.jpg')) {
        allFileList.add(File(file.path));

        String name = file.path.split('/').last.split('.').first;
        fileNames.add({0: int.parse(name), 1: file.path.split('/').last});
      }
    });

    if (fileNames.isNotEmpty) {
      final recentFile =
          fileNames.reduce((curr, next) => curr[0] > next[0] ? curr : next);
      String recentFileName = recentFile[1];
      _imageFile = File('${directory.path}/$recentFileName');

      setState(() {});
    }
  }

  _saveLocalImage(String? imagePath) async {
    await _checkPermission();

    if (imagePath == null) {
      print('Error: Image path is null');
      return;
    }

    File imageFile = File(imagePath);

    if (!await imageFile.exists()) {
      print('Error: File does not exist at the path: $imagePath');
      return;
    }

    try {
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) {
        print('Error: Failed to decode image');
        return;
      }

      Uint8List pngBytes = Uint8List.fromList(img.encodePng(image));

      final directory = await getExternalStorageDirectory();
      //final customFolder = Directory('${directory!.path}/gecko');
      final customFolder = Directory('/storage/emulated/0/Pictures/MyApp/images/');


      if (!await customFolder.exists()) {
        await customFolder.create(recursive: true);
      }

      final filePath = '${customFolder.path}/saved_image.png';
      print('FilePath: ${filePath}');
      final file = File(filePath);

      await file.writeAsBytes(pngBytes);

      //final result = await ImageGallerySaver.saveFile(filePath);
      final result = await FlutterImageGallerySaver.saveFile(filePath);

      /*if (result != null && result['isSuccess'] == true) {
        print(customFolder);
        print('Image saved successfully in custom folder: $filePath');
      } else {
        print('Error saving image: $result');
      }

       */
    } catch (e) {
      print('Exception occurred while saving image: $e');
    }
  }

  Future<void> _checkPermission() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
  }

  Future _pickFromGallery() async {

    print('pick Image');
    final returnedImage = await ImagePicker().pickImage(source: ImageSource.gallery);
    setState(() {

      CropandUpload(returnedImage?.path.toString());
    });

  }

  Future<String?> takePicture() async {
    final CameraController? cameraController = controller;
    final deviceOrientation = MediaQuery.of(context).orientation;

    print(deviceOrientation);
    //cameraController!.lockCaptureOrientation(deviceOrientation);

    if (cameraController!.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();

      File imageFile =  File(file.path);

      int currentUnix = DateTime.now()
          .millisecondsSinceEpoch;

      final directory =
      await getApplicationDocumentsDirectory();

      String fileFormat = imageFile.path
          .split('.')
          .last;

      //print(fileFormat);

      await imageFile.copy(
        '${directory.path}/$currentUnix.$fileFormat',
      );

      return '${directory.path}/$currentUnix.$fileFormat';

    } on CameraException catch (e) {
      print('Error occured while taking picture: $e');
      return null;
    }
  }

  void resetCameraValues() async {
    _currentZoomLevel = 1.0;
    _currentExposureOffset = 0.0;
  }

  void onNewCameraSelected(CameraDescription cameraDescription) async {
    final previousCameraController = controller;

    final CameraController cameraController = CameraController(
      cameraDescription,
      currentResolutionPreset,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    await previousCameraController?.dispose();

    resetCameraValues();

    if (mounted) {
      setState(() {
        controller = cameraController;
      });
    }

    // Update UI if controller updated
    cameraController.addListener(() {
      if (mounted) setState(() {});
    });

    try {
      await cameraController.initialize();
      await Future.wait([
        cameraController
            .getMinExposureOffset()
            .then((value) => _minAvailableExposureOffset = value),
        cameraController
            .getMaxExposureOffset()
            .then((value) => _maxAvailableExposureOffset = value),
        cameraController
            .getMaxZoomLevel()
            .then((value) => _maxAvailableZoom = value),
        cameraController
            .getMinZoomLevel()
            .then((value) => _minAvailableZoom = value),
      ]);

      _currentFlashMode = controller!.value.flashMode;
    } on CameraException catch (e) {
      print('Error initializing camera: $e');
    }

    if (mounted) {
      setState(() {
        _isCameraInitialized = controller!.value.isInitialized;
      });
    }
  }

  void onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (controller == null) {
      return;
    }

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );
    controller!.setExposurePoint(offset);
    controller!.setFocusPoint(offset);

  }

  Future<void> initDB() async {

    print("loading data");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int _selectedEndpoint = prefs.getInt("endpoint") ?? 1;

    fileTypes = await DBProvider.db.getAllDistinctFiles(_selectedEndpoint);

    if (fileTypes.isEmpty) {
        fileTypes.add(new Files(id: 0, endpoint: _selectedEndpoint, name:'Lost and Found', type: 'lsf') );

    }

    _selectedDocType = prefs.getString("documentType") ?? fileTypes[0].type ?? "";
    


  }

  @override
  void initState() {
    // Hide the status bar in Android
    //SystemChrome.setEnabledSystemUIOverlays([]);
    getPermissionStatus();
    getLocationPermission();
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);


   initDB();

  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = controller;

    // App state changed before we got the chance to initialize.
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      onNewCameraSelected(cameraController.description);
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    controller?.dispose();
    super.dispose();
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    // When there are not exactly two fingers on screen don't scale
    if (controller == null || _pointers != 2) {
      return;
    }

    _currentScale = (_baseScale * details.scale)
        .clamp(_minAvailableZoom, _maxAvailableZoom);

    await controller!.setZoomLevel(_currentScale);
  }


  Future<void> _dialogBuilder(BuildContext context, String? imageFile) {
    String? documentType;
    final documentNo = TextEditingController();

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Form(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                         child: DropdownButtonFormField(
                            decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.grey,
                                    width: 0.3,
                                  ),
                                )
                            ),
                            dropdownColor: Colors.blueAccent,
                            value: _selectedDocType,
                            onChanged: (String? newValue) {
                                   documentType = newValue;
                            },
                            items: fileTypes.map( (user) =>  DropdownMenuItem<String>(
                              child: Text( (user.name ?? "")  ),
                              value: (user.type ?? ""),
                            )).toList()
                        ),

                      ),
                  Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: TextFormField(
                        controller: documentNo,
                      decoration: InputDecoration(
                          counterText: "",
                          labelText: "Item Name",
                          floatingLabelBehavior: FloatingLabelBehavior.auto,
                          hintText: "Item Name",
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.grey,
                              width: 0.3,
                            ),
                          )),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'This field is required';
                        }
                        return null;
                      },
                    ),
                  )

                ],
              )
          ),
          actions: [
            TextButton(
                onPressed: () { /*Navigator.of(context).pop();*/
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => CameraScreen() ));
                  } ,
                child: Text("Cancel")
            ),
            TextButton(
                onPressed: ()  async{
                  print(imageFile.toString());
                  print(documentType);
                  print(documentNo.text);
                  print('xxxxxxxxxxxxxxxxxxxxxxxxxx');

                  if (documentType == null ) {
                    documentType = _selectedDocType;
                  } else {
                    _selectedDocType = documentType ?? fileTypes[0].type ?? "";
                  }



                  if ( documentNo.text == "" || documentType! == "" ) return;
                  var apiProvider = QCgiAPIProvider();
                  bool res = await apiProvider.uploadFile(documentType, documentNo.text, imageFile,latitude,longitude);
                    if (res) {
                      print("Test Return ${res}");


                     await Alert(
                        context: context,
                        type: AlertType.success,
                        title: "",
                        desc: "File upload successful.",
                        closeFunction: () => /*Navigator.of(context).pop()*/ Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CameraScreen() )),
                        buttons: [
                          DialogButton(
                            child: Text(
                              "Ok",
                              style: TextStyle(color: Colors.white, fontSize: 20),
                            ),
                            onPressed: () => /*Navigator.of(context).pop()*/ Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => CameraScreen() )),
                            width: 120,
                          )
                        ],
                      ).show();

                      Navigator.of(context).pop();
                    } else {

                      Alert(
                        context: context,
                        type: AlertType.error,
                        title: "${documentNo.text}",
                        desc: "File upload failed.",
                        closeFunction: () => Navigator.of(context).pop(),
                        buttons: [
                          DialogButton(
                            child: Text(
                              "Ok",
                              style: TextStyle(color: Colors.white, fontSize: 20),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            width: 120,
                          )
                        ],
                      ).show();
                    }
                  } ,
                child: Text("Upload")
            ),

          ],
        );
      },
    );
  }

  CropandUpload(String? imageFile ) async{

    if (imageFile!.isEmpty) return;

    CroppedFile? croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile,

      uiSettings: [
        AndroidUiSettings(
            toolbarTitle: 'Cropper',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio3x2,
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPreset.ratio16x9
          ],
        ),

      ],
    );

    print("File Cropped");
    print("cropped ${croppedFile}");

    //pop-up screen for document type and
    if(croppedFile!=null) {
      getLocationPermission();
      _dialogBuilder(context, croppedFile.path.toString());
    }else{
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => CameraScreen() ));

    }

  }

  @override
  Widget build(BuildContext context) {
    final deviceOrientation = MediaQuery.of(context).orientation;
  //  print(deviceOrientation);
  //  print(1 / controller!.value.aspectRatio);
    return SafeArea(
      child: Scaffold(
        /*  appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
            title: Text (""),
            leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: ()  { Navigator.pop(context); }
            )
          ),

       */
        backgroundColor: Colors.black,


        body: _isCameraPermissionGranted
            ? _isCameraInitialized
                ? deviceOrientation == Orientation.portrait
                    ? Column(

                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AspectRatio(
                            aspectRatio: 1 / controller!.value.aspectRatio,
                            child: Stack(
                              children: [
                              Listener(
                                onPointerDown: (_) => _pointers++,
                                onPointerUp: (_) => _pointers--,
                                child: CameraPreview(
                                  controller!,
                                  child: LayoutBuilder(builder:
                                      (BuildContext context,
                                          BoxConstraints constraints) {
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTapDown: (details) =>
                                          onViewFinderTap(details, constraints),
                                      onScaleStart: _handleScaleStart,
                                      onScaleUpdate: _handleScaleUpdate,


                                    );
                                  }),
                                ),
                              ),
                                // TODO: Uncomment to preview the overlay
                                // Center(
                                //   child: Image.asset(
                                //     'assets/camera_aim.png',
                                //     color: Colors.greenAccent,
                                //     width: 150,
                                //     height: 150,
                                //   ),
                                // ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16.0,
                                    8.0,
                                    16.0,
                                    8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Container(
                                          margin:
                                          const EdgeInsets.only(top: 30),
                                          decoration: BoxDecoration(
                                            //color: Colors.grey[700],
                                            borderRadius:
                                            BorderRadius.circular(50.0),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              //Navigator.pushNamed(context, "/Endpoints").then( (res){ initDB(); } );
 
                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.black38,
                                                  size: 60,
                                                ),
                                                Icon(
                                                  Icons.settings,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Container(
                                          margin:
                                          const EdgeInsets.only(top: 10),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius:
                                            BorderRadius.circular(10.0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                              right: 8.0,
                                            ),
                                            child: DropdownButton<
                                                ResolutionPreset>(
                                              dropdownColor: Colors.black87,
                                              underline: Container(),
                                              value: currentResolutionPreset,
                                              items: [
                                                for (ResolutionPreset preset
                                                in resolutionPresets)
                                                  DropdownMenuItem(
                                                    child: Text(
                                                      preset
                                                          .toString()
                                                          .split('.')[1]
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    value: preset,
                                                  )
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  currentResolutionPreset =
                                                  value!;
                                                  _isCameraInitialized = false;
                                                });
                                                onNewCameraSelected(
                                                    controller!.description);
                                              },
                                              hint: Text("Select item"),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Spacer(),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 8.0, top: 16.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              _currentExposureOffset
                                                      .toStringAsFixed(1) +
                                                  'x',
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: RotatedBox(
                                          quarterTurns: 3,
                                          child: Container(
                                            height: 30,
                                            child: Slider(
                                              value: _currentExposureOffset,
                                              min: _minAvailableExposureOffset,
                                              max: _maxAvailableExposureOffset,
                                              activeColor: Colors.white,
                                              inactiveColor: Colors.white30,
                                              onChanged: (value) async {
                                                setState(() {
                                                  _currentExposureOffset =
                                                      value;
                                                });
                                                await controller!
                                                    .setExposureOffset(value);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Slider(
                                              value: _currentZoomLevel,
                                              min: _minAvailableZoom,
                                              max: _maxAvailableZoom,
                                              activeColor: Colors.white,
                                              inactiveColor: Colors.white30,
                                              onChanged: (value) async {
                                                setState(() {
                                                  _currentZoomLevel = value;
                                                });
                                                await controller!
                                                    .setZoomLevel(value);
                                              },
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  _currentZoomLevel
                                                          .toStringAsFixed(1) +
                                                      'x',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              //Navigator.pop(context);
                                              Navigator.pushNamed(context, "/Endpoints").then( (res){ initDB(); } );
                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.black38,
                                                  size: 60,
                                                ),
                                                _image != null
                                                    ? GestureDetector(
                                                  onTap: _pickFromGallery,
                                                  child: Image.file(
                                                    _image!,
                                                    width: 30,
                                                    height: 30,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                                    : GestureDetector(
                                                  onTap: _pickFromGallery,
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 30,
                                                    color: Colors.grey,
                                                  ),
                                                ),

                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () async {

                                              String? imageFile  =
                                                  await takePicture();
                                              _saveLocalImage(imageFile);
                                              CropandUpload(imageFile);
                                              //Navigator.pop(context, imageFile );
                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.white38,
                                                  size: 80,
                                                ),
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.white,
                                                  size: 65,
                                                ),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _isCameraInitialized = false;
                                              });
                                              onNewCameraSelected(cameras[
                                                  _isRearCameraSelected
                                                      ? 1
                                                      : 0]);
                                              setState(() {
                                                _isRearCameraSelected =
                                                    !_isRearCameraSelected;
                                              });
                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.black38,
                                                  size: 60,
                                                ),
                                                Icon(
                                                  _isRearCameraSelected
                                                      ? Icons.camera_front
                                                      : Icons.camera_rear,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      16.0, 8.0, 16.0, 8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          setState(() {
                                            _currentFlashMode = FlashMode.off;
                                          });
                                          await controller!.setFlashMode(
                                            FlashMode.off,
                                          );
                                        },
                                        child: Icon(
                                          Icons.flash_off,
                                          color:
                                              _currentFlashMode == FlashMode.off
                                                  ? Colors.amber
                                                  : Colors.white,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          setState(() {
                                            _currentFlashMode = FlashMode.auto;
                                          });
                                          await controller!.setFlashMode(
                                            FlashMode.auto,
                                          );
                                        },
                                        child: Icon(
                                          Icons.flash_auto,
                                          color: _currentFlashMode ==
                                                  FlashMode.auto
                                              ? Colors.amber
                                              : Colors.white,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          setState(() {
                                            _currentFlashMode =
                                                FlashMode.always;
                                          });
                                          await controller!.setFlashMode(
                                            FlashMode.always,
                                          );
                                        },
                                        child: Icon(
                                          Icons.flash_on,
                                          color: _currentFlashMode ==
                                                  FlashMode.always
                                              ? Colors.amber
                                              : Colors.white,
                                        ),
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          setState(() {
                                            _currentFlashMode = FlashMode.torch;
                                          });
                                          await controller!.setFlashMode(
                                            FlashMode.torch,
                                          );
                                        },
                                        child: Icon(
                                          Icons.highlight,
                                          color: _currentFlashMode ==
                                                  FlashMode.torch
                                              ? Colors.amber
                                              : Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                          /*Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [

                  ],
                ),
              ),
            ),*/
                        ],
                      ) // end of Portrait
                    : Row(
                        children: [
                          AspectRatio(
                              aspectRatio: controller!.value.aspectRatio,
                              child: Stack(children: [
                                CameraPreview(
                                  controller!,
                                  child: LayoutBuilder(builder:
                                      (BuildContext context,
                                          BoxConstraints constraints) {
                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTapDown: (details) =>
                                          onViewFinderTap(details, constraints),
                                    );
                                  }),
                                ),
                                // TODO: Uncomment to preview the overlay
                                // Center(
                                //   child: Image.asset(
                                //     'assets/camera_aim.png',
                                //     color: Colors.greenAccent,
                                //     width: 150,
                                //     height: 150,
                                //   ),
                                // ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    16.0,
                                    8.0,
                                    16.0,
                                    8.0,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Align(
                                          child: RotatedBox(
                                              quarterTurns: 3,
                                              child: Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    InkWell(
                                                      onTap: () async {
                                                        setState(() {
                                                          _currentFlashMode =
                                                              FlashMode.off;
                                                        });
                                                        await controller!
                                                            .setFlashMode(
                                                          FlashMode.off,
                                                        );
                                                      },
                                                      child: Icon(
                                                        Icons.flash_off,
                                                        color:
                                                        _currentFlashMode ==
                                                            FlashMode
                                                                .off
                                                            ? Colors.amber
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () async {
                                                        setState(() {
                                                          _currentFlashMode =
                                                              FlashMode.auto;
                                                        });
                                                        await controller!
                                                            .setFlashMode(
                                                          FlashMode.auto,
                                                        );
                                                      },
                                                      child: Icon(
                                                        Icons.flash_auto,
                                                        color:
                                                        _currentFlashMode ==
                                                            FlashMode
                                                                .auto
                                                            ? Colors.amber
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () async {
                                                        setState(() {
                                                          _currentFlashMode =
                                                              FlashMode.always;
                                                        });
                                                        await controller!
                                                            .setFlashMode(
                                                          FlashMode.always,
                                                        );
                                                      },
                                                      child: Icon(
                                                        Icons.flash_on,
                                                        color:
                                                        _currentFlashMode ==
                                                            FlashMode
                                                                .always
                                                            ? Colors.amber
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                    InkWell(
                                                      onTap: () async {
                                                        setState(() {
                                                          _currentFlashMode =
                                                              FlashMode.torch;
                                                        });
                                                        await controller!
                                                            .setFlashMode(
                                                          FlashMode.torch,
                                                        );
                                                      },
                                                      child: Icon(
                                                        Icons.highlight,
                                                        color:
                                                        _currentFlashMode ==
                                                            FlashMode
                                                                .torch
                                                            ? Colors.amber
                                                            : Colors.white,
                                                      ),
                                                    ),
                                                  ]))),
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Container(
                                          margin:
                                          const EdgeInsets.only(top: 30),
                                          decoration: BoxDecoration(
                                            //color: Colors.grey[700],
                                            borderRadius:
                                            BorderRadius.circular(50.0),
                                          ),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.pushNamed(context, "/Endpoints").then( (res){ initDB(); } );

                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.black38,
                                                  size: 60,
                                                ),
                                                Icon(
                                                  Icons.settings,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 8.0,
                                              right: 8.0,
                                            ),
                                            child: DropdownButton<
                                                ResolutionPreset>(
                                              dropdownColor: Colors.black87,
                                              underline: Container(),
                                              value: currentResolutionPreset,
                                              items: [
                                                for (ResolutionPreset preset
                                                    in resolutionPresets)
                                                  DropdownMenuItem(
                                                    child: Text(
                                                      preset
                                                          .toString()
                                                          .split('.')[1]
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                    value: preset,
                                                  )
                                              ],
                                              onChanged: (value) {
                                                setState(() {
                                                  currentResolutionPreset =
                                                      value!;
                                                  _isCameraInitialized = false;
                                                });
                                                onNewCameraSelected(
                                                    controller!.description);
                                              },
                                              hint: Text("Select item"),
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Spacer(),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            right: 8.0, top: 16.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10.0),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              _currentExposureOffset
                                                      .toStringAsFixed(1) +
                                                  'x',
                                              style: TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: RotatedBox(
                                          quarterTurns: 0,
                                          child: Container(
                                            height: 30,
                                            child: Slider(
                                              value: _currentExposureOffset,
                                              min: _minAvailableExposureOffset,
                                              max: _maxAvailableExposureOffset,
                                              activeColor: Colors.white,
                                              inactiveColor: Colors.white30,
                                              onChanged: (value) async {
                                                setState(() {
                                                  _currentExposureOffset =
                                                      value;
                                                });
                                                await controller!
                                                    .setExposureOffset(value);
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Expanded(
                                              child: RotatedBox(
                                                  quarterTurns: 3,
                                                  child: Container(
                                                    height: 30,
                                                    child: Slider(
                                                      value: _currentZoomLevel,
                                                      min: _minAvailableZoom,
                                                      max: _maxAvailableZoom,
                                                      activeColor:
                                                          Colors.blueAccent,
                                                      inactiveColor:
                                                          Colors.white30,
                                                      onChanged: (value) async {
                                                        setState(() {
                                                          _currentZoomLevel =
                                                              value;
                                                        });
                                                        await controller!
                                                            .setZoomLevel(
                                                                value);
                                                      },
                                                    ),
                                                  ))),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 8.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.black87,
                                                borderRadius:
                                                    BorderRadius.circular(10.0),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  _currentZoomLevel
                                                          .toStringAsFixed(1) +
                                                      'x',
                                                  style: TextStyle(
                                                      color: Colors.white),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                _isCameraInitialized = false;
                                              });
                                              onNewCameraSelected(cameras[
                                                  _isRearCameraSelected
                                                      ? 1
                                                      : 0]);
                                              setState(() {
                                                _isRearCameraSelected =
                                                    !_isRearCameraSelected;
                                              });
                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.black38,
                                                  size: 60,
                                                ),
                                                Icon(
                                                  _isRearCameraSelected
                                                      ? Icons.camera_front
                                                      : Icons.camera_rear,
                                                  color: Colors.white,
                                                  size: 30,
                                                ),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () async {

                                              String? imageFile  =
                                              await takePicture();
                                              _saveLocalImage(imageFile);
                                              CropandUpload(imageFile);
                                              //Navigator.pop(context, imageFile );

                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.white38,
                                                  size: 80,
                                                ),
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.white,
                                                  size: 65,
                                                ),
                                              ],
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              Navigator.pushNamed(context, "/Endpoints").then( (res){ initDB(); } );

                                            },
                                            child: Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Icon(
                                                  Icons.circle,
                                                  color: Colors.black38,
                                                  size: 60,
                                                ),
                                                _image != null
                                                    ? GestureDetector(
                                                  onTap: _pickFromGallery,
                                                  child: Image.file(
                                                    _image!,
                                                    width: 30,
                                                    height: 30,
                                                    fit: BoxFit.cover,
                                                  ),
                                                )
                                                    : GestureDetector(
                                                  onTap: _pickFromGallery,
                                                  child: Icon(
                                                    Icons.image,
                                                    size: 30,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                    ],
                                  ),
                                ),
                              ]))
                          /*Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  children: [


                  ],
                ),
              ),
            ),*/
                        ],
                      )
                : Center(
                    child: Text(
                      'LOADING',
                      style: TextStyle(color: Colors.white),
                    ),
                  )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(),
                  Text(
                    'Permission denied',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      getPermissionStatus();
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Give permission',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
