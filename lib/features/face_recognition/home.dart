import 'package:flutter/material.dart';
import 'package:visca/features/face_recognition/add_person_view.dart';
import 'package:visca/features/face_recognition/entities/face_embedding.dart';
import 'package:visca/features/face_recognition/face_detector_view.dart';
import 'package:visca/features/face_recognition/services/database_service.dart';
import 'package:visca/features/face_recognition/entities/person.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<Person> _persons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _databaseService.initialize();
      final persons = await _databaseService.getAllPersons();

      setState(() {
        _persons = persons;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading persons: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddPerson() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPersonView()),
    );

    // Refresh the list when coming back from AddPersonView
    if (result == true || result == null) {
      _loadPersons();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('VISCA DIVISI FACE RECOGNITION'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main buttons
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FaceDetectorView()),
                );
              },
              icon: const Icon(Icons.face),
              label: const Text('Face Detector'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToAddPerson,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Person'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 32),

            // Persons list section
            Row(
              children: [
                const Icon(Icons.people, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Added Persons (${_persons.length})',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_persons.isNotEmpty)
                  IconButton(
                    onPressed: _loadPersons,
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh list',
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Persons list
            Expanded(
              child:
                  _isLoading
                      ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Loading persons...'),
                          ],
                        ),
                      )
                      : _persons.isEmpty
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
                              'No persons added yet',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Use "Add Person" to register new faces',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        itemCount: _persons.length,
                        itemBuilder: (context, index) {
                          final person = _persons[index];
                          return _buildPersonCard(person, index);
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonCard(Person person, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Text(
            person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          person.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        subtitle: Text(
          'Added on ${_formatDate(person.createdAt)}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FutureBuilder<int>(
              future: _getFaceEmbeddingCount(person),
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
                  _showDeleteConfirmation(person);
                }
              },
              itemBuilder:
                  (context) => [
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
          _showPersonDetails(person);
        },
      ),
    );
  }

  Future<int> _getFaceEmbeddingCount(Person person) async {
    try {
      final embeddings = await _databaseService.getFaceEmbeddingsForPerson(
        person,
      );
      return embeddings.length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<FaceEmbedding>> _getFaceEmbedding(Person person) async {
    try {
      final embeddings = await _databaseService.getFaceEmbeddingsForPerson(
        person,
      );
      return embeddings;
    } catch (e) {
      return [];
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showPersonDetails(Person person) {
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
                    person.name.isNotEmpty ? person.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    person.name,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('ID', person.id.toString()),
                _buildDetailRow('Name', person.name),
                _buildDetailRow('Created', _formatDetailDate(person.createdAt)),
                const SizedBox(height: 16),
                FutureBuilder<int>(
                  future: _getFaceEmbeddingCount(person),
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return _buildDetailRow('Face Embeddings', count.toString());
                  },
                ),
                FutureBuilder<List<FaceEmbedding>>(
                  future: _getFaceEmbedding(person),
                  builder: (context, snapshot) {
                    final List<FaceEmbedding> embedding = snapshot.data ?? [];
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
                        embedding.first.embedding.toString(),
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  String _formatDetailDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showDeleteConfirmation(Person person) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Person'),
            content: Text(
              'Are you sure you want to delete "${person.name}" and all associated face data?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deletePerson(person);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  Future<void> _deletePerson(Person person) async {
    try {
      await _databaseService.deletePerson(person);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${person.name} deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadPersons(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting person: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
