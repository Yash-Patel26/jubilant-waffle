import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class TournamentCreationScreen extends StatefulWidget {
  const TournamentCreationScreen({super.key});

  @override
  _TournamentCreationScreenState createState() =>
      _TournamentCreationScreenState();
}

class _TournamentCreationScreenState extends State<TournamentCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // Tournament Details
  String _name = '';
  String _gameId = '';
  String _gameName = '';
  String _type = 'solo'; // 'solo' or 'team'
  DateTime? _startDate;
  DateTime? _endDate;
  String _rules = '';
  String _prize = '';
  int _maxParticipants = 16;
  double _entryFee = 0.0;
  String? _description;

  // Games List - Using the same games as game_selection_screen.dart
  final List<Map<String, dynamic>> _games = [
    {
      'id': 'bgmi',
      'name': 'BGMI',
      'image_url':
          'https://upload.wikimedia.org/wikipedia/en/thumb/6/63/Battleground_Mobile_India.webp/240px-Battleground_Mobile_India.webp.png',
      'description': 'Battlegrounds Mobile India',
      'genre': 'Battle Royale',
    },
    {
      'id': 'valorant',
      'name': 'Valorant',
      'image_url':
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Valorant_logo_-_pink_color_version.svg/1280px-Valorant_logo_-_pink_color_version.svg.png',
      'description': 'Tactical FPS Game',
      'genre': 'Tactical FPS',
    },
    {
      'id': 'apex-legends',
      'name': 'Apex Legends',
      'image_url':
          'https://encrypted-tbn3.gstatic.com/images?q=tbn:ANd9GcTb3m_BWQxdS_09torGZNfNx6rLwPG0KJLZmN4hXASgPTGHP8B3',
      'description': 'Battle Royale Shooter',
      'genre': 'Battle Royale',
    },
    {
      'id': 'pubg-mobile',
      'name': 'PUBG Mobile',
      'image_url':
          'https://upload.wikimedia.org/wikipedia/en/thumb/4/44/PlayerUnknown%27s_Battlegrounds_Mobile.webp/180px-PlayerUnknown%27s_Battlegrounds_Mobile.webp.png',
      'description': 'Battle Royale Mobile',
      'genre': 'Battle Royale',
    },
    {
      'id': 'free-fire',
      'name': 'Free Fire',
      'image_url':
          'https://upload.wikimedia.org/wikipedia/commons/9/9a/Free_fire.jpg',
      'description': 'Survival Shooter',
      'genre': 'Battle Royale',
    },
    {
      'id': 'call-of-duty',
      'name': 'Call of Duty',
      'image_url':
          'https://upload.wikimedia.org/wikipedia/en/7/7c/Call_Of_Duty_%282003%29%2CCover%2CUpdated.jpg',
      'description': 'First Person Shooter',
      'genre': 'FPS',
    },
  ];

  @override
  void initState() {
    super.initState();
    // No need to fetch games from database since we're using hardcoded games
  }

  Future<void> _createDefaultRoles(String tournamentId, String userId) async {
    try {
      final ownerRole = {
        'tournament_id': tournamentId,
        'user_id': userId,
        'role': 'owner',
        'permissions': {
          'can_manage_roles': true,
          'can_post_announcements': true,
          'can_moderate_chat': true,
          'can_manage_media': true,
          'can_update_bracket': true,
        }
      };
      await Supabase.instance.client.from('tournament_roles').insert(ownerRole);
    } catch (e) {
      // If tournament_roles table doesn't exist, continue without roles
      print('Warning: Could not create tournament roles: $e');
    }
  }

  Future<void> _createTournament() async {
    if (!_formKey.currentState!.validate()) return;

    // Save form data
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Create tournament
      final tournamentData = {
        'name': _name,
        'game': _gameName,
        'description': _description ?? '',
        'type': _type,
        'start_date': _startDate?.toIso8601String(),
        'end_date': _endDate?.toIso8601String(),
        'rules': _rules,
        'prize_pool': _prize,
        'max_participants': _maxParticipants,
        'created_by': user.id,
        'status': 'upcoming',
      };

      final result = await Supabase.instance.client
          .from('tournaments')
          .insert(tournamentData)
          .select()
          .single();

      // Create default roles for the tournament
      await _createDefaultRoles(result['id'], user.id);

      // Add creator as participant
      await Supabase.instance.client.from('tournament_participants').insert({
        'tournament_id': result['id'],
        'user_id': user.id,
        'joined_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tournament Created Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(result['id']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating tournament: $e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Tournament'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        actions: [],
      ),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _createTournament();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) {
              setState(() => _currentStep--);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : details.onStepContinue,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _currentStep == 3 ? 'Create Tournament' : 'Next'),
                    ),
                  ),
                ],
              ),
            );
          },
          steps: [
            // Step 1: Basic Information
            Step(
              title: const Text('Basic Information'),
              content: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Tournament Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a tournament name';
                      }
                      return null;
                    },
                    onSaved: (value) => _name = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Game',
                      border: OutlineInputBorder(),
                      hintText: 'Select a game for your tournament',
                    ),
                    value: _gameId.isEmpty ? null : _gameId,
                    items: _games.map<DropdownMenuItem<String>>((game) {
                      return DropdownMenuItem<String>(
                        value: game['id'] as String,
                        child: Text(game['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      final selectedGame = _games.firstWhere(
                          (g) => g['id'] == value,
                          orElse: () => {});
                      setState(() {
                        _gameId = value ?? '';
                        _gameName = selectedGame['name'] ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a game';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Solo'),
                          value: 'solo',
                          groupValue: _type,
                          onChanged: (value) {
                            setState(() => _type = value!);
                          },
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          title: const Text('Team'),
                          value: 'team',
                          groupValue: _type,
                          onChanged: (value) {
                            setState(() => _type = value!);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Step 2: Dates and Rules
            Step(
              title: const Text('Dates & Rules'),
              content: Column(
                children: [
                  ListTile(
                    title: const Text('Start Date & Time'),
                    subtitle: Text(
                      _startDate != null
                          ? DateFormat('MMM dd, yyyy - HH:mm')
                              .format(_startDate!)
                          : 'Select start date',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate:
                            DateTime.now().add(const Duration(days: 1)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setState(() {
                            _startDate = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                  ListTile(
                    title: const Text('End Date (Optional)'),
                    subtitle: Text(
                      _endDate != null
                          ? DateFormat('MMM dd, yyyy').format(_endDate!)
                          : 'Select end date',
                    ),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _startDate ??
                            DateTime.now().add(const Duration(days: 2)),
                        firstDate: _startDate ?? DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => _endDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Rules',
                      border: OutlineInputBorder(),
                      hintText: 'Enter tournament rules...',
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter tournament rules';
                      }
                      return null;
                    },
                    onSaved: (value) => _rules = value ?? '',
                  ),
                ],
              ),
            ),
            // Step 3: Prize and Participants
            Step(
              title: const Text('Prize & Participants'),
              content: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Prize Details',
                      border: OutlineInputBorder(),
                      hintText: 'e.g., \$1000 First Place, \$500 Second Place',
                    ),
                    maxLines: 3,
                    onSaved: (value) => _prize = value ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Max Participants',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _maxParticipants.toString(),
                    validator: (value) {
                      final num = int.tryParse(value ?? '');
                      if (num == null || num < 2) {
                        return 'Please enter a valid number (minimum 2)';
                      }
                      return null;
                    },
                    onSaved: (value) =>
                        _maxParticipants = int.parse(value ?? '16'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Entry Fee (Optional)',
                      border: OutlineInputBorder(),
                      prefixText: '\$',
                    ),
                    keyboardType: TextInputType.number,
                    initialValue: _entryFee.toString(),
                    onSaved: (value) =>
                        _entryFee = double.tryParse(value ?? '0') ?? 0.0,
                  ),
                ],
              ),
            ),
            // Step 4: Review
            Step(
              title: const Text('Review'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReviewItem('Name', _name),
                  _buildReviewItem('Game', _gameName),
                  _buildReviewItem('Type',
                      _type == 'solo' ? 'Solo Tournament' : 'Team Tournament'),
                  _buildReviewItem(
                      'Start Date',
                      _startDate != null
                          ? DateFormat('MMM dd, yyyy - HH:mm')
                              .format(_startDate!)
                          : 'Not set'),
                  if (_endDate != null)
                    _buildReviewItem('End Date',
                        DateFormat('MMM dd, yyyy').format(_endDate!)),
                  _buildReviewItem(
                      'Max Participants', _maxParticipants.toString()),
                  if (_entryFee > 0)
                    _buildReviewItem(
                        'Entry Fee', '\$${_entryFee.toStringAsFixed(2)}'),
                  if (_prize.isNotEmpty) _buildReviewItem('Prize', _prize),
                  _buildReviewItem('Rules', _rules),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
