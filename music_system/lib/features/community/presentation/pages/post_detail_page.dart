import 'package:flutter/material.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/repositories/post_repository.dart';
import '../../../../injection_container.dart';
import '../widgets/artist_feed_card.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  final String currentUserId;

  const PostDetailPage({
    super.key,
    required this.postId,
    required this.currentUserId,
  });

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  PostEntity? _post;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  Future<void> _fetchPost() async {
    final result = await sl<PostRepository>().getPost(widget.postId);
    if (mounted) {
      result.fold(
        (failure) => setState(() {
          _error = failure.message;
          _isLoading = false;
        }),
        (post) => setState(() {
          _post = post;
          _isLoading = false;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Publicação'),
        backgroundColor: Colors.black,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.white)),
      );
    }

    if (_post == null) {
      return const Center(
        child: Text(
          'Publicação não encontrada',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return SingleChildScrollView(
      child: ArtistFeedCard(post: _post!, currentUserId: widget.currentUserId),
    );
  }
}
