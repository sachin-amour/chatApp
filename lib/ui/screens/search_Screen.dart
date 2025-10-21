import 'package:amour_chat/myconstent/colors.dart';
import 'package:amour_chat/others/user_model.dart';
import 'package:amour_chat/ui/screens/Chat_Screen.dart';
import 'package:amour_chat/ui/services/authServices.dart';
import 'package:amour_chat/ui/services/dbServices.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  List<String> _searchHistory = [];
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Load search history from SharedPreferences
  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList('search_history') ?? [];
    setState(() {
      _searchHistory = history;
    });
  }

  // Save search history to SharedPreferences
  Future<void> _saveSearchHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    if (!_searchHistory.contains(query)) {
      _searchHistory.insert(0, query);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.sublist(0, 10);
      }
      await prefs.setStringList('search_history', _searchHistory);
    }
  }

  // Delete entire search history
  Future<void> _deleteSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _searchHistory.clear();
    });
  }

  // Delete single history item
  Future<void> _deleteHistoryItem(String item) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory.remove(item);
    });
    await prefs.setStringList('search_history', _searchHistory);
  }

  // Search for users by email
  void _onSearchChanged() async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      // Get current user ID from Firebase Auth
      final currentUserId = AuthService().getCurrentUserId();

      if (currentUserId == null) {
        setState(() {
          _searchResults.clear();
          _isSearching = false;
        });
        return;
      }

      final users = await _databaseService.fetchUsers(currentUserId);

      if (users != null) {
        final results = users
            .where((user) {
              final email = user['email']?.toString().toLowerCase() ?? '';
              return email.contains(query.toLowerCase());
            })
            .map((user) => UserModel.fromMap(user))
            .toList();

        setState(() {
          _searchResults = results;
        });
      }
    } catch (e) {
      print('Error searching users: $e');
      setState(() {
        _searchResults.clear();
      });
    }
  }

  // Navigate to chat screen
  // Navigate to chat screen
  void _navigateToChat(UserModel user) {
    final currentUserId = AuthService().getCurrentUserId();

    if (currentUserId == null) {
      // Handle the case where the current user ID is not available (e.g., user not logged in)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Current user not logged in.')),
      );
      return;
    }

    _saveSearchHistory(_searchController.text);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          user: user,
          currentUserId: currentUserId, // PASS THE REQUIRED PARAMETER
        ),
      ),
    );
  }

  // Handle history item tap
  void _onHistoryTap(String query) {
    _searchController.text = query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.white),

        title: Text('Search Users', style: TextStyle(color: Colors.white)),
        backgroundColor: basecolor,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchResults.clear();
                            _isSearching = false;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              autofocus: true,
            ),
          ),

          // Search History or Search Results
          Expanded(
            child: _isSearching ? _buildSearchResults() : _buildSearchHistory(),
          ),
        ],
      ),
    );
  }

  // Build search results
  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No users found',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: user.imageUrl != null
                ? NetworkImage(user.imageUrl!)
                : null,
            child: user.imageUrl == null
                ? Text(user.name?[0].toUpperCase() ?? 'U')
                : null,
          ),
          title: Text(user.name ?? 'Unknown'),
          subtitle: Text(user.email ?? ''),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () => _navigateToChat(user),
        );
      },
    );
  }

  // Build search history
  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No search history',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              TextButton.icon(
                onPressed: _deleteSearchHistory,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Clear All'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final query = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(query),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => _deleteHistoryItem(query),
                ),
                onTap: () => _onHistoryTap(query),
              );
            },
          ),
        ),
      ],
    );
  }
}
