import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:visca/features/face_recognition/camera_view.dart';
import 'package:visca/features/face_recognition/painters/face_recognition_painter.dart';
import 'package:visca/features/face_recognition/services/face_recognition_service.dart';
import 'package:visca/features/face_recognition/services/facenet_service.dart';
import 'package:visca/models/attendance_model.dart';
import 'package:visca/services/attendance_service.dart';
import 'dart:async';

class FaceDetectorView extends StatefulWidget {
  final AttendanceModel attendance;

  const FaceDetectorView({Key? key, required this.attendance})
    : super(key: key);

  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceNetService _faceNetService = FaceNetService();
  late final FaceRecognitionService _recognitionService;
  final AttendanceService _attendanceService = AttendanceService();

  bool _canProcess = true;
  bool _isBusy = false;
  bool _isInitialized = false;
  var _cameraLensDirection = CameraLensDirection.front;
  List<FaceRecognitionResult> _results = [];

  Map<String, dynamic>? _roomStats;

  final Map<String, DateTime> _lastCheckInAttempt = {};

  late AttendanceModel _currentAttendance;
  StreamSubscription<AttendanceModel>? _attendanceSubscription;

  String? _lastCheckedInUser;
  DateTime? _lastCheckInTime;

  Size _imageSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;
  CustomPaint? _customPaint;

  @override
  void initState() {
    super.initState();
    _currentAttendance = widget.attendance;
    _recognitionService = FaceRecognitionService(
      faceNetService: _faceNetService,
    );
    _initializeService();
    _startAttendanceStream();
  }

