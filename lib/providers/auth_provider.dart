import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authStateProvider = StreamProvider<User?>((ref) {
  // authStateChanges yerine userChanges kullanarak profil güncellemelerini de dinliyoruz
  return ref.watch(firebaseAuthProvider).userChanges();
});

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {
    // Initial state is null / empty
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(firebaseAuthProvider).signInWithEmailAndPassword(
            email: email,
            password: password,
          );
    });
  }

  Future<void> register(String email, String password, {String? displayName}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final credential = await ref.read(firebaseAuthProvider).createUserWithEmailAndPassword(
            email: email,
            password: password,
          );
      // Kullanıcı adını kaydet
      if (displayName != null && displayName.isNotEmpty && credential.user != null) {
        await credential.user!.updateDisplayName(displayName);
        await credential.user!.reload();
      }
    });
  }

  Future<void> updateProfileName(String newName) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final user = ref.read(firebaseAuthProvider).currentUser;
      if (user != null) {
        await user.updateDisplayName(newName);
        // Firebase Auth lokal state'ini yeniler
        await user.reload(); 
        
        // ÖNEMLİ: userChanges() her zaman anında tetiklenmeyebilir.
        // UI'ın (HomeScreen, ProfileScreen) anında yeni ismi görmesi için 
        // authStateProvider'ı geçersiz kılıp yeniden okumasını zorluyoruz.
        ref.invalidate(authStateProvider);
      }
    });
  }

  Future<void> signOut() async {
    await ref.read(firebaseAuthProvider).signOut();
  }
}

final authNotifierProvider =
    AsyncNotifierProvider<AuthNotifier, void>(() => AuthNotifier());
