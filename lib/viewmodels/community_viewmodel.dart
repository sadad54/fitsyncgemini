import 'package:flutter/material.dart';
import '../models/community_model.dart';
import '../services/community_service.dart';

class CommunityViewModel extends ChangeNotifier {
  final CommunityService _communityService = CommunityService();

  CommunityModel? _communityData;
  bool _isLoading = false;
  String? _error;

  CommunityModel? get communityData => _communityData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadCommunityData() async {
    _setLoading(true);
    try {
      _communityData = await _communityService.getCommunityData();
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> togglePostLike(int postId) async {
    try {
      await _communityService.togglePostLike(postId);
      // Update local state
      if (_communityData != null) {
        final postIndex = _communityData!.posts.indexWhere(
          (p) => p.id == postId,
        );
        if (postIndex != -1) {
          final post = _communityData!.posts[postIndex];
          final updatedPost = post.copyWith(
            liked: !post.liked,
            likes: post.liked ? post.likes - 1 : post.likes + 1,
          );
          _communityData!.posts[postIndex] = updatedPost;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> joinChallenge(int challengeId) async {
    try {
      await _communityService.joinChallenge(challengeId);
      // Refresh community data to get updated participant count
      await loadCommunityData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createPost(
    String imageUrl,
    String caption,
    String? challengeId,
  ) async {
    try {
      await _communityService.createPost(
        imageUrl: imageUrl,
        caption: caption,
        challengeId: challengeId,
      );
      // Refresh community data to show new post
      await loadCommunityData();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
