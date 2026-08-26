import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'safe_firestore.dart';

mixin SchoolRepositoryAuth {
  FirebaseAuth get auth;
  GoogleSignIn get googleSignIn;
  FirebaseFirestore get firestore;
  String? get uid => auth.currentUser?.uid;

  Stream<User?> authState() => auth.authStateChanges();

  Future<void> signOut() async {
    await googleSignIn.signOut();
    await auth.signOut();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream() {
    final userId = uid;
    if (userId == null) return const Stream.empty();
    return firestore.collection('users').doc(userId).safeSnapshots();
  }

  Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
    String? firstName,
    String? lastName,
  }) async {
    final userId = uid;
    if (userId == null) return;
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (avatarUrl != null) updates['avatarUrl'] = avatarUrl;
    if (firstName != null) updates['firstName'] = firstName;
    if (lastName != null) updates['lastName'] = lastName;
    if (updates.isNotEmpty) {
      await firestore.collection('users').doc(userId).update(updates);
    }
  }

  Future<Map<String, dynamic>> resolveUserCached(String userId) async {
    final data = await getUserData(userId);
    return data ?? {'name': 'Unknown User'};
  }

  Future<void> updateActivity() async {
    final userId = uid;
    if (userId == null) return;

    final ref = firestore.collection('users').doc(userId);
    final doc = await ref.get();
    final data = doc.data() ?? {};

    final lastActivity = data['lastActivity'] as Timestamp?;
    int streak = data['streak'] as int? ?? 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (lastActivity != null) {
      final last = lastActivity.toDate();
      final lastDay = DateTime(last.year, last.month, last.day);

      final diff = today.difference(lastDay).inDays;
      if (diff == 1) {
        streak += 1;
      } else if (diff > 1) {
        streak = 1;
      }
    } else {
      streak = 1;
    }

    await ref.update({
      'lastActivity': FieldValue.serverTimestamp(),
      'streak': streak,
    });
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    return auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<UserCredential> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    final cred = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user != null) {
      await Future.wait([
        user.updateDisplayName(name),
        // New accounts remain pending until the user joins a class or submits
        // a teacher request in onboarding. This matches phone registration
        // and prevents a blank class dashboard on first launch.
        createProfile(uid: user.uid, name: name, role: 'pending', email: email),
      ]);
    }
    return cred;
  }

  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    return auth.signInWithCredential(credential);
  }

  Future<void> createProfile({
    String? uid,
    required String name,
    required String role,
    String? email,
    String? phone,
  }) async {
    final effectiveUid = uid ?? this.uid;
    if (effectiveUid == null) return;
    final ref = firestore.collection('users').doc(effectiveUid);
    final existing = await ref.get();
    final existingRole = existing.data()?['role']?.toString() ?? '';
    final shouldSetInitialRole = !existing.exists || existingRole.isEmpty;
    final shouldPromotePendingProfile =
        existingRole == 'pending' && role == 'student';
    await ref.set({
      'name': name.trim(),
      if (!existing.exists && email != null)
        'email': email.trim().toLowerCase(),
      if (!existing.exists && phone != null) 'phone': phone.trim(),
      if (shouldSetInitialRole || shouldPromotePendingProfile) 'role': role,
      if (!existing.exists) 'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Checks the contact-email lookup used by parent/teacher linking before a
  /// phone-authenticated user stores it on their profile.
  Future<bool> isProfileEmailAvailable(
    String email, {
    String? excludeUserId,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return true;

    final matches = await firestore
        .collection('users')
        .where('email', isEqualTo: normalized)
        .limit(2)
        .get();
    return matches.docs.every((doc) => doc.id == excludeUserId);
  }

  Future<void> updateProfileName(String name) async {
    final user = auth.currentUser;
    if (user == null) return;
    await Future.wait([
      user.updateDisplayName(name),
      firestore.collection('users').doc(user.uid).update({'name': name}),
    ]);
  }

  Future<void> deleteUserAccount(String userId) async {
    // 1. Delete user document from Firestore directly
    await firestore.collection('users').doc(userId).delete();

    // 2. Try calling backend service to clean up Auth account if available
    try {
      const proxyUrl = String.fromEnvironment(
        'GOOGLE_DRIVE_PROXY_URL',
        defaultValue: 'https://vercel-talentum-backend.vercel.app',
      );
      if (proxyUrl.isNotEmpty) {
        final idToken = await auth.currentUser?.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          final dio = Dio();
          await dio.post(
            '$proxyUrl/api/auth/delete_user',
            data: {'userId': userId},
            options: Options(headers: {'Authorization': 'Bearer $idToken'}),
          );
        }
      }
    } catch (_) {
      // Backend proxy API optional; Firestore user doc is already deleted.
    }
  }

  Future<void> verifyPhone({
    required String phoneNumber,
    required PhoneCodeSent codeSent,
    required PhoneVerificationFailed verificationFailed,
    required PhoneVerificationCompleted verificationCompleted,
  }) async {
    await auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<UserCredential> signInWithPhoneCredential({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return auth.signInWithCredential(credential);
  }

  Future<ConfirmationResult> signInWithPhoneNumberWeb(
    String phoneNumber, {
    RecaptchaVerifier? verifier,
  }) {
    if (verifier != null) {
      return auth.signInWithPhoneNumber(phoneNumber, verifier);
    }
    return auth.signInWithPhoneNumber(phoneNumber);
  }
}
