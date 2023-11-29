import 'dart:ffi';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:fluttertoast/fluttertoast.dart';

GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<Album> createAlbum(String img, String color) async {
  final http.Response response = await http.post(
    Uri.parse(
        'https://0506-2001-14bb-690-29ec-f030-798a-71df-af79.ngrok-free.app/process_image'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(
        <String, String>{'image_data': img, 'background_color': color}),
  );

  if (response.statusCode == 200) {
    return Album.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to create album.');
  }
}

Future<List<Background>> listBackgrounds() async {
  final http.Response response = await http.get(
    Uri.parse(
        'https://0506-2001-14bb-690-29ec-f030-798a-71df-af79.ngrok-free.app/backgrounds'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
  );

  if (response.statusCode == 200) {
    return List<Background>.from(
        json.decode(response.body).map((x) => Background.fromJson(x)));
  } else {
    throw Exception('Failed to load backgrounds.');
  }
}

Future<Album> getBackground(int id) async {
  final http.Response response = await http.post(
    Uri.parse(
        'https://0506-2001-14bb-690-29ec-f030-798a-71df-af79.ngrok-free.app/static'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },
    body: jsonEncode(<String, int>{'id': id}),
  );

  if (response.statusCode == 200) {
    return Album.fromJson(json.decode(response.body));
  } else {
    throw Exception('Failed to create album.');
  }
}

class Album {
  final String image;

  Album({required this.image});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      image: json['image'],
    );
  }
}

class Background {
  int id;
  String name;

  Background({required this.id, required this.name});

  factory Background.fromJson(Map<String, dynamic> json) {
    return Background(
      id: json['id'],
      name: json['name'],
    );
  }
}

const List<Color> colors = [
  Colors.red,
  Colors.pink,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.lightBlue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.lightGreen,
  Colors.lime,
  Colors.yellow,
  Colors.amber,
  Colors.orange,
  Colors.deepOrange,
  Colors.brown,
  Colors.grey,
  Colors.white,
  Colors.black,
];

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primaryColor: Colors.green),
      home: const BackgroundRemoval(),
      debugShowCheckedModeBanner: false,
      builder: FToastBuilder(),
      navigatorKey: navigatorKey,
    );
  }
}

class BackgroundRemoval extends StatefulWidget {
  const BackgroundRemoval({super.key});

  @override
  State<BackgroundRemoval> createState() => _BackgroundRemovalState();
}

class _BackgroundRemovalState extends State<BackgroundRemoval> {
  bool _inProcess = false;
  late FToast fToast;

  final picker = ImagePicker();
  XFile? _pickedFile;
  CroppedFile? _croppedFile;
  Uint8List? _processedFile;
  late Album _futureAlbum;
  late List<Background> _test;

  Color _mycolor = Colors.white;
  int _portraitCrossAxisCount = 4;
  int _landscapeCrossAxisCount = 5;
  double _borderRadius = 30;
  double _blurRadius = 5;
  double _iconSize = 24;

  late final List<Uint8List?> _customBackground;