  Future<void> _initializeService() async {
    try {
      // Initialize with the room ID from attendance
      await _recognitionService.initialize(roomId: widget.attendance.roomId);

      // Get room statistics
      _roomStats = await _recognitionService.getRoomStats(
        widget.attendance.roomId,
      );

      setState(() {
        _isInitialized = true;
      });

      print(
        'Face recognition initialized for room: ${widget.attendance.roomId}',
      );
      print('Room stats: $_roomStats');
    } catch (e) {
      print('Error initializing service: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize face recognition: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startAttendanceStream() {
    _attendanceSubscription = _attendanceService
        .getAttendanceStream(widget.attendance.id)
        .listen(
          (updatedAttendance) {
            setState(() {
              _currentAttendance = updatedAttendance;
            });
          },
          onError: (error) {
            print('Error listening to attendance updates: $error');
          },
        );
  }

  @override
  void dispose() {
    _canProcess = false;
    _attendanceSubscription?.cancel();
    _recognitionService.dispose();
    super.dispose();
  }

  Future<void> _checkInUser(String userName) async {
    try {
      // Prevent spam attempts within 5 seconds
      final now = DateTime.now();
      final lastAttempt = _lastCheckInAttempt[userName];
      if (lastAttempt != null && now.difference(lastAttempt).inSeconds < 5) {
        return;
      }
      _lastCheckInAttempt[userName] = now;

      // Check if user is already checked in
      if (_currentAttendance.checkedInUsers.contains(userName)) {
        return;
      }

      await _attendanceService.addCheckedInUser(widget.attendance.id, userName);

      setState(() {
        _lastCheckedInUser = userName;
        _lastCheckInTime = now;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $userName checked in successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      print('Successfully checked in: $userName');
    } catch (e) {
      print('Error checking in user $userName: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check in $userName: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance: ${_currentAttendance.name}'),
        backgroundColor: const Color(0xFF4C7273),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showAttendanceInfo();
            },
          ),
          IconButton(
            icon: const Icon(Icons.face),
            onPressed: () {
              _showRoomFaceStats();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Show loading overlay if not initialized
          if (!_isInitialized)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Initializing face recognition...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),

          CameraView(
            customPaint: _customPaint,
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) {
              _cameraLensDirection = value;
              _updateCustomPaint();
            },
          ),

          // Results overlay
          Positioned(
            left: 16,
            right: 16,
            bottom: 80,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status row
                  Row(
                    children: [
                      Icon(
                        _isInitialized
                            ? Icons.check_circle
                            : Icons.hourglass_empty,
                        color: _isInitialized ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isInitialized
                            ? 'Recognition Active'
                            : 'Initializing...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Faces: ${_results.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // Room info
                  if (_roomStats != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Registered: ${_roomStats!['registeredPersons']} people, ${_roomStats!['totalEmbeddings']} faces',
                      style: const TextStyle(color: Colors.cyan, fontSize: 11),
                    ),
                  ],

                  // Attendance info
                  const SizedBox(height: 4),
                  Text(
                    'Checked in: ${_currentAttendance.totalCheckedIn}',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Last check-in info
                  if (_lastCheckedInUser != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Last: $_lastCheckedInUser',
                      style: const TextStyle(color: Colors.green, fontSize: 11),
                    ),
                  ],

                  // Current faces
                  if (_results.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Current faces:',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._results.asMap().entries.map((entry) {
                      final result = entry.value;
                      final isCheckedIn = _currentAttendance.checkedInUsers
                          .contains(result.personName);

                      Color iconColor;
                      IconData iconData;

                      if (isCheckedIn) {
                        iconColor = Colors.green;
                        iconData = Icons.check_circle;
                      } else if (result.isRecognized) {
                        iconColor = Colors.blue;
                        iconData = Icons.person;
                      } else {
                        iconColor = Colors.red;
                        iconData = Icons.person_outline;
                      }

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 1),
                        child: Row(
                          children: [
                            Icon(iconData, color: iconColor, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${result.personName} '
                                '(${result.similarity.toStringAsFixed(3)})'
                                '${isCheckedIn ? " ✓" : ""}',
                                style: TextStyle(
                                  color: iconColor,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAttendanceInfo() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(_currentAttendance.name),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Room ID: ${_currentAttendance.roomId}'),
                Text('Total checked in: ${_currentAttendance.totalCheckedIn}'),
                const SizedBox(height: 8),
                const Text('Checked in users:'),
                const SizedBox(height: 4),
                if (_currentAttendance.checkedInUsers.isEmpty)
                  const Text(
                    'No users checked in yet',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ..._currentAttendance.checkedInUsers.map(
                  (user) =>
                      Text('• $user', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  void _showRoomFaceStats() {
    if (_roomStats == null) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Registered Faces'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Room ID: ${_roomStats!['roomId']}'),
                Text('Registered people: ${_roomStats!['registeredPersons']}'),
                Text(
                  'Total face embeddings: ${_roomStats!['totalEmbeddings']}',
                ),
                const SizedBox(height: 8),
                const Text('Registered names:'),
                const SizedBox(height: 4),
                if (_roomStats!['registeredNames'].isEmpty)
                  const Text(
                    'No faces registered yet',
                    style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ...(_roomStats!['registeredNames'] as List<String>).map(
                  (name) =>
                      Text('• $name', style: const TextStyle(fontSize: 12)),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy || !_isInitialized) return;

    _isBusy = true;

    try {
      // Pass the room ID to ensure only room members are recognized
      final results = await _recognitionService.recognizeFaces(
        inputImage,
        roomId: widget.attendance.roomId,
      );

      // Auto check-in recognized users (all results are already filtered by room)
      for (final result in results) {
        if (result.isRecognized &&
            result.personName != 'Not recognized' &&
            result.personName != 'Error') {
          await _checkInUser(result.personName);
        }
      }

      // Update image metadata for the painter
      _imageSize = Size(
        inputImage.metadata?.size.width.toDouble() ?? 0,
        inputImage.metadata?.size.height.toDouble() ?? 0,
      );
      _rotation =
          inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg;

      setState(() {
        _results = results;
        _updateCustomPaint();
      });
    } catch (e) {
      print('Error processing frame: $e');
    } finally {
      _isBusy = false;
    }
  }

  void _updateCustomPaint() {
    if (_results.isNotEmpty && _imageSize != Size.zero) {
      _customPaint = _buildCustomPaint();
    } else {
      _customPaint = null;
    }
  }

  CustomPaint _buildCustomPaint() {
    return CustomPaint(
      painter: FaceRecognitionPainter(
        _results,
        _imageSize,
        _rotation,
        _cameraLensDirection,
      ),
    );
  }
}
