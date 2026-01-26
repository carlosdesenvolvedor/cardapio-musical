import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../auth/domain/entities/user_profile.dart';
import '../../../auth/data/models/user_profile_model.dart';

class UserSelectorDialog extends StatefulWidget {
  final String title;
  final List<String> selectedIds;
  final bool multiple;

  const UserSelectorDialog({
    super.key,
    required this.title,
    this.selectedIds = const [],
    this.multiple = true,
  });

  @override
  State<UserSelectorDialog> createState() => _UserSelectorDialogState();
}

class _UserSelectorDialogState extends State<UserSelectorDialog> {
  final _searchController = TextEditingController();
  List<UserProfile> _searchResults = [];
  final List<UserProfile> _selectedUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Poderíamos carregar os perfis já selecionados se necessário
  }

  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('artisticName', isGreaterThanOrEqualTo: query)
          .where('artisticName', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(10)
          .get();

      setState(() {
        _searchResults = snapshot.docs
            .map((doc) => UserProfileModel.fromJson(doc.data(), doc.id))
            .toList();
      });
    } catch (e) {
      debugPrint('Error searching users: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar artista...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _searchUsers,
            ),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    final isSelected =
                        _selectedUsers.any((u) => u.id == user.id);

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: user.photoUrl != null
                            ? NetworkImage(user.photoUrl!)
                            : null,
                        child: user.photoUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      title: Text(user.artisticName),
                      trailing: Checkbox(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              if (!widget.multiple) _selectedUsers.clear();
                              _selectedUsers.add(user);
                            } else {
                              _selectedUsers
                                  .removeWhere((u) => u.id == user.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedUsers),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5B80B),
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
