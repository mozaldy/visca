import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import 'services/database_service.dart'; // Your ObjectBox DatabaseService
import 'services/facenet_service.dart'; // Your FaceNetService
import 'utils/face_processor.dart'; // Your FaceProcessor utility
import 'package:visca/services/room_service.dart'; // Add this import

class AddPersonView extends StatefulWidget {
  final String roomId;

  const AddPersonView({super.key, required this.roomId});

  @override
  State<AddPersonView> createState() => _AddPersonViewState();
}

class _AddPersonViewState extends State<AddPersonView> {
  final _nameController = TextEditingController();
  final _imagePicker = ImagePicker();
  late final FaceNetService _faceNetService;
  late final DatabaseService _databaseService;
  late final RoomService _roomService; // Add RoomService

  List<img.Image> _detectedFaces = [];
  bool _isProcessing = false;
  bool _isExtractingFaces = false;
  bool _servicesInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _faceNetService = FaceNetService();
    _databaseService = DatabaseService.instance;
    _roomService = RoomService(); // Initialize RoomService

    try {
      await _faceNetService.initialize();
      if (mounted) {
        setState(() {
          _servicesInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing services: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Uint8List _imageToBytes(img.Image image) {
    return Uint8List.fromList(img.encodePng(image));
  }

  void _removeFace(int index) {
    if (mounted) {
      setState(() {
        _detectedFaces.removeAt(index);
      });
    }
  }

  Future<void> _selectImages() async {
    if (!_servicesInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Services not ready. Please wait.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_isExtractingFaces) return;

    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 70,
      );

      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          _isExtractingFaces = true;
          _detectedFaces.clear();
        });

        List<img.Image> allFacesFromSelection = [];
        for (final xFile in pickedFiles) {
          if (!mounted) break;
          try {
            final facesInOneImage = await FaceProcessor.extractFacesFromImage(
              File(xFile.path),
            );
            allFacesFromSelection.addAll(facesInOneImage);
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error processing image ${xFile.name}: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }

        if (mounted) {
          setState(() {
            _detectedFaces = allFacesFromSelection;
            _isExtractingFaces = false;
          });
          if (allFacesFromSelection.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'No faces detected in the selected images. Try different images.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${allFacesFromSelection.length} face(s) detected.',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExtractingFaces = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processPerson() async {
    if (!_servicesInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Services not ready. Please wait.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final String currentName = _nameController.text.trim();
    if (currentName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name for the person.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (_detectedFaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No faces detected. Please select images and ensure faces are found.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (mounted) setState(() => _isProcessing = true);

    try {
      // Step 1: Add person to local ObjectBox database
      final person = await _databaseService.addPerson(
        currentName,
        widget.roomId,
      );

      int embeddingsAddedCount = 0;
      for (final faceImage in _detectedFaces) {
        if (!mounted) break;
        final embedding = await _faceNetService.generateEmbedding(faceImage);
        if (embedding.isNotEmpty) {
          bool added = await _databaseService.addFaceEmbeddingWithValidation(
            person,
            embedding,
          );
          if (added) embeddingsAddedCount++;
        }
      }

      if (!mounted) return;

      if (embeddingsAddedCount > 0) {
        // Step 2: Add member name to Firebase room if local registration was successful
        try {
          await _roomService.addMemberNameToRoom(widget.roomId, currentName);
          print(
            'Successfully added "$currentName" to Firebase room "${widget.roomId}"',
          );
        } catch (firebaseError) {
          // Log the Firebase error but don't fail the entire operation
          // since local face data was successfully saved
          print(
            'Warning: Failed to add "$currentName" to Firebase room "${widget.roomId}": $firebaseError',
          );

          // Optionally show a warning to the user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Local face data saved successfully, but failed to sync with cloud: $firebaseError',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }

        // Step 3: Show success message and navigate back
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Face data for "$currentName" ($embeddingsAddedCount face(s)) registered successfully for room ${widget.roomId}.',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, currentName);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not generate valid embeddings for the detected faces. Please try with clearer images.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error registering face data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_servicesInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Register Face')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing services...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Register Face for Room: ${widget.roomId}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Person\'s Name',
                hintText: 'Enter unique name for this member',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              enabled: !_isProcessing && !_isExtractingFaces,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon:
                  _isExtractingFaces
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.collections),
              label: Text(
                _isExtractingFaces
                    ? 'Detecting Faces...'
                    : 'Select Images to Detect Faces',
              ),
              onPressed:
                  _isProcessing || _isExtractingFaces ? null : _selectImages,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 16),
            if (_detectedFaces.isNotEmpty)
              Text(
                'Detected Faces: ${_detectedFaces.length} (Tap image to remove)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            const SizedBox(height: 8),
            if (_detectedFaces.isNotEmpty)
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: _detectedFaces.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap:
                          _isProcessing || _isExtractingFaces
                              ? null
                              : () => _removeFace(index),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.memory(
                                _imageToBytes(_detectedFaces[index]),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                            ),
                          ),
                          if (!_isProcessing && !_isExtractingFaces)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.7),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              )
            else if (!_isExtractingFaces)
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_search, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No faces selected or detected yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        Text(
                          'Use "Select Images" to begin.',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon:
                  _isProcessing
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.save),
              label: const Text('Save Face Data to Device'),
              onPressed:
                  _isProcessing || _isExtractingFaces || _detectedFaces.isEmpty
                      ? null
                      : _processPerson,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
