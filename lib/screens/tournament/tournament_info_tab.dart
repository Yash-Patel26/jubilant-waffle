import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gamer_flick/services/tournament/tournament_service.dart';
import '../../widgets/tournament/tournament_overview_card.dart';
import '../../widgets/tournament/prize_pool_card.dart';
import '../../widgets/tournament/tournament_rules_card.dart';
import '../../widgets/tournament/recent_participants_card.dart';

class TournamentInfoTab extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final bool isOwnerOrMod;
  final VoidCallback? onUpdated;

  const TournamentInfoTab({
    super.key,
    required this.tournament,
    required this.isOwnerOrMod,
    this.onUpdated,
  });

  @override
  _TournamentInfoTabState createState() => _TournamentInfoTabState();
}

class _TournamentInfoTabState extends State<TournamentInfoTab> {
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _prizeController;
  late TextEditingController _rulesController;
  DateTime? _startDate;
  DateTime? _endDate;

  bool get _isOwner {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return false;
    return widget.tournament['created_by'] == user.id;
  }

  @override
  void initState() {
    super.initState();
    _prizeController =
        TextEditingController(text: widget.tournament['prize_details'] ?? '');
    _rulesController =
        TextEditingController(text: widget.tournament['rules'] ?? '');
    _startDate = widget.tournament['start_date'] != null
        ? DateTime.parse(widget.tournament['start_date'])
        : null;
    _endDate = widget.tournament['end_date'] != null
        ? DateTime.parse(widget.tournament['end_date'])
        : null;
  }

  @override
  void dispose() {
    _prizeController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.from('tournaments').update({
        'prize_details': _prizeController.text,
        'rules': _rulesController.text,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
      }).eq('id', widget.tournament['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tournament updated successfully!')),
        );
        setState(() => _isEditing = false);
        widget.onUpdated?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating tournament: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(bool isStartDate) async {
    final currentDate = isStartDate ? _startDate : _endDate;
    final date = await showDatePicker(
      context: context,
      initialDate: currentDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: currentDate != null
            ? TimeOfDay.fromDateTime(currentDate)
            : TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          if (isStartDate) {
            _startDate = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          } else {
            _endDate = DateTime(
              date.year,
              date.month,
              date.day,
              time.hour,
              time.minute,
            );
          }
        });
      }
    }
  }

  Future<void> _deleteTournament() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tournament'),
        content: const Text(
          'Are you sure you want to delete this tournament? This action cannot be undone and will permanently remove all tournament data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      setState(() => _isLoading = true);

      await TournamentService().deleteTournament(widget.tournament['id']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate deletion
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting tournament: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tournament = widget.tournament;
    final participants = tournament['participants'] as List? ?? [];
    final rules = tournament['rules'] ?? '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24).copyWith(bottom: 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TournamentOverviewCard(tournament: tournament),
                    PrizePoolCard(tournament: tournament),
                    RecentParticipantsCard(participants: participants),
                    TournamentRulesCard(rules: rules),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left column
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TournamentOverviewCard(tournament: tournament),
                          TournamentRulesCard(rules: rules),
                        ],
                      ),
                    ),
                    const SizedBox(width: 32),
                    // Right column
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          PrizePoolCard(tournament: tournament),
                          RecentParticipantsCard(participants: participants),
                        ],
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildInfoSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 28.0),
          child: content,
        ),
      ],
    );
  }

  Color _getStatusColor() {
    final status = widget.tournament['status'] as String?;
    switch (status?.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
