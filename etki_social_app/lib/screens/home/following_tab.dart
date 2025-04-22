import 'package:flutter/material.dart';
import '../../models/post_model.dart';
import '../../models/story.dart';
import '../../widgets/post_card.dart';
import '../../widgets/story_list.dart';

class FollowingTab extends StatelessWidget {
  final List<Post> posts;
  final List<Story> stories;
  final Function(Post)? onLike;
  final Function(Post)? onComment;
  final Function(Post)? onShare;
  final Function(Story)? onStoryTap;

  const FollowingTab({
    super.key,
    required this.posts,
    required this.stories,
    this.onLike,
    this.onComment,
    this.onShare,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        // TODO: Implement refresh for following tab
      },
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: StoryList(
              stories: stories,
              onStoryTap: onStoryTap,
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final post = posts[index];
                return PostCard(
                  post: post,
                  onLike: () => onLike?.call(post),
                  onComment: () => onComment?.call(post),
                  onShare: () => onShare?.call(post),
                );
              },
              childCount: posts.length,
            ),
          ),
        ],
      ),
    );
  }
} 