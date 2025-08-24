// This service has been replaced by Supabase storage operations
// All Firebase Storage operations should now use Supabase storage
// See lib/services/supabase_service.dart for uploadImage method

class StorageService {
  // This service is deprecated - use Supabase storage instead
  static void showDeprecationWarning() {
    print('⚠️ StorageService is deprecated. Use Supabase storage instead.');
  }
}
