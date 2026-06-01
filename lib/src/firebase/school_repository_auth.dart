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
        createProfile(uid: user.uid, name: name, role: 'student', email: email),
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
  }) async {
    final effectiveUid = uid ?? this.uid;
    if (effectiveUid == null) return;
    await firestore.collection('users').doc(effectiveUid).set({
      'name': name,
      'role': role,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });
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
    const apiSecret = String.fromEnvironment('APP_API_SECRET');
    const proxyUrl = String.fromEnvironment('GOOGLE_DRIVE_PROXY_URL');
    if (proxyUrl.isEmpty) {
      throw Exception('Backend GOOGLE_DRIVE_PROXY_URL is not configured. Please run with --dart-define=GOOGLE_DRIVE_PROXY_URL=...');
    }
    if (apiSecret.isEmpty) {
      throw Exception('Backend APP_API_SECRET is not configured. Please run with --dart-define=APP_API_SECRET=...');
    }

    final dio = Dio();
    final res = await dio.post(
      '$proxyUrl/api/auth/delete_user',
      data: {'userId': userId},
      options: Options(
        headers: {
          'Authorization': 'Bearer $apiSecret',
        },
      ),
    );

    if (res.statusCode != 200) {
      throw Exception('Failed to delete user: ${res.data}');
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
}
