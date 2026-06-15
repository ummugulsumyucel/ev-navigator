import 'package:ev_navigator/core/config/firebase_config.dart';
import 'package:ev_navigator/core/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseConfig.initialize();
  runApp(const ProviderScope(child: AdminApp()));
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EV Navigator Admin',
      theme: AppTheme.dark,
      home: const AdminAuthGate(),
    );
  }
}

/// RBAC — yalnızca Firestore role=admin kullanıcıları erişebilir
class AdminAuthGate extends StatefulWidget {
  const AdminAuthGate({super.key});

  @override
  State<AdminAuthGate> createState() => _AdminAuthGateState();
}

class _AdminAuthGateState extends State<AdminAuthGate> {
  bool _checking = true;
  bool _isAdmin = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _error = 'Giriş yapılmamış. Önce mobil uygulamadan giriş yapın veya Firebase Auth ile oturum açın.';
          _checking = false;
        });
        return;
      }
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = doc.data()?['role'] as String? ?? 'user';
      setState(() {
        _isAdmin = role == 'admin';
        _checking = false;
        if (!_isAdmin) {
          _error = 'Bu panele erişim yetkiniz yok. Kullanıcı rolü: $role';
        }
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('EV Navigator Admin')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text(_error ?? 'Erişim reddedildi', textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Firebase Proje: ${FirebaseConfig.projectId}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return const AdminDashboard();
  }
}

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EV Navigator Admin')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _AdminTile(
            title: 'Kullanıcılar',
            icon: Icons.people,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UsersAdminPage()),
            ),
          ),
          _AdminTile(
            title: 'Şarj İstasyonları',
            icon: Icons.ev_station,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StationsAdminPage()),
            ),
          ),
          _AdminTile(
            title: 'Haberler',
            icon: Icons.newspaper,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NewsAdminPage()),
            ),
          ),
          _AdminTile(
            title: 'Topluluk Denetimi',
            icon: Icons.forum,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CommunityAdminPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class StationsAdminPage extends StatefulWidget {
  const StationsAdminPage({super.key});

  @override
  State<StationsAdminPage> createState() => _StationsAdminPageState();
}

class _StationsAdminPageState extends State<StationsAdminPage> {
  final _nameController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İstasyon Yönetimi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'İstasyon Adı'),
                ),
                TextField(
                  controller: _latController,
                  decoration: const InputDecoration(labelText: 'Enlem'),
                ),
                TextField(
                  controller: _lngController,
                  decoration: const InputDecoration(labelText: 'Boylam'),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('charging_stations')
                        .add({
                      'name': _nameController.text,
                      'network': 'zes',
                      'location': {
                        'lat': double.tryParse(_latController.text) ?? 41.0,
                        'lng': double.tryParse(_lngController.text) ?? 29.0,
                      },
                      'address': '',
                      'city': 'İstanbul',
                      'sockets': [
                        {
                          'id': '1',
                          'type': 'ccs2',
                          'powerKw': 150,
                          'status': 'available',
                        },
                      ],
                      'status': 'available',
                      'reliabilityScore': 4.0,
                      'supportsReservation': true,
                      'photoUrls': [],
                      'availableCount': 1,
                      'totalSockets': 1,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('İstasyon eklendi')),
                      );
                    }
                  },
                  child: const Text('İstasyon Ekle'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('charging_stations')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, i) {
                    final data =
                        snapshot.data!.docs[i].data()! as Map<String, dynamic>;
                    return ListTile(
                      title: Text(data['name'] as String? ?? ''),
                      subtitle: Text(data['network'] as String? ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            snapshot.data!.docs[i].reference.delete(),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class NewsAdminPage extends StatefulWidget {
  const NewsAdminPage({super.key});

  @override
  State<NewsAdminPage> createState() => _NewsAdminPageState();
}

class _NewsAdminPageState extends State<NewsAdminPage> {
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Haber Yönetimi')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Başlık'),
            ),
            TextField(
              controller: _summaryController,
              decoration: const InputDecoration(labelText: 'Özet'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('news').add({
                  'title': _titleController.text,
                  'summary': _summaryController.text,
                  'content': _summaryController.text,
                  'category': 'Genel',
                  'publishedAt': FieldValue.serverTimestamp(),
                });
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Haber yayınlandı')),
                  );
                }
              },
              child: const Text('Haber Yayınla'),
            ),
          ],
        ),
      ),
    );
  }
}

class CommunityAdminPage extends StatelessWidget {
  const CommunityAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Topluluk Denetimi')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('community_posts')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              final doc = snapshot.data!.docs[i];
              final data = doc.data()! as Map<String, dynamic>;
              return ListTile(
                title: Text(data['title'] as String? ?? ''),
                subtitle: Text(data['authorName'] as String? ?? ''),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => doc.reference.delete(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class UsersAdminPage extends StatelessWidget {
  const UsersAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanıcı Yönetimi')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, i) {
              final data =
                  snapshot.data!.docs[i].data()! as Map<String, dynamic>;
              return ListTile(
                title: Text(data['displayName'] as String? ?? ''),
                subtitle: Text(data['email'] as String? ?? ''),
                trailing: Text(data['role'] as String? ?? 'user'),
              );
            },
          );
        },
      ),
    );
  }
}
