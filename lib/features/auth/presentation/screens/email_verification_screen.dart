import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firebase_providers.dart';
import '../providers/auth_providers.dart';

class EmailVerificationScreen extends ConsumerWidget {
  const EmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('E-posta Doğrulama')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.mark_email_unread_outlined, size: 72),
            const SizedBox(height: 24),
            const Text(
              'Hesabınızı doğrulamak için e-postanıza gönderilen bağlantıya tıklayın.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      await ref
                          .read(firebaseAuthProvider)
                          .currentUser
                          ?.sendEmailVerification();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Doğrulama e-postası gönderildi'),
                          ),
                        );
                      }
                    },
              child: authState.isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tekrar Gönder'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: authState.isLoading
                  ? null
                  : () async {
                      final verified = await ref
                          .read(authControllerProvider.notifier)
                          .syncEmailVerification();
                      if (!context.mounted) return;
                      if (verified) {
                        context.go('/complete-profile');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'E-posta henüz doğrulanmamış. Gelen kutunuzu kontrol edin.',
                            ),
                          ),
                        );
                      }
                    },
              child: const Text('Doğruladım, Devam Et'),
            ),
          ],
        ),
      ),
    );
  }
}
