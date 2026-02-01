import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gamer_flick/repositories/storage/storage_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final storageRepositoryProvider = Provider<IStorageRepository>((ref) {
  return SupabaseStorageRepository(Supabase.instance.client);
});
