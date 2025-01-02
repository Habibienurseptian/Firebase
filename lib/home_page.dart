import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> todos = []; // Menyimpan daftar todo
  bool isLoading = true; // Status loading untuk menampilkan indikator progress

  @override
  void initState() {
    super.initState();
    getTodo(); // Memanggil fungsi getTodo() untuk mengambil data ketika halaman pertama kali dimuat
  }

  // Fungsi untuk mengambil daftar todo dari Firestore
  Future<void> getTodo() async {
    try {
      // Mengambil data dari koleksi 'todos' di Firestore
      QuerySnapshot querySnapshot = await _firestore.collection('todos').get();
      
      setState(() {
        todos = querySnapshot.docs.map((doc) {
          return {
            'id': doc.id,
            'title': doc['title'],
            'description': doc['description'],
            'isComplete': doc['isComplete'],
          };
        }).toList();
        isLoading = false; // Setelah data diambil, set loading menjadi false
      });
    } catch (e) {
      setState(() {
        isLoading = false; // Menghentikan indikator loading jika terjadi error
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error fetching data: $e'),
      ));
    }
  }

  // Menambahkan todo baru
  Future<void> addTodo(String title, String description) async {
    try {
      await _firestore.collection('todos').add({
        'title': title,
        'description': description,
        'isComplete': false, // Default status isComplete
        'createdAt': Timestamp.now(),
      });
      getTodo(); // Memanggil getTodo untuk memuat ulang data setelah penambahan
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error adding todo: $e'),
      ));
    }
  }

  // Logout function
  void _logout() async {
    await _auth.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator()) // Menampilkan loading indicator
          : Column(
              children: [
                // Input form untuk menambahkan todo baru
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Title'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          addTodo('New Todo', 'This is a new todo description');
                        },
                        child: const Text('Add Todo'),
                      ),
                    ],
                  ),
                ),
                // Daftar todo
                Expanded(
                  child: ListView.builder(
                    itemCount: todos.length,
                    itemBuilder: (context, index) {
                      var todo = todos[index];
                      return Card(
                        child: ListTile(
                          title: Text(todo['title']),
                          subtitle: Text(todo['description']),
                          trailing: Icon(
                            todo['isComplete']
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: todo['isComplete'] ? Colors.green : Colors.red,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
