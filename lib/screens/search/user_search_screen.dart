import 'package:flutter/material.dart';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({super.key});

  @override
  State<UserSearchScreen> createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  String searchQuery = '';
  String selectedDepartment = 'All Departments';
  String selectedStatus = 'All Status';
  bool isGrid = true;

 
  final List<Map<String, dynamic>> users = [
    {
      'name': 'Sarah Johnson',
      'role': 'Product Manager',
      'email': 'sarah.johnson@example.com',
      'phone': '+1 (555) 123-4567',
      'location': 'San Francisco, CA',
      'joined': '1/15/2023',
      'status': 'active',
      'skills': ['Product Strategy', 'User Research', 'Agile'],
      'avatar': null,
      'games': ['Valorant', 'League of Legends'],
    },
    {
      'name': 'Michael Chen',
      'role': 'Senior Developer',
      'email': 'michael.chen@example.com',
      'phone': '+1 (555) 987-6543',
      'location': 'New York, NY',
      'joined': '8/20/2022',
      'status': 'active',
      'skills': ['React', 'Node.js', 'TypeScript'],
      'avatar': null,
      'games': ['CS:GO', 'Dota 2'],
    },
    {
      'name': 'Emily Rodriguez',
      'role': 'UX Designer',
      'email': 'emily.rodriguez@example.com',
      'phone': '+1 (555) 456-7890',
      'location': 'Austin, TX',
      'joined': '3/10/2023',
      'status': 'active',
      'skills': ['Figma', 'User Testing', 'Prototyping'],
      'avatar': null,
      'games': ['Overwatch', 'Apex Legends'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredUsers = users.where((user) {
      final query = searchQuery.toLowerCase();
      return user['name'].toLowerCase().contains(query) ||
          user['email'].toLowerCase().contains(query) ||
          user['role'].toLowerCase().contains(query) ||
          (user['skills'] as List<String>)
              .any((s) => s.toLowerCase().contains(query)) ||
          (user['games'] as List<String>)
              .any((g) => g.toLowerCase().contains(query));
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_alt_outlined,
                      size: 36, color: Colors.blueAccent),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Search Users',
                          style: TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Find and connect with gamers across the platform',
                          style:
                              TextStyle(fontSize: 15, color: Colors.black54)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText:
                            'Search by name, email, role, skills, or games...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 16),
                      ),
                      onChanged: (val) => setState(() => searchQuery = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<String>(
                    value: selectedDepartment,
                    items: [
                      'All Departments',
                      'Development',
                      'Design',
                      'Product'
                    ]
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => selectedDepartment = val!),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedStatus,
                    items: ['All Status', 'Active', 'Offline']
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) => setState(() => selectedStatus = val!),
                  ),
                  const SizedBox(width: 12),
                  ToggleButtons(
                    isSelected: [isGrid, !isGrid],
                    onPressed: (i) => setState(() => isGrid = i == 0),
                    borderRadius: BorderRadius.circular(8),
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('Grid'),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('List'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('${filteredUsers.length} users found',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 16),
              Expanded(
                child: isGrid
                    ? GridView.count(
                        crossAxisCount: 3,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 1.5,
                        children: filteredUsers
                            .map((user) => _buildUserCard(user))
                            .toList(),
                      )
                    : ListView.separated(
                        itemCount: filteredUsers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, i) =>
                            _buildUserCard(filteredUsers[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                child: user['avatar'] == null
                    ? const Icon(Icons.person, size: 32, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(user['name'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(width: 8),
                        if (user['status'] == 'active')
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('active',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                      ],
                    ),
                    Text(user['role'],
                        style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              const Icon(Icons.more_vert, color: Colors.black38),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.email_outlined, size: 18, color: Colors.black45),
              const SizedBox(width: 6),
              Text(user['email'], style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.phone_outlined, size: 18, color: Colors.black45),
              const SizedBox(width: 6),
              Text(user['phone'], style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 18, color: Colors.black45),
              const SizedBox(width: 6),
              Text(user['location'], style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: Colors.black45),
              const SizedBox(width: 6),
              Text('Joined ${user['joined']}',
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Skills', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ...((user['skills'] as List<String>).map((s) => Chip(
                    label: Text(s),
                    backgroundColor: Colors.grey.shade100,
                  ))),
              ...((user['games'] as List<String>).map((g) => Chip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.sports_esports,
                            size: 16, color: Colors.blueAccent),
                        SizedBox(width: 4),
                        Text(g),
                      ],
                    ),
                    backgroundColor: Colors.blue.shade50,
                  ))),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Message'),
                  onPressed: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View Profile'),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
