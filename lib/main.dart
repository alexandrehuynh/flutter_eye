import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui' as ui;
import 'pose_painter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.camera.request();
  runApp(EyeSpyApp());
}

class EyeSpyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eye Spy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _cameraController;
  late PoseDetector _poseDetector;
  bool _isCameraInitialized = false;
  List<Pose> _detectedPoses = [];
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializePoseDetector();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _cameraController = CameraController(
      firstCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController.initialize();
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
      _imageSize = Size(
        _cameraController.value.previewSize!.height,
        _cameraController.value.previewSize!.width,
      );
    });

    Timer.periodic(Duration(milliseconds: 200), (timer) {
      if (_cameraController.value.isInitialized) {
        _captureAndProcessImage();
      }
    });
  }

  void _initializePoseDetector() {
    final options = PoseDetectorOptions();
    _poseDetector = PoseDetector(options: options);
  }

  void _captureAndProcessImage() async {
    try {
      XFile file = await _cameraController.takePicture();
      final bytes = await file.readAsBytes();
      final image = await decodeImageFromList(bytes);
      
      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.width * 4,
        ),
      );

      final poses = await _poseDetector.processImage(inputImage);
      setState(() {
        _detectedPoses = poses;
      });
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: Text('Eye Spy')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController),
          if (_imageSize != null)
            CustomPaint(
              painter: PosePainter(_detectedPoses, _imageSize!),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _poseDetector.close();
    super.dispose();
  }
}