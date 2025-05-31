import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'services/database_service.dart';
import 'services/facenet_service.dart';
import 'utils/face_processor.dart';

class AddPersonView extends StatefulWidget {
  const AddPersonView({super.key});

  @override
  State<AddPersonView> createState() => _AddPersonViewState();
}

class _AddPersonViewState extends State<AddPersonView> {
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _faceNetService = FaceNetService();
  final _databaseService = DatabaseService.instance;

  List<img.Image> _detectedFaces = [];
  bool _isProcessing = false;
  bool _isExtractingFaces = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    await _faceNetService.initialize();
    await _databaseService.initialize();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Person')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Person Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isExtractingFaces ? null : _selectImages,
              child:
                  _isExtractingFaces
                      ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Detecting Faces...'),
                        ],
                      )
                      : const Text('Select Images'),
            ),
            const SizedBox(height: 20),
            if (_detectedFaces.isNotEmpty) ...[
              Text('Detected Faces: ${_detectedFaces.length}'),
              const SizedBox(height: 10),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _detectedFaces.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              _imageToBytes(_detectedFaces[index]),
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeFace(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ] else if (!_isExtractingFaces) ...[
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.face, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No faces detected yet',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Select images to detect faces',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed:
                  _isProcessing ||
                          _isExtractingFaces ||
                          _nameController.text.trim().isEmpty ||
                          _detectedFaces.isEmpty
                      ? null
                      : _processPerson,
              child:
                  _isProcessing
                      ? const CircularProgressIndicator()
                      : const Text('Add Person'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectImages() async {
    final images = await _imagePicker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _isExtractingFaces = true;
      });

      await _extractFacesFromImages(
        images.map((xFile) => File(xFile.path)).toList(),
      );
    }
  }

  Future<void> _extractFacesFromImages(List<File> imageFiles) async {
    final List<img.Image> allFaces = [];

    try {
      for (final imageFile in imageFiles) {
        final faces = await FaceProcessor.extractFacesFromImage(imageFile);
        allFaces.addAll(faces);
      }

      setState(() {
        _detectedFaces = allFaces;
        _isExtractingFaces = false;
      });

      // Show feedback to user
      if (allFaces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No faces detected in the selected images. '
              'Please select images with clear, visible faces.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully detected ${allFaces.length} face(s) '
              'from ${imageFiles.length} image(s)',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isExtractingFaces = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error detecting faces: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeFace(int index) {
    setState(() {
      _detectedFaces.removeAt(index);
    });
  }

  Uint8List _imageToBytes(img.Image image) {
    return Uint8List.fromList(img.encodePng(image));
  }

  Future<void> _processPerson() async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Create person in database
      final person = await _databaseService.addPerson(
        _nameController.text.trim(),
      );

      // Process each detected face
      for (final faceImage in _detectedFaces) {
        // Generate embedding
        final embedding = await _faceNetService.generateEmbedding(faceImage);

        // Store embedding
        await _databaseService.addFaceEmbedding(person, embedding);
      }

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully added ${_nameController.text} with '
            '${_detectedFaces.length} face(s)',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Clear form
      _nameController.clear();
      setState(() {
        _detectedFaces.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding person: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
}
