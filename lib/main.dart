import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_vision/google_ml_vision.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;
  await Firebase.initializeApp();

  runApp(MaterialApp(home: HomePage(camera: firstCamera)));
}

class HomePage extends StatefulWidget {
  final CameraDescription camera;

  const HomePage({super.key, required this.camera});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;

      final image = await _controller.takePicture();
      analyzeImage(image);
    } catch (e) {
      print(e);
    }
  }

  // Função para analisar a imagem
  Future<void> analyzeImage(XFile image) async {
    final GoogleVisionImage visionImage =
        GoogleVisionImage.fromFilePath(image.path);
    final ImageLabeler labeler = GoogleVision.instance.imageLabeler();
    final List<ImageLabel> labels = await labeler.processImage(visionImage);

    // Criando uma lista de widgets para exibir as etiquetas e confianças
    List<Widget> labelWidgets = labels
        .map((label) => Text(
            '${label.text}: ${label.confidence!.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 16)))
        .toList();

    // Exibindo um diálogo com os resultados
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Objetos Identificados"),
          content: SingleChildScrollView(
            child: ListBody(children: labelWidgets),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Câmera HomePage')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Exibindo a pré-visualização da câmera
            return CameraPreview(_controller);
          } else {
            // Exibindo um spinner de carregamento enquanto a câmera está sendo inicializada
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
