import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserGateService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Returns TRUE if the profile is complete.
  /// Returns FALSE if any required field is missing.
  Future<bool> isProfileComplete() async {
    User? user = _auth.currentUser;

    // 1. Safety check: If not logged in, they can't be complete.
    if (user == null) return false;

    try {
      // 2. Fetch the user document
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();

      // 3. If document doesn't exist at all
      if (!doc.exists) return false;

      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      if (data == null) return false;

      // 4. Check the specific fields
      String? firstName = data['firstName'];
      String? faculty = data['faculty'];
      String? studyProgram = data['studyProgram'];

      // 5. The Rule: All three must exist and not be empty strings
      bool hasName = firstName != null && firstName.isNotEmpty;
      bool hasFaculty = faculty != null && faculty.isNotEmpty;
      bool hasProdi = studyProgram != null && studyProgram.isNotEmpty;

      return hasName && hasFaculty && hasProdi;

    } catch (e) {
      print("Error checking profile: $e");
      return false; // Fail safe
    }
  }
}
