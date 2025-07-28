import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:math';

class ExerciseDetector extends StatefulWidget {
  @override
  _ExerciseDetectorState createState() => _ExerciseDetectorState();
}

class _ExerciseDetectorState extends State<ExerciseDetector> {
  CameraController? camera;
  PoseDetector? detector;
  
  // 📊 DATOS TEMPORALES
  List<Pose> poseHistory = [];        // Historial de poses
  List<double> elbowHeights = [];     // Historial de alturas de codos
  List<double> kneeAngles = [];       // Historial de ángulos de rodillas
  
  // 🏋️ CONTADORES
  int pushUpCount = 0;
  int squatCount = 0;
  
  // 🔄 ESTADO DEL EJERCICIO
  bool isPushingUp = false;
  bool isSquatting = false;
  String currentExercise = "Esperando...";
  
  @override
  void initState() {
    super.initState();
    setupCamera();
  }

  setupCamera() async {
    final cameras = await availableCameras();
    detector = PoseDetector(options: PoseDetectorOptions());
    
    camera = CameraController(cameras[0], ResolutionPreset.medium);
    await camera!.initialize();
    camera!.startImageStream(analyzeFrame);
    
    setState(() {});
  }

  // 🎯 ANÁLISIS DE CADA FRAME
  void analyzeFrame(CameraImage image) async {
    final inputImage = convertToInputImage(image);
    final poses = await detector!.processImage(inputImage);
    
    if (poses.isNotEmpty) {
      Pose pose = poses.first;
      
      // 📚 AGREGAR AL HISTORIAL
      poseHistory.add(pose);
      if (poseHistory.length > 30) poseHistory.removeAt(0); // Mantener solo 1 segundo
      
      // 🔍 ANALIZAR EJERCICIOS
      analyzePushUps(pose);
      analyzeSquats(pose);
      
      setState(() {});
    }
  }

  // 🏋️ DETECTOR DE FLEXIONES
  void analyzePushUps(Pose pose) {
    // 1️⃣ Calcular altura promedio de codos
    double? leftElbowY = pose.landmarks[PoseLandmarkType.leftElbow]?.y;
    double? rightElbowY = pose.landmarks[PoseLandmarkType.rightElbow]?.y;
    
    if (leftElbowY == null || rightElbowY == null) return;
    
    double averageElbowY = (leftElbowY + rightElbowY) / 2;
    elbowHeights.add(averageElbowY);
    
    // 2️⃣ Mantener solo último segundo
    if (elbowHeights.length > 30) elbowHeights.removeAt(0);
    
    // 3️⃣ Analizar si tenemos suficiente historial
    if (elbowHeights.length < 10) return;
    
    // 4️⃣ Comparar con frames anteriores
    double currentHeight = averageElbowY;
    double previousHeight = elbowHeights[elbowHeights.length - 5];
    double difference = currentHeight - previousHeight;
    
    // 5️⃣ Detectar movimiento
    if (difference > 15 && !isPushingUp) {
      // Codos bajando (flexión hacia abajo)
      isPushingUp = true;
      currentExercise = "Push-up (bajando)";
    } else if (difference < -15 && isPushingUp) {
      // Codos subiendo (flexión completada)
      isPushingUp = false;
      pushUpCount++;
      currentExercise = "Push-up completado!";
    }
  }

  // 🏃 DETECTOR DE SENTADILLAS
  void analyzeSquats(Pose pose) {
    // 1️⃣ Calcular ángulo de rodillas
    double leftKneeAngle = calculateKneeAngle(pose, true);
    double rightKneeAngle = calculateKneeAngle(pose, false);
    double averageKneeAngle = (leftKneeAngle + rightKneeAngle) / 2;
    
    kneeAngles.add(averageKneeAngle);
    
    // 2️⃣ Mantener solo último segundo
    if (kneeAngles.length > 30) kneeAngles.removeAt(0);
    
    // 3️⃣ Analizar si tenemos suficiente historial
    if (kneeAngles.length < 10) return;
    
    // 4️⃣ Comparar ángulos
    double currentAngle = averageKneeAngle;
    double previousAngle = kneeAngles[kneeAngles.length - 5];
    
    // 5️⃣ Detectar movimiento
    if (currentAngle < 110 && previousAngle > 140 && !isSquatting) {
      // Rodillas doblándose (sentadilla hacia abajo)
      isSquatting = true;
      currentExercise = "Sentadilla (bajando)";
    } else if (currentAngle > 150 && previousAngle < 120 && isSquatting) {
      // Rodillas extendiéndose (sentadilla completada)
      isSquatting = false;
      squatCount++;
      currentExercise = "Sentadilla completada!";
    }
  }

  // 📐 CALCULAR ÁNGULO DE RODILLA
  double calculateKneeAngle(Pose pose, bool isLeft) {
    PoseLandmark? hip = pose.landmarks[isLeft ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    PoseLandmark? knee = pose.landmarks[isLeft ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    PoseLandmark? ankle = pose.landmarks[isLeft ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];
    
    if (hip == null || knee == null || ankle == null) return 180.0;
    
    // Calcular vectores
    double vector1X = hip.x - knee.x;
    double vector1Y = hip.y - knee.y;
    double vector2X = ankle.x - knee.x;
    double vector2Y = ankle.y - knee.y;
    
    // Calcular ángulo
    double dotProduct = vector1X * vector2X + vector1Y * vector2Y;
    double magnitude1 = sqrt(vector1X * vector1X + vector1Y * vector1Y);
    double magnitude2 = sqrt(vector2X * vector2X + vector2Y * vector2Y);
    
    double angle = acos(dotProduct / (magnitude1 * magnitude2));
    return angle * 180 / pi; // Convertir radianes a grados
  }

  // 🔄 CONVERSIÓN DE IMAGEN
  InputImage convertToInputImage(CameraImage image) {
    final bytes = image.planes[0].bytes;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    
    return InputImage.fromBytes(
      bytes: bytes,
      inputImageData: InputImageData(
        size: size,
        imageRotation: InputImageRotation.rotation0deg,
        inputImageFormat: InputImageFormat.yuv420,
        planeData: [],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (camera == null || !camera!.value.isInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Detector de Ejercicios'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: [
          // 📹 VISTA DE CÁMARA
          Expanded(
            flex: 3,
            child: CameraPreview(camera!),
          ),
          
          // 📊 PANEL DE INFORMACIÓN
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              color: Colors.black87,
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    currentExercise,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildCounter("Push-ups", pushUpCount, Colors.orange),
                      _buildCounter("Sentadillas", squatCount, Colors.green),
                      _buildCounter("Poses", poseHistory.length, Colors.blue),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Frames analizados: ${elbowHeights.length}/30",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounter(String title, int count, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    camera?.dispose();
    detector?.close();
    super.dispose();
  }
}