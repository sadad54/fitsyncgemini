import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fitsyncgemini/models/clothing_item.dart';
import 'package:fitsyncgemini/models/outfit.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// This service has been replaced by SupabaseService
// All Firestore operations should now use Supabase database operations
// See lib/services/supabase_service.dart for the current implementation

class FirestoreService {
  // This service is deprecated - use SupabaseService instead
  static void showDeprecationWarning() {
    print('⚠️ FirestoreService is deprecated. Use SupabaseService instead.');
  }
}

// Provider
final firestoreServiceProvider = Provider((ref) => FirestoreService());
