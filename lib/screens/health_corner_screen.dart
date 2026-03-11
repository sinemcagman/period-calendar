import 'package:flutter/material.dart';
import '../database/db_helper.dart';
import '../models/blog_post.dart';
import '../constants/app_strings.dart';
import '../constants/app_colors.dart';

class HealthCornerScreen extends StatefulWidget {
  const HealthCornerScreen({super.key});

  @override
  State<HealthCornerScreen> createState() => _HealthCornerScreenState();
}

class _HealthCornerScreenState extends State<HealthCornerScreen> {
  List<BlogPost> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('blog_posts');
    setState(() {
      _posts = res.map((m) => BlogPost.fromMap(m)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
         child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          AppStrings.healthCornerTitle,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          AppStrings.healthCornerSubtitle,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryDark),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: AppColors.textSecondaryDark),
                      onPressed: () {},
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        shape: const CircleBorder(),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Featured
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      AppStrings.featured,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      AppStrings.seeAll.toUpperCase(),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brandPink),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  height: 200,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _posts.isNotEmpty ? 2 : 0, 
                    itemBuilder: (context, index) {
                      return _buildFeaturedCard(_posts[index], index == 1 ? const Color(0xFF9D50BB) : AppColors.brandPink);
                    },
                  ),
                ),
                
                const SizedBox(height: 32),

                // List Section
                const Text(
                  AppStrings.otherTopics,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                if (_posts.length > 2)
                  ..._posts.sublist(2).map((post) => _buildListItem(post)),
                  
                const SizedBox(height: 32),
                
                // Quick Tip
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.brandPink.withValues(alpha: 0.2), 
                        const Color(0xFF9D50BB).withValues(alpha: 0.2)
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('💡', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.dailyTip.toUpperCase(),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.brandPink, letterSpacing: 1.5),
                          )
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Magnezyum açısından zengin besinler (muz, bitter çikolata gibi) kramp şiddetini azaltmaya yardımcı olabilir.",
                        style: TextStyle(fontSize: 14, height: 1.5, color: Colors.white70),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 48),
              ],
            )
         )
      ),
    );
  }

  Widget _buildFeaturedCard(BlogPost post, Color tagColor) {
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(8),
        image: DecorationImage(
          image: NetworkImage(post.imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: tagColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                post.category,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              post.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListItem(BlogPost post) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(post.imageUrl),
                fit: BoxFit.cover,
              )
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  post.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryDark),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      AppStrings.readTime.replaceAll('{min}', post.readTime.toString()),
                      style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('•', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
                    ),
                    const Text(
                      AppStrings.newBadge,
                      style: TextStyle(fontSize: 10, color: AppColors.brandPink, fontWeight: FontWeight.bold),
                    )
                  ],
                )
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textSecondaryDark)
        ],
      ),
    );
  }
}
