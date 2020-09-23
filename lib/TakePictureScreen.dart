import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

import 'package:camera_firebase/LoadingIndicator.dart';

class TakePictureScreen extends StatefulWidget {
  final TakePictureScreenState takePictureScreenState =
      TakePictureScreenState();

  Future<String> takePicture() async {
    return (await takePictureScreenState.takePicture());
  }

  Future<void> switchCameras() async {
    return (await takePictureScreenState.switchCamera());
  }

  @override
  TakePictureScreenState createState() => takePictureScreenState;
}

class TakePictureScreenState extends State<TakePictureScreen> {
  List cameras;
  int cameraIdx = 0;
  CameraController _controller;
  Future<void> _initializeControllerFuture;
  bool isReady = false;

  @override
  void initState() {
    super.initState();
    _setUpCamera();
  }

  Future<void> _setUpCamera() async {
    try {
      cameras = await availableCameras();

      _controller = CameraController(
        cameras[cameraIdx],
        ResolutionPreset.ultraHigh,
      );

      await _controller.initialize();

      setState(() {
        isReady = true;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return isReady
        ? Container(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: CameraPreview(_controller),
            ),
          )
        : LoadingIndicator();
  }

  Future<void> switchCamera() async {
    cameraIdx = cameraIdx < cameras.length - 1 ? cameraIdx + 1 : 0;
    setState(() {
      isReady = false;
    });
    await _setUpCamera();
  }

  Future<String> takePicture() async {
    try {
      await _initializeControllerFuture;
      final path =
          join((await getTemporaryDirectory()).path, '${DateTime.now()}.png');
      await _controller.takePicture(path);
      return path;
    } catch (e) {
      print(e);
    }
    return ('');
  }
}
