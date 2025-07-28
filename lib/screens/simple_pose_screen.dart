import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class SimplePoseScreen extends StatefulWidget {
  @override
  _SimplePoseScreenState createState() => _SimplePoseScreenState();
}

class _SimplePoseScreenState extends State<SimplePoseScreen> {
  // 1. Variables básicas que necesitamos
  CameraController? cameraController;
  List<CameraDescription> cameras = [];
  bool isCameraReady = false;
  
  // 2. Variables para ML Kit
  PoseDetector? poseDetector;
  List<Pose> detectedPoses = [];
  
  @override
  void initState() {
    super.initState();
    setupCamera();
    setupPoseDetector();
  }

  // 3. PASO 1: Configurar la cámara
  void setupCamera() async {
    // Obtener lista de cámaras disponibles
    cameras = await availableCameras();
    
    // Crear controlador con la primera cámara (trasera)
    cameraController = CameraController(
      cameras[0], // Cámara trasera
      ResolutionPreset.medium, // Resolución media
    );
    
    // Inicializar la cámara
    await cameraController!.initialize();
    
    // Activar el stream de imágenes
    cameraController!.startImageStream(processImage);
    
    setState(() {
      isCameraReady = true;
    });
  }

  // 4. PASO 2: Configurar el detector de poses
  void setupPoseDetector() {
    poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        model: PoseDetectionModel.base, // Modelo básico (más rápido)
      ),
    );
  }

  // 5. PASO 3: Procesar cada imagen de la cámara
  void processImage(CameraImage image) async {
    // Convertir CameraImage a InputImage para ML Kit
    final inputImage = convertToInputImage(image);
    
    // Detectar poses
    final poses = await poseDetector!.processImage(inputImage);
    
    // Actualizar la pantalla
    setState(() {
      detectedPoses = poses;
    });
  }

  // 6. PASO 4: Convertir imagen de cámara a formato ML Kit
  InputImage convertToInputImage(CameraImage image) {
    // Esto es lo mínimo necesario para que funcione
    final bytes = image.planes[0].bytes;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    
    return InputImage.fromBytes(
      bytes: bytes,
      inputImageData: InputImageData(
        size: size,
        imageRotation: InputImageRotation.rotation0deg,
        inputImageFormat: InputImageFormat.yuv420,
        planeData: image.planes.map((plane) {
          return InputImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Si la cámara no está lista, mostrar loading
    if (!isCameraReady || cameraController == null) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('ML Kit Básico'),
      ),
      body: Stack(
        children: [
          // Vista de la cámara
          CameraPreview(cameraController!),
          
          // Dibujar puntos de las poses detectadas
          CustomPaint(
            painter: PosePointsPainter(detectedPoses),
            child: Container(),
          ),
          
          // Información básica
          Positioned(
            top: 20,
            left: 20,
            child: Container(
              padding: EdgeInsets.all(10),
              color: Colors.black54,
              child: Text(
                'Poses detectadas: ${detectedPoses.length}',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController?.dispose();
    poseDetector?.close();
    super.dispose();
  }
}

// 7. PASO 5: Dibujar puntos en pantalla
class PosePointsPainter extends CustomPainter {
  final List<Pose> poses;
  
  PosePointsPainter(this.poses);

  @override
  void paint(Canvas canvas, Size size) {
    // Pincel para dibujar puntos
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 5.0;

    // Para cada pose detectada
    for (Pose pose in poses) {
      // Para cada punto de la pose
      pose.landmarks.forEach((type, landmark) {
        // Solo dibujar si la confianza es alta
        if (landmark.likelihood > 0.5) {
          // Dibujar un círculo en la posición del punto
          canvas.drawCircle(
            Offset(landmark.x, landmark.y),
            3.0,
            paint,
          );
        }
      });
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}