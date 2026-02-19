import 'package:flutter/material.dart';
import 'package:smartlearn/models/creator.dart';
import 'package:smartlearn/services/api_service.dart';
import 'package:smartlearn/services/content_service.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlearn/models/reel_model.dart';
import 'package:smartlearn/models/post_model.dart';
import 'package:smartlearn/models/course_model.dart';
import 'package:smartlearn/screens/user/learning_feed_screen.dart';
import 'package:smartlearn/widgets/tip_bottom_sheet.dart';
import 'package:intl/intl.dart';

/// Shows a single creator's profile with options to tip them.
class CreatorProfileScreen extends StatefulWidget {
  final Creator creator;

  const CreatorProfileScreen({super.key, required this.creator});

  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen>
    with SingleTickerProviderStateMixin {
  late double _currentBalance;
  String _creatorAlgoAddress = '';
  String _creatorName = '';
  String? _creatorPhotoUrl;
  String _creatorBio = 'Digital Creator | Educator';
  int _postsCount = 0;
  int _coursesCount = 0;
  List<ReelModel> _reels = [];
  List<CourseModel> _courses = [];
  List<PostModel> _allPosts = [];
  late TabController _tabController;
  final ContentService _contentService = ContentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _currentBalance = widget.creator.balance;
    _creatorName = widget.creator.name ?? widget.creator.userId;
    _creatorPhotoUrl = widget.creator.photoUrl;
    _creatorBio = widget.creator.bio ?? 'Digital Creator | Educator';
    _creatorAlgoAddress = widget.creator.algoAddress;

    _fetchUserProfile();
    _fetchCreatorStats();
    _fetchLatestBalance();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child(AppConstants.usersCollection)
          .child(widget.creator.userId)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        if (mounted) {
          setState(() {
            _creatorName = data['name'] ?? widget.creator.userId;
            _creatorPhotoUrl = data['photoUrl'];
            _creatorBio = data['bio'] ?? 'Digital Creator | Educator';
            _creatorAlgoAddress =
                data['algoAddress'] ?? widget.creator.algoAddress;
          });
        }
      }
    } catch (e) {
      print('Error fetching user profile: $e');
    }
  }

  Future<void> _fetchCreatorStats() async {
    try {
      final database = FirebaseDatabase.instance.ref();

      // Fetch Reels
      final reelsSnapshot = await database
          .child(AppConstants.reelsCollection)
          .orderByChild('createdBy')
          .equalTo(widget.creator.userId)
          .get();

      final List<ReelModel> fetchedReels = [];
      if (reelsSnapshot.exists && reelsSnapshot.value != null) {
        final Map<dynamic, dynamic> data = reelsSnapshot.value as Map;
        data.forEach((key, value) {
          fetchedReels.add(
            ReelModel.fromMap(
              Map<String, dynamic>.from(value as Map),
              key.toString(),
            ),
          );
        });
        fetchedReels.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      // Fetch Courses
      final creatorCourses = await _contentService.getCoursesByCreator(
        widget.creator.userId,
      );

      // Fetch Posts
      final creatorPosts = await _contentService.getPostsByCreator(
        widget.creator.userId,
      );

      if (mounted) {
        setState(() {
          _reels = fetchedReels;
          _courses = creatorCourses;
          _allPosts = creatorPosts;
          _postsCount = _reels.length + _allPosts.length;
          _coursesCount = _courses.length;
        });
      }
    } catch (e) {
      print('Error fetching creator stats: $e');
    }
  }

  Future<void> _fetchLatestBalance() async {
    try {
      final balanceData = await ApiService.getBalance(widget.creator.userId);
      if (mounted) {
        setState(() {
          _currentBalance = (balanceData['balance'] as num).toDouble();
        });
      }
    } catch (e) {
      print('Error fetching latest balance: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: Colors.blueAccent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Reels'),
                  Tab(text: 'Courses'),
                  Tab(text: 'Gallery'),
                  Tab(text: 'Blogs'),
                  Tab(text: 'Music'),
                ],
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildReelsGrid(),
                _buildCoursesGrid(),
                _buildGalleryGrid(),
                _buildBlogsList(),
                _buildMusicList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const Spacer(),
              const Icon(Icons.more_vert, color: Colors.white),
            ],
          ),
          const SizedBox(height: 10),
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.blueAccent.withOpacity(0.2),
            backgroundImage: _creatorPhotoUrl != null
                ? CachedNetworkImageProvider(_creatorPhotoUrl!)
                : NetworkImage(
                        'https://picsum.photos/seed/${widget.creator.userId}/200',
                      )
                      as ImageProvider,
            child: null,
          ),
          const SizedBox(height: 16),
          Text(
            _creatorName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _creatorBio,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Coins Earned',
                '${(_currentBalance * AppConstants.coinsPerAlgo).toInt()}',
              ),
              Container(height: 40, width: 1, color: Colors.grey[800]),
              _buildStatItem('Posts', '$_postsCount'),
              Container(height: 40, width: 1, color: Colors.grey[800]),
              _buildStatItem('Courses', '$_coursesCount'),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => _showTipSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'Support Creator',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showTipSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TipBottomSheet(
        creatorId: widget.creator.userId,
        toAddress: _creatorAlgoAddress,
        creatorName: _creatorName,
        onTipSent: (amount) {
          // Refresh creator's balance
          _fetchLatestBalance();
          final coins = (amount * AppConstants.coinsPerAlgo).toInt();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Thank you! Your support of $coins coins was successful.',
              ),
            ),
          );
        },
      ),
    ).then((_) {
      // This .then() is called when the bottom sheet is dismissed.
      // _fetchLatestBalance() is already called in onTipSent, so no need to call it again here
      // unless we want to refresh even if no tip was sent (e.g., user just closed it).
      // For now, let's rely on onTipSent for balance refresh.
    });
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      ],
    );
  }

  Widget _buildReelsGrid() {
    if (_reels.isEmpty) return _buildEmptyState('No reels yet');

    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
        childAspectRatio: 0.7,
      ),
      itemCount: _reels.length,
      itemBuilder: (context, index) {
        final reel = _reels[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => LearningFeedScreen(
                  courseId: reel.courseId,
                  conceptId: reel.conceptId,
                  initialReels: _reels,
                  initialReelId: reel.id,
                ),
              ),
            );
          },
          child: Container(
            color: Colors.grey[900],
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: reel.thumbnailUrl ?? '',
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey[900]),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                const Positioned(
                  bottom: 4,
                  right: 4,
                  child: Icon(Icons.play_arrow, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCoursesGrid() {
    if (_courses.isEmpty) return _buildEmptyState('No courses yet');

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: _courses.length,
      itemBuilder: (context, index) {
        final course = _courses[index];
        return Card(
          color: Colors.grey[900],
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CachedNetworkImage(
                  imageUrl: course.thumbnailUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  course.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGalleryGrid() {
    final images = _allPosts.where((p) => p.type == 'image').toList();
    if (images.isEmpty) return _buildEmptyState('No images yet');

    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: images[index].content,
          fit: BoxFit.cover,
        );
      },
    );
  }

  Widget _buildBlogsList() {
    final blogs = _allPosts.where((p) => p.type == 'blog').toList();
    if (blogs.isEmpty) return _buildEmptyState('No blogs yet');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: blogs.length,
      itemBuilder: (context, index) {
        final blog = blogs[index];
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  blog.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  blog.content,
                  style: TextStyle(color: Colors.grey[400]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(blog.createdAt),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMusicList() {
    final music = _allPosts
        .where((p) => p.type == 'audio' || p.type == 'video')
        .toList();
    if (music.isEmpty) return _buildEmptyState('No music or videos yet');

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: music.length,
      itemBuilder: (context, index) {
        final item = music[index];
        return ListTile(
          leading: const Icon(
            Icons.play_circle_fill,
            color: Colors.blueAccent,
            size: 40,
          ),
          title: Text(item.title, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            DateFormat('MMM dd, yyyy').format(item.createdAt),
            style: TextStyle(color: Colors.grey[600]),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(message, style: TextStyle(color: Colors.grey[600])),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: Colors.black, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return _tabBar != oldDelegate._tabBar;
  }
}
