import 'package:amour_chat/model/auth_model.dart';
import 'package:amour_chat/service/auth.dart';
import 'package:amour_chat/service/firestore_service.dart';
import 'package:amour_chat/service/navigation_service.dart';
import 'package:amour_chat/ui/screens/chatScreen.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final GetIt _getIt = GetIt.instance;
  late FirestoreService _firestoreService;
  late NavigattionService _navigationService;
  late Authservice _authservice;

  final TextEditingController _searchController = TextEditingController();
  List<String> _searchHistory = [];
  UserProfile? _searchResult;
  bool _isSearching = false;
  bool _showHistory = true;

  @override
  void initState() {
    super.initState();
    _firestoreService = _getIt.get<FirestoreService>();
    _navigationService = _getIt.get<NavigattionService>();
    _authservice = _getIt.get<Authservice>();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchHistory(String email) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(email);
    _searchHistory.insert(0, email);
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    await prefs.setStringList('search_history', _searchHistory);
    setState(() {});
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _searchHistory.clear();
    });
  }

  Future<void> _searchUser(String email) async {
    if (email.trim().isEmpty) return;

    setState(() {
      _isSearching = true;
      _showHistory = false;
      _searchResult = null;
    });

    try {
      final result = await _firestoreService.searchUserByEmail(email.trim());
      setState(() {
        _searchResult = result;
        _isSearching = false;
      });

      if (result != null) {
        await _saveSearchHistory(email.trim());
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _navigateToChat(UserProfile userProfile) async {
    final chatExists = await _firestoreService.CheckChatExists(
      _authservice.user!.uid,
      userProfile.uid!,
    );

    if (!chatExists) {
      await _firestoreService.createChat(
        _authservice.user!.uid,
        userProfile.uid!,
      );
    }

    _navigationService.push(
      MaterialPageRoute(
        builder: (context) => chatScreen(userProfile: userProfile),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.teal.shade700,
        title: const Text(
          "Search Users",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _showHistory ? _buildSearchHistory() : _buildSearchResult(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search by email...',
          prefixIcon: const Icon(Icons.email_outlined),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchResult = null;
                _showHistory = true;
              });
            },
          )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.teal.shade700, width: 2),
          ),
        ),
        onChanged: (value) {
          setState(() {});
        },
        onSubmitted: _searchUser,
      ),
    );
  }

  Widget _buildSearchHistory() {
    if (_searchHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Search for users by email',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _clearHistory,
                icon: const Icon(Icons.delete_outline, size: 20),
                label: const Text('Clear'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _searchHistory.length,
            itemBuilder: (context, index) {
              final email = _searchHistory[index];
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(email),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  _searchController.text = email;
                  _searchUser(email);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResult() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResult == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No user found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Card(
        margin: const EdgeInsets.all(20),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: NetworkImage(_searchResult!.pfpURL!),
                backgroundColor: Colors.teal.shade100,
              ),
              const SizedBox(height: 20),
              Text(
                _searchResult!.name!,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _searchController.text,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _navigateToChat(_searchResult!),
                icon: const Icon(Icons.chat),
                label: const Text('Start Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}