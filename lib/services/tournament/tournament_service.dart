import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/services/core/network_service.dart';
import 'package:gamer_flick/services/core/error_reporting_service.dart';

class TournamentService {
  static final TournamentService _instance = TournamentService._internal();
  factory TournamentService() => _instance;
  TournamentService._internal();

  /// Deletes a tournament. Only the tournament owner can delete it.
  ///
  /// [tournamentId] - The ID of the tournament to delete
  /// Returns true if deletion was successful, false otherwise
  Future<bool> deleteTournament(String tournamentId) async {
    return NetworkService().executeWithRetry(
      operationName: 'TournamentService.deleteTournament',
      operation: () async {
        try {
          final user = Supabase.instance.client.auth.currentUser;
          if (user == null) {
            throw Exception('User not authenticated');
          }

          // First, verify that the current user is the tournament owner
          final tournament = await Supabase.instance.client
              .from('tournaments')
              .select('created_by')
              .eq('id', tournamentId)
              .single();

          if (tournament['created_by'] != user.id) {
            throw Exception(
                'Only the tournament owner can delete this tournament');
          }

          // Check if tournament has started or has participants
          final tournamentDetails = await Supabase.instance.client
              .from('tournaments')
              .select('status, participants:tournament_participants(count)')
              .eq('id', tournamentId)
              .single();

          final participantCount =
              tournamentDetails['participants']?[0]?['count'] ?? 0;
          final status = tournamentDetails['status'];

          // Prevent deletion if tournament has started or has participants
          if (status == 'ongoing' || status == 'completed') {
            throw Exception(
                'Cannot delete a tournament that has already started or completed');
          }

          if (participantCount > 0) {
            throw Exception(
                'Cannot delete a tournament that has participants. Please remove all participants first.');
          }

          // Delete related data in the correct order
          await Supabase.instance.client
              .from('tournament_roles')
              .delete()
              .eq('tournament_id', tournamentId);

          await Supabase.instance.client
              .from('tournament_matches')
              .delete()
              .eq('tournament_id', tournamentId);

          await Supabase.instance.client
              .from('tournament_teams')
              .delete()
              .eq('tournament_id', tournamentId);

          await Supabase.instance.client
              .from('tournament_participants')
              .delete()
              .eq('tournament_id', tournamentId);

          await Supabase.instance.client
              .from('tournament_media')
              .delete()
              .eq('tournament_id', tournamentId);

          await Supabase.instance.client
              .from('tournaments')
              .delete()
              .eq('id', tournamentId);

          return true;
        } catch (e) {
          ErrorReportingService().reportError(
            'Failed to delete tournament: $e',
            null,
            context: 'TournamentService.deleteTournament',
            additionalData: {'tournamentId': tournamentId},
          );
          rethrow;
        }
      },
    );
  }

  /// Checks if the current user is the owner of a tournament
  ///
  /// [tournamentId] - The ID of the tournament to check
  /// Returns true if the current user is the owner, false otherwise
  Future<bool> isTournamentOwner(String tournamentId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      final tournament = await Supabase.instance.client
          .from('tournaments')
          .select('created_by')
          .eq('id', tournamentId)
          .single();

      return tournament['created_by'] == user.id;
    } catch (e) {
      rethrow;
    }
  }

  /// Gets the current user's role in a tournament
  ///
  /// [tournamentId] - The ID of the tournament
  /// Returns the role name or null if user is not a participant
  Future<String?> getUserRole(String tournamentId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final role = await Supabase.instance.client
          .from('tournament_roles')
          .select('role')
          .eq('tournament_id', tournamentId)
          .eq('user_id', user.id)
          .single();

      return role['role'];
    } catch (e) {
      // User might not have a role assigned yet
      return null;
    }
  }

  /// Removes a participant from a tournament. Only the owner can do this.
  Future<void> removeParticipant(String tournamentId, int participantId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if current user is the owner
    final tournament = await Supabase.instance.client
        .from('tournaments')
        .select('created_by')
        .eq('id', tournamentId)
        .single();
    if (tournament['created_by'] != user.id) {
      throw Exception('Only the tournament owner can remove participants');
    }

    // Remove the participant
    await Supabase.instance.client
        .from('tournament_participants')
        .delete()
        .eq('id', participantId);
  }

  /// Fetches upcoming tournaments with enhanced data
  ///
  /// [limit] - Maximum number of tournaments to fetch (default: 5)
  /// Returns a list of upcoming tournaments with participant counts
  Future<List<Map<String, dynamic>>> getUpcomingTournaments(
      {int limit = 5}) async {
    return NetworkService().executeWithRetry(
      operationName: 'TournamentService.getUpcomingTournaments',
      operation: () async {
        try {
          final response = await Supabase.instance.client
              .from('tournaments')
              .select('''
                *,
                creator:profiles!tournaments_created_by_fkey(username, avatar_url),
                participants:tournament_participants(count)
              ''')
              .eq('status', 'upcoming')
              .gte('start_date', DateTime.now().toIso8601String())
              .order('start_date', ascending: true)
              .limit(limit);

          return (response as List)
              .map((tournament) => Map<String, dynamic>.from({
                    ...tournament,
                    'participant_count':
                        tournament['participants']?[0]?['count'] ?? 0,
                  }))
              .toList();
        } catch (e) {
          ErrorReportingService().reportError(
            'Failed to fetch upcoming tournaments: $e',
            null,
            context: 'TournamentService.getUpcomingTournaments',
          );
          return [];
        }
      },
    );
  }

  /// Fetches tournaments by status
  ///
  /// [status] - Tournament status ('upcoming', 'ongoing', 'completed')
  /// [limit] - Maximum number of tournaments to fetch (default: 10)
  /// Returns a list of tournaments with the specified status
  Future<List<Map<String, dynamic>>> getTournamentsByStatus(String status,
      {int limit = 10}) async {
    return NetworkService().executeWithRetry(
      operationName: 'TournamentService.getTournamentsByStatus',
      operation: () async {
        try {
          final response = await Supabase.instance.client
              .from('tournaments')
              .select('''
                *,
                creator:profiles!tournaments_created_by_fkey(username, avatar_url),
                participants:tournament_participants(count)
              ''')
              .eq('status', status)
              .order('start_date', ascending: true)
              .limit(limit);

          return (response as List)
              .map((tournament) => Map<String, dynamic>.from({
                    ...tournament,
                    'participant_count':
                        tournament['participants']?[0]?['count'] ?? 0,
                  }))
              .toList();
        } catch (e) {
          ErrorReportingService().reportError(
            'Failed to fetch tournaments by status: $e',
            null,
            context: 'TournamentService.getTournamentsByStatus',
            additionalData: {'status': status},
          );
          return [];
        }
      },
    );
  }
}
