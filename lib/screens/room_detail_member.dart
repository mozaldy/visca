import 'package:flutter/material.dart';
import 'package:visca/features/face_recognition/add_person_view.dart';
import 'package:visca/features/face_recognition/entities/face_embedding.dart';
import 'package:visca/features/face_recognition/services/database_service.dart';
import 'package:visca/features/face_recognition/entities/person.dart';
import 'package:visca/models/room_model.dart';

class RoomDetailMemberPage extends StatefulWidget {
  final RoomModel room;

  const RoomDetailMemberPage({required this.room, Key? key}) : super(key: key);

  @override
  State<RoomDetailMemberPage> createState() => _RoomDetailMemberPageState();
}

class _RoomDetailMemberPageState extends State<RoomDetailMemberPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Person> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Assuming DatabaseService is already initialized elsewhere or handles it internally
      // If not, you might need: await _databaseService.initialize();
      final persons = await _databaseService.getLocallyRegisteredPersonsForRoom(
        widget.room.id,
      ); // Or a room-specific method

      setState(() {
        _members = persons;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading members: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Placeholder for navigating to an AddMember/AddPerson screen
  // You'll connect this to your AddPersonView later
  Future<void> _navigateToAddMember(String roomId) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPersonView(roomId: roomId),
      ), // Example
    );

    if (result == true || result == null && mounted) {
      // result == null for back button press
      _loadMembers(); // Refresh the list
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child:
                _isLoading
                    ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading members...'),
                        ],
                      ),
                    )
                    : _members.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No members in this room yet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Use the "+" button to add new members', // Adjusted message
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: _loadMembers,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8),
                        itemCount: _members.length,
                        itemBuilder: (context, index) {
                          final member = _members[index];
                          return _buildMemberCard(member);
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _navigateToAddMember(widget.room.id);
        }, // To be implemented fully later
        tooltip: 'Add Member',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 134,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4C7273), Color(0xFF8FD7D9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.center, // Adjusted for better alignment
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: 0,
              ), // Keep if specific alignment needed
              child: IconButton(
                icon: const Icon(
                  Icons.chevron_left,
                  color: Colors.white,
                  size: 32, // Slightly larger for easier tap
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center text vertically
                children: [
                  Text(
                    widget.room.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text(
                    'Total members: ${_members.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Optional: Refresh button in header if not using pull-to-refresh
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadMembers,
              tooltip: 'Refresh members',
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(Person member) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          member.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          'Added on ${_formatDate(member.createdAt)}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<int>(
              future: _getFaceEmbeddingCount(member),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count face${count != 1 ? 's' : ''}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteConfirmation(member);
                } else if (value == 'view_details') {
                  _showMemberDetails(member);
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'view_details',
                      child: Row(
                        children: [
                          Icon(Icons.visibility, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('View Details'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
              child: const Icon(Icons.more_vert),
            ),
          ],
        ),
        onTap: () {
          _showMemberDetails(member);
        },
      ),
    );
  }

  Future<int> _getFaceEmbeddingCount(Person person) async {
    try {
      // Ensure person.id is not null if your service expects a non-nullable id
      // final embeddings = await _databaseService.getFaceEmbeddingsForPerson(person);
      // Assuming Person object itself is enough or it contains the necessary ID
      final embeddings = await _databaseService.getFaceEmbeddingsForPerson(
        person,
      );
      return embeddings.length;
    } catch (e) {
      print("Error getting face embedding count: $e");
      return 0;
    }
  }

  Future<List<FaceEmbedding>> _getFaceEmbeddings(Person person) async {
    try {
      // final embeddings = await _databaseService.getFaceEmbeddingsForPerson(person);
      // Assuming Person object itself is enough or it contains the necessary ID
      final embeddings = await _databaseService.getFaceEmbeddingsForPerson(
        person,
      );
      return embeddings;
    } catch (e) {
      print("Error getting face embeddings: $e");
      return [];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDetailDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120, // Adjusted width for potentially longer labels
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  void _showMemberDetails(Person member) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              // In case content is too long
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'ID',
                    member.id.toString(),
                  ), // Handle potential null ID
                  _buildDetailRow('Name', member.name),
                  _buildDetailRow('ID', member.roomId),
                  _buildDetailRow(
                    'Added On',
                    _formatDetailDate(member.createdAt),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<FaceEmbedding>>(
                    future: _getFaceEmbeddings(
                      member,
                    ), // Changed to get full embeddings
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildDetailRow('Face Embeddings', 'Loading...');
                      }
                      final embeddings = snapshot.data ?? [];
                      String embeddingText = '${embeddings.length} found';
                      if (embeddings.isNotEmpty) {
                        // Displaying all embeddings might be too much.
                        // Consider showing just the count or a summary.
                        // For demonstration, showing the first one if available.
                        // embeddingText += '\nFirst: ${embeddings.first.embedding.take(5)}...'; // Example: show first 5 values
                        embeddingText =
                            '${embeddings.length} registered'; // Simplified
                      }
                      return _buildDetailRow('Face Data', embeddingText);
                    },
                  ),
                  // Example: Displaying raw embedding data (can be very long)
                  // Be cautious with displaying raw embedding arrays directly in UI
                  // FutureBuilder<List<FaceEmbedding>>(
                  //   future: _getFaceEmbeddings(member),
                  //   builder: (context, snapshot) {
                  //     if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                  //       return Column(
                  //         crossAxisAlignment: CrossAxisAlignment.start,
                  //         children: [
                  //           const SizedBox(height: 8),
                  //           const Text("Embeddings:", style: TextStyle(fontWeight: FontWeight.bold)),
                  //           Text(snapshot.data!.first.embedding.toString().substring(0,snapshot.data!.first.embedding.toString().length > 100 ? 100 : snapshot.data!.first.embedding.toString().length) + "...", style: TextStyle(fontSize: 10)),
                  //         ],
                  //       );
                  //     }
                  //     return const SizedBox.shrink();
                  //   },
                  // ),
                ],
              ),
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

  void _showDeleteConfirmation(Person member) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Member'),
            content: Text(
              'Are you sure you want to delete "${member.name}" and all associated face data? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  _deleteMember(member);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _deleteMember(Person member) async {
    try {
      // await _databaseService.deletePerson(member.id); // Assuming deletePerson takes an ID
      await _databaseService.deletePerson(
        member,
      ); // Or the Person object itself
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${member.name} deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
      _loadMembers(); // Refresh the list
    } catch (e) {
      print('Error deleting member: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting member: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
