import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../providers/auth_providers.dart';

class ProfileCompletionScreen extends ConsumerStatefulWidget {
  const ProfileCompletionScreen({super.key});

  @override
  ConsumerState<ProfileCompletionScreen> createState() =>
      _ProfileCompletionScreenState();
}

class _ProfileCompletionScreenState
    extends ConsumerState<ProfileCompletionScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    if (user != null && _nameController.text.isEmpty) {
      _nameController.text = user.displayName;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profili Tamamla')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Deneyiminizi kişiselleştirmek için birkaç bilgi daha.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Görünen Ad',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Telefon (isteğe bağlı)',
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () async {
                if (Validators.required(_nameController.text) != null) return;
                await ref.read(authControllerProvider.notifier).completeProfile(
                      displayName: _nameController.text.trim(),
                      phone: _phoneController.text.trim().isEmpty
                          ? null
                          : _phoneController.text.trim(),
                    );
                if (context.mounted) context.go('/home');
              },
              child: const Text('Devam Et'),
            ),
          ],
        ),
      ),
    );
  }
}
