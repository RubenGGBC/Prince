import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class MLSimple extends StatefulWidget {
  @override
  _MLSimpleState createState() => _MLSimpleState();
}

class _MLSimpleState extends State<MLSimple> {
  CameraController? camera;
  PoseDetector? detector;
  
  bool personDetected = false;
  String message = "Iniciando cámara...";

  @override
  void initState() {
    super.initState();
    startCamera();
  }

  startCamera() async {
    // 1. Obtener cámaras
    final cameras = await availableCameras();
    
    // 2. Crear detector
    detector = PoseDetector(options: PoseDetectorOptions());
    
    // 3. Configurar cámara
    camera = CameraController(cameras[0], ResolutionPreset.medium);
    await camera!.initialize();
    
    // 4. Empezar a analizar
    camera!.startImageStream(analyzeImage);
    
    setState(() {
      message = "Cámara lista. Ponte frente a la cámara.";
    });
  }

  analyzeImage(CameraImage image) async {
    // Convertir imagen
    final inputImage = InputImage.fromBytes(
      bytes: image.planes[0].bytes,
      inputImageData: InputImageData(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        imageRotation: InputImageRotation.rotation0deg,
        inputImageFormat: InputImageFormat.yuv420,
        planeData: [],
      ),
    );

    // Detectar poses
    final poses = await detector!.processImage(inputImage);
    
    // ¿Hay alguien?
    setState(() {
      if (poses.isNotEmpty) {
        personDetected = true;
        message = "¡Persona detectada! 👤";
      } else {
        personDetected = false;
        message = "No hay nadie en la cámara 🔍";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ML Kit Simple'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Cámara
          if (camera != null && camera!.value.isInitialized)
            Expanded(
              flex: 3,
              child: CameraPreview(camera!),
            )
          else
            Expanded(
              flex: 3,
              child: Center(child: CircularProgressIndicator()),
            ),
          
          // Estado
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: personDetected ? Colors.green : Colors.red,
              child: Center(
                child: Text(
                  message,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    camera?.dispose();
    detector?.close();
    super.dispose();
  }
}