  @override
  void initState() {
    super.initState();
    fToast = FToast();
    getBackgrounds();
    // if you want to use context from globally instead of content we need to pass navigatorKey.currentContext!
    fToast.init(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Background removal app'),
        backgroundColor: Colors.green,
        actions: const [],
      ),
      body: Stack(
        children: [
          Builder(
            builder: (BuildContext context) {
              return Center(
                child: Column(
                  // mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // main image display
                    Expanded(child: _image_primary()),
                    // submit button
                    ElevatedButton(
                      style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                              _processedFile == null
                                  ? Colors.green
                                  : Colors.white)),
                      child: _processedFile == null
                          ? const Center(child: Text('Submit'))
                          : Container(),
                      onPressed: () {
                        if (_processedFile == null) {
                          submit();
                          setState(() {
                            _inProcess = true;
                          });
                        } else {
                          setState(() {
                            _processedFile = null;
                            _inProcess = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          // progress indicator
          (_inProcess)
              ? Container(
                  color: Colors.white,
                  height: MediaQuery.of(context).size.height * 0.95,
                  child: const Center(child: CircularProgressIndicator()))
              : const Center()
        ],
      ),
    );
  }

  Widget _image_primary() {
    if (_processedFile != null) {
      return _resultCard();
    } else if (_croppedFile != null || _pickedFile != null) {
      return _imageCard();
    } else {
      return _uploaderCard();
    }
  }

  Widget _resultCard() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kIsWeb ? 24.0 : 16.0),
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(kIsWeb ? 24.0 : 16.0),
                child: _image(),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          _actionButtons(),
        ],
      ),
    );
  }

  Widget _imageCard() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: kIsWeb ? 24.0 : 16.0),
            child: Card(
              elevation: 4.0,
              child: Padding(
                padding: const EdgeInsets.all(kIsWeb ? 24.0 : 16.0),
                child: _image(),
              ),
            ),
          ),
          const SizedBox(height: 24.0),
          _actionButtons(),
        ],
      ),
    );
  }

  Widget _image() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    if (_processedFile != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        // child: kIsWeb ? Image.network(path) : Image.file(File(path)),
        child: Image.memory(_processedFile!),
      );
    } else if (_croppedFile != null) {
      final path = _croppedFile!.path;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: kIsWeb ? Image.network(path) : Image.file(File(path)),
      );
    } else if (_pickedFile != null) {
      final path = _pickedFile!.path;
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 0.8 * screenWidth,
          maxHeight: 0.7 * screenHeight,
        ),
        child: kIsWeb ? Image.network(path) : Image.file(File(path)),
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  Widget pickerLayoutBuilder(
      BuildContext context, List<Color> colors, PickerItem child) {
    Orientation orientation = MediaQuery.of(context).orientation;

    return SizedBox(
      width: 300,
      height: orientation == Orientation.portrait ? 360 : 240,
      child: GridView.count(
        crossAxisCount: orientation == Orientation.portrait
            ? _portraitCrossAxisCount
            : _landscapeCrossAxisCount,
        crossAxisSpacing: 5,
        mainAxisSpacing: 5,
        children: [for (Color color in colors) child(color)],
      ),
    );
  }

  Widget pickerItemBuilder(
      Color color, bool isCurrentColor, void Function() changeColor) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_borderRadius),
        border: color == Colors.white
            ? Border.all(
                color: Colors.grey,
                width: 2,
              )
            : null,
        color: color,
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.8),
              offset: const Offset(1, 2),
              blurRadius: _blurRadius)
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: changeColor,
          borderRadius: BorderRadius.circular(_borderRadius),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: isCurrentColor ? 1 : 0,
            child: Icon(
              Icons.done,
              size: _iconSize,
              color: useWhiteForeground(color) ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButtons() {
    List<Uint8List?> files = _customBackground.toList();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: FloatingActionButton(
            onPressed: () {
              _clear();
            },
            backgroundColor: Colors.redAccent,
            tooltip: 'Delete',
            child: const Icon(Icons.delete),
          ),
        ),
        if (_croppedFile == null && _processedFile == null)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: FloatingActionButton(
              onPressed: () {
                _cropImage();
              },
              backgroundColor: const Color(0xFFBC764A),
              tooltip: 'Crop',
              child: const Icon(Icons.crop),
            ),
          ),
        if (_processedFile == null)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: FloatingActionButton(
              backgroundColor: _mycolor,
              tooltip: 'Pick a background color',
              onPressed: () {},
              // child: const Icon(Icons.color_lens),
              child: Padding(
                padding: const EdgeInsets.all(kIsWeb ? 16.0 : 12.0),
                child: Center(
                  child: Ink(
                    decoration: const ShapeDecoration(
                      color: Colors.black,
                      shape: CircleBorder(),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.color_lens),
                      padding: const EdgeInsets.all(kIsWeb ? 6.0 : 4.0),
                      iconSize: kIsWeb ? 32.0 : 24.0,
                      color: Colors.white,
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Pick a background color!'),
                                content: SingleChildScrollView(
                                  child: BlockPicker(
                                    pickerColor: _mycolor,
                                    onColorChanged: (Color color) {
                                      //on color picked
                                      setState(() {
                                        _mycolor = color;
                                      });
                                    },
                                    availableColors: colors,
                                    layoutBuilder: pickerLayoutBuilder,
                                    itemBuilder: pickerItemBuilder,
                                  ),
                                ),
                                actions: <Widget>[
                                  ElevatedButton(
                                    child: const Text('DONE'),
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); //dismiss the color picker
                                    },
                                  ),
                                ],
                              );
                            });
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        if (_processedFile == null)
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: FloatingActionButton(
              backgroundColor: Colors.lightGreen,
              tooltip: 'Pick a background image',
              child: const Icon(Icons.image_outlined),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('Pick a background image!'),
                        content: SingleChildScrollView(
                          child: GridView.builder(
                              padding: const EdgeInsets.all(20),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 5.0,
                                crossAxisSpacing: 5.0,
                              ),
                              itemCount: 5,
                              itemBuilder: (context, index) {
                                // return GridTile(child: Image.file(files[index]));
                                return GridTile(
                                  child: Image.memory(
                                    files[index]!,
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 100,
                                  ),
                                );
                              }),
                        ),
                        actions: <Widget>[
                          ElevatedButton(
                            child: const Text('DONE'),
                            onPressed: () {
                              Navigator.of(context)
                                  .pop(); //dismiss the color picker
                            },
                          ),
                        ],
                      );
                    });
              },
            ),
          ),
        if (_processedFile != null)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0),
            child: FloatingActionButton(
              onPressed: () async {
                await _saveFileToGallery();
                _showToast('Image saved to gallery');
              },
              backgroundColor: const Color(0xFFBC764A),
              tooltip: 'Download',
              child: const Icon(Icons.download),
            ),
          ),
      ],
    );
  }

  Widget _uploaderCard() {
    return Center(
      child: Card(
        elevation: 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: SizedBox(
          width: kIsWeb ? 380.0 : 320.0,
          height: 300.0,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: DottedBorder(
                    radius: const Radius.circular(12.0),
                    borderType: BorderType.RRect,
                    dashPattern: const [8, 4],
                    color: Theme.of(context).highlightColor.withOpacity(0.4),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image,
                            color: Theme.of(context).highlightColor,
                            size: 80.0,
                          ),
                          const SizedBox(height: 24.0),
                          Text(
                            'Upload an image to start',
                            style: kIsWeb
                                ? Theme.of(context)
                                    .textTheme
                                    .headlineSmall!
                                    .copyWith(
                                        color: Theme.of(context).highlightColor)
                                : Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .copyWith(
                                        color:
                                            Theme.of(context).highlightColor),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    MaterialButton(
                        color: Colors.green,
                        child: const Text(
                          "Camera",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          _uploadImage(ImageSource.camera);
                        }),
                    MaterialButton(
                        color: Colors.deepOrange,
                        child: const Text(
                          "Device",
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          _uploadImage(ImageSource.gallery);
                        })
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _cropImage() async {
    if (_pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _pickedFile!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: false),
          IOSUiSettings(
            title: 'Cropper',
          ),
          WebUiSettings(
            context: context,
            presentStyle: CropperPresentStyle.dialog,
            boundary: const CroppieBoundary(
              width: 520,
              height: 520,
            ),
            viewPort:
                const CroppieViewPort(width: 480, height: 480, type: 'circle'),
            enableExif: true,
            enableZoom: true,
            showZoomer: true,
          ),
        ],
      );
      if (croppedFile != null) {
        setState(() {
          _croppedFile = croppedFile;
        });
      }
    }
  }

  Future<void> _uploadImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _pickedFile = pickedFile;
      });
    }
  }

  submit() async {
    try {
      if (_croppedFile != null || _pickedFile != null) {
        File? imagefile;
        if (_croppedFile != null) {
          imagefile = File(_croppedFile!.path);
        } else {
          imagefile = File(_pickedFile!.path);
        }
        Uint8List imagebytes = await imagefile.readAsBytes(); //convert to bytes
        String base64string =
            base64.encode(imagebytes); //convert bytes to base64 string
        //decode base64 string to bytes
        _futureAlbum = await createAlbum(
            base64string, '#${_mycolor.value.toRadixString(16).substring(2)}');
        setState(() {
          _processedFile = base64Decode(_futureAlbum.image);
          _inProcess = false;
        });
      } else {
        print("No image is selected.");
      }
    } catch (e) {
      print(e);
    }
  }

  Future<bool> _saveFileToGallery() async {
    await ImageGallerySaver.saveImage(_processedFile!);
    return true;
  }

  void getBackgrounds() async {
    try {
      _test = await listBackgrounds();
      _test.forEach((background) async {
        var bg = await getBackground(background.id);
        // Perform operations on each Background object
        _customBackground.add(base64Decode(bg.image));
      });
    } catch (e) {
      print(e);
    }
  }

  void _clear() {
    setState(() {
      _processedFile = null;
      _pickedFile = null;
      _croppedFile = null;
    });
  }

  _showToast(message) {
    Widget toast = Container(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.greenAccent,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check),
          const SizedBox(
            width: 12.0,
          ),
          Text(message),
        ],
      ),
    );

    fToast.showToast(
      child: toast,
      gravity: ToastGravity.BOTTOM,
      toastDuration: Duration(seconds: 2),
    );

    // Custom Toast Position
    // fToast.showToast(
    //     child: toast,
    //     toastDuration: Duration(seconds: 2),
    //     positionedToastBuilder: (context, child) {
    //       return Positioned(
    //         child: child,
    //         top: 16.0,
    //         left: 16.0,
    //       );
    //     });
  }
}
