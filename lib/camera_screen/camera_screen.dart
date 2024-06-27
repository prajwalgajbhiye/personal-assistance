import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:gemini_chat_bot/camera_screen/result_screen.dart';
import 'package:image_picker/image_picker.dart';

class HomeScreen2 extends StatefulWidget {
  const HomeScreen2({Key? key}) : super(key: key);

  @override
  State<HomeScreen2> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen2> {
  late ImagePicker imagePicker;
  CameraController? controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    initCamera();
  }

  Future<void> initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        controller = CameraController(cameras[0], ResolutionPreset.medium);
        _initializeControllerFuture = controller!.initialize().then((_) {
          setState(() {}); // This triggers a rebuild once the camera is initialized
        });
      } else {
        print('No cameras available on the device');
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return buildCameraScreen(context);
          } else if (snapshot.hasError) {
            print('Camera initialization error: ${snapshot.error}');
            return Center(child: Text('Error initializing camera: ${snapshot.error}'));
          } else {
            print('Waiting for camera to initialize...');
            return const Center(child: CircularProgressIndicator());
          }
        }
    );
  }

  Widget buildCameraScreen(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(height: 40,),
            // buildActionRow(),
            if (controller != null) buildCameraPreview(),
            buildBottomRow(context),
          ],
        ),
      ),
    );
  }

  // Widget buildActionRow() {
  //   return const Padding(
  //     padding: EdgeInsets.only(top: 15),
  //     child: Card(
  //       color: Colors.blueAccent,
  //       child: SizedBox(
  //         height: 10,
  //         // child: Row(
  //         //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //         //   children: [
  //         //     Column(
  //         //       mainAxisAlignment: MainAxisAlignment.center,
  //         //       children: [
  //         //         Icon(Icons.adf_scanner_sharp, size: 30, color: Colors.white),
  //         //         Text(
  //         //           'Scan',
  //         //           style: TextStyle(color: Colors.white),
  //         //         )
  //         //       ],
  //         //     ),
  //         //     Column(
  //         //       mainAxisAlignment: MainAxisAlignment.center,
  //         //       children: [
  //         //         Icon(Icons.document_scanner, size: 30, color: Colors.white),
  //         //         Text(
  //         //           'Recognize',
  //         //           style: TextStyle(color: Colors.white),
  //         //         )
  //         //       ],
  //         //     ),
  //         //     Column(
  //         //       mainAxisAlignment: MainAxisAlignment.center,
  //         //       children: [
  //         //         Icon(Icons.assignment, size: 30, color: Colors.white),
  //         //         Text(
  //         //           'Enhanced',
  //         //           style: TextStyle(color: Colors.white),
  //         //         )
  //         //       ],
  //         //     ),
  //         //   ],
  //         // ),
  //       ),
  //     ),
  //   );
  // }

  Widget buildCameraPreview() {
    return Card(
      color: Colors.black,
      child: SizedBox(
        height: MediaQuery.of(context).size.height -300,
        child: CameraPreview(controller!),
      ),
    );
  }

  Widget buildBottomRow(BuildContext context) {
    return Card(
      color: Colors.grey.shade900,
      child: SizedBox(
        height: 100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const Icon(Icons.rotate_left, size: 50, color: Colors.white),
            InkWell(
                onTap: () async {
                  if (controller != null && controller!.value.isInitialized) {
                    try {
                      // Attempt to take a picture and then get the file `XFile`.
                      final XFile? xfile = await controller!.takePicture();
                      if (xfile != null) {
                        File imageFile = File(xfile.path);

                        // Optionally, navigate to another screen with the image
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => RecognizerScreen( image: imageFile,),
                        ));
                      }
                    } catch (e) {
                      // If an error occurs, log the error to the console.
                      print(e);
                    }
                  }
                },
                child: const Icon(Icons.camera, size: 50, color: Colors.white)),
            galleryAccessIcon(context),
          ],
        ),
      ),
    );
  }

  Widget galleryAccessIcon(BuildContext context) {
    return InkWell(
      onTap: () async {
        final xfile = await imagePicker.pickImage(source: ImageSource.gallery);
        if (xfile != null) {
          final image = File(xfile.path);
          Navigator.push(context, MaterialPageRoute(
              builder: (context) => RecognizerScreen( image: image,)
          ));
        }
      },
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image, size: 50, color: Colors.white),
        ],
      ),
    );
  }

}
