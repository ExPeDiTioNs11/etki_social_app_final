import 'package:flutter/material.dart';
import '../models/story.dart';
import 'story_circle.dart';

class StoryList extends StatelessWidget {
  final List<Story> stories;
  final Function(Story)? onStoryTap;

  const StoryList({
    super.key,
    required this.stories,
    this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 100,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: stories.length,
        itemBuilder: (context, index) {
          final story = stories[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: StoryCircle(
              story: story,
              onTap: () => onStoryTap?.call(story),
            ),
          );
        },
      ),
    );
  }
} 