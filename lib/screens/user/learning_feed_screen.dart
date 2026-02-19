import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smartlearn/models/reel_model.dart';
import 'package:smartlearn/models/game_model.dart';
import 'package:smartlearn/models/user_progress_model.dart';
import 'package:smartlearn/providers/auth_provider.dart';
import 'package:smartlearn/providers/content_provider.dart';
import 'package:smartlearn/providers/wallet_provider.dart';
import 'package:smartlearn/providers/user_provider.dart';
import 'package:smartlearn/utils/constants.dart';
import 'package:smartlearn/utils/lottie_animations.dart';
import 'package:smartlearn/widgets/inline_quiz.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:smartlearn/screens/user/wallet_screen.dart';
import 'package:smartlearn/games/space_blaster_game.dart';
import 'package:smartlearn/games/maze_of_minds_game.dart';
import 'package:smartlearn/games/skyfall_circuits_game.dart';
import 'package:smartlearn/games/door_decision_run_game.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:smartlearn/widgets/tip_bottom_sheet.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smartlearn/models/creator.dart';
import 'package:smartlearn/screens/user/creator_profile_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LearningFeedScreen extends StatefulWidget {
  final String courseId;
  final String conceptId;
  final List<ReelModel>? initialReels;
  final String? initialReelId;

  const LearningFeedScreen({
    super.key,
    required this.courseId,
    required this.conceptId,
    this.initialReels,
    this.initialReelId,
  });

  @override
  State<LearningFeedScreen> createState() => _LearningFeedScreenState();
}

class _LearningFeedScreenState extends State<LearningFeedScreen> {
  late PageController _verticalController;
  bool _isInit = true;
  String _currentConceptName = "";
  bool _showRewardAnimation = false;
  int _currentPageIndex = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _verticalController = PageController();

    // Configure audio to play nicely with background videos
    _audioPlayer.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.assistanceSonification,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadContent();
      });
      _isInit = false;
    }
  }

  Future<void> _loadContent() async {
    final contentProvider = Provider.of<ContentProvider>(
      context,
      listen: false,
    );
    final walletProvider = Provider.of<WalletProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Load content
    await contentProvider.fetchConceptsByCourse(widget.courseId);

    // Load wallet
    if (auth.currentUser != null) {
      await walletProvider.loadWallet(auth.currentUser!.uid);
    }

    if (contentProvider.currentCourseConcepts.isNotEmpty) {
      final concepts = contentProvider.currentCourseConcepts;
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      int targetIndex = 0;
      bool found = false;

      for (var concept in concepts) {
        if (concept.id == widget.conceptId) {
          found = true;
          break;
        }
        // Count pages before target concept
        targetIndex++; // Reel
        final status = userProvider.getConceptStatus(concept.name);
        if (status != AppConstants.conceptLearned) {
          targetIndex++; // Game
        }
      }

      if (found && _verticalController.hasClients) {
        _verticalController.jumpToPage(targetIndex);
        setState(() {
          _currentPageIndex = targetIndex;
          _currentConceptName = concepts
              .firstWhere((c) => c.id == widget.conceptId)
              .name;
        });
      }
    } else if (widget.initialReels != null && widget.initialReels!.isNotEmpty) {
      if (widget.initialReelId != null) {
        final index = widget.initialReels!.indexWhere(
          (r) => r.id == widget.initialReelId,
        );
        if (index != -1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_verticalController.hasClients) {
              _verticalController.jumpToPage(index);
              setState(() {
                _currentPageIndex = index;
                _currentConceptName = widget.initialReels![index].concept;
              });
            }
          });
        }
      }
    }
    setState(() {});
  }

  void _onGameSuccess() async {
    // 1. Show Reward Animation Overlay
    setState(() {
      _showRewardAnimation = true;
    });

    // Play earn sound from 3s to 6s
    try {
      await _audioPlayer.setSource(AssetSource('music/money-earn.mp3'));
      await _audioPlayer.seek(const Duration(seconds: 3));
      await _audioPlayer.resume();

      // Play for 3 seconds (from 3s to 6s in the file)
      await Future.delayed(const Duration(seconds: 3));
      await _audioPlayer.stop();
    } catch (e) {
      print("Error playing sound: $e");
    }

    // 2. Update Wallet/XP immediately (so it updates during animation)
    if (mounted) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.currentUser != null) {
        // Refresh wallet balance to show updated points
        await Provider.of<WalletProvider>(
          context,
          listen: false,
        ).refreshBalance(auth.currentUser!.uid);
        // Refresh user XP
        await Provider.of<UserProvider>(
          context,
          listen: false,
        ).addXP(0); // This just triggers a refresh if needed
      }
    }

    // 3. Animation duration is handled by the audio playback above (3 seconds)
    // No additional fixed delay needed as per user request to scroll right after audio segment.

    // 4. Hide Animation and Check Navigation
    if (mounted) {
      setState(() => _showRewardAnimation = false);

      // Check if we are already seeing the next concept due to list shift
      // (When concept is learned, the Game page is removed, shifting content up)
      final PageController controller = _verticalController;
      if (controller.hasClients) {
        int currentIndex = controller.page?.round() ?? 0;

        // Re-check current feed items to see what's at this index
        final contentProvider = Provider.of<ContentProvider>(
          context,
          listen: false,
        );
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final concepts = contentProvider.currentCourseConcepts;

        final List<Map<String, dynamic>> currentFeedItems = [];
        for (var concept in concepts) {
          currentFeedItems.add({'type': 'reel', 'concept': concept});
          final status = userProvider.getConceptStatus(concept.name);
          if (status != AppConstants.conceptLearned) {
            currentFeedItems.add({'type': 'game', 'concept': concept});
          }
        }

        // 5. Robust Auto Scroll: Find the REEL of the NEXT concept
        int targetPageIndex = -1;

        // Find the concept object matching _currentConceptName to get its ID/Index
        final int masterIndex = concepts.indexWhere(
          (c) => c.name == _currentConceptName,
        );

        if (masterIndex != -1 && masterIndex < concepts.length - 1) {
          // Target the next concept in the sequence
          final nextConcept = concepts[masterIndex + 1];
          targetPageIndex = currentFeedItems.indexWhere(
            (item) =>
                item['type'] == 'reel' && item['concept'].id == nextConcept.id,
          );
        }

        if (targetPageIndex != -1) {
          print(
            'DEBUG: Navigating to target reel index $targetPageIndex (Concept: ${currentFeedItems[targetPageIndex]['concept'].name})',
          );
          if (targetPageIndex != currentIndex) {
            _verticalController.animateToPage(
              targetPageIndex,
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeInOut,
            );
          } else {
            print('DEBUG: Already at target index $targetPageIndex (shifted).');
          }
        } else {
          print('DEBUG: No NEXT concept reel found. Course maybe finished?');
          // If no more concepts, maybe pop? Or stay on results.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Course completed! Great job!")),
          );
        }
      }
    }
  }

  void _onGameFail() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Score < 60%. Review the concept and try again!",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );

    // Auto scroll back to the reel page to re-learn
    if (_verticalController.hasClients) {
      _verticalController.previousPage(
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final contentProvider = Provider.of<ContentProvider>(context);
    List concepts = contentProvider.currentCourseConcepts;

    // Filter: Removed sublist to allow backward navigation (swipe down)
    // We handle the initial scroll in _loadContent
    if (contentProvider.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (concepts.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "No concepts found.",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Go Back"),
              ),
            ],
          ),
        ),
      );
    }

    final userProvider = Provider.of<UserProvider>(context);

    // Generate Feed Items dynamically
    final List<Map<String, dynamic>> feedItems = [];

    if (widget.initialReels != null && widget.initialReels!.isNotEmpty) {
      // Coming from a Profile grid: Just show requested reels
      for (var reel in widget.initialReels!) {
        feedItems.add({'type': 'reel', 'reel': reel, 'concept': null});
      }
    } else {
      for (var concept in concepts) {
        // Always add Reel Page
        feedItems.add({'type': 'reel', 'concept': concept});

        // Check status
        final status = userProvider.getConceptStatus(concept.name);
        final isLearned = status == AppConstants.conceptLearned;

        // Add Game Page ONLY if not learned
        if (!isLearned) {
          feedItems.add({'type': 'game', 'concept': concept});
        }
      }
    }

    if (feedItems.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("No content", style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          PageView.builder(
            controller: _verticalController,
            scrollDirection: Axis.vertical,
            physics: const ClampingScrollPhysics(), // Allow scrolling
            itemCount: feedItems.length,
            onPageChanged: (index) {
              final item = feedItems[index];
              setState(() {
                _currentPageIndex = index;
                _currentConceptName =
                    item['concept']?.name ?? item['reel']?.concept ?? "Video";
              });
            },
            itemBuilder: (context, index) {
              final item = feedItems[index];
              final concept = item['concept'];

              if (item['type'] == 'game') {
                return ConceptGamePage(
                  courseId: widget.courseId,
                  conceptId: concept.id,
                  conceptName: concept.name,
                  onSuccess: _onGameSuccess,
                  onFail: _onGameFail,
                  isActive: _currentPageIndex == index,
                );
              } else if (item['reel'] != null) {
                // Showing a direct reel from Profile
                return ReelItem(
                  reel: item['reel'],
                  conceptName: item['reel'].concept,
                  isActive: _currentPageIndex == index,
                );
              } else {
                return ConceptReelsPage(
                  conceptId: concept.id,
                  conceptName: concept.name,
                  isActive: _currentPageIndex == index,
                );
              }
            },
          ),

          // Top Header & Back Button
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black45,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Text(
                        _currentConceptName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Wallet Widget
                  Consumer<WalletProvider>(
                    builder: (context, walletProvider, _) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WalletScreen(),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          height: 40, // Reduced from 60
                          decoration: BoxDecoration(
                            color: Colors.black26, // Matched with topic
                            borderRadius: BorderRadius.circular(20), // Matched
                            border: Border.all(
                              color: Colors.white10,
                            ), // Matched
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "${walletProvider.balance}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16, // Reduced from 21
                                  letterSpacing: 1.1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 32, // Reduced from 58
                                height: 32, // Reduced from 58
                                child: LottieAnimations.load(
                                  LottieAnimations.walletBox,
                                  repeat: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Full Screen Reward Animation
          if (_showRewardAnimation)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: LottieAnimations.load(
                    LottieAnimations.coinShower,
                    repeat: false,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom Scroll Physics to allow scrolling UP but conditionalize scrolling DOWN
class DirectionalScrollPhysics extends ScrollPhysics {
  final bool canScrollDown;
  final bool canScrollUp;

  const DirectionalScrollPhysics({
    this.canScrollDown = true,
    this.canScrollUp = false,
    super.parent,
  });

  @override
  DirectionalScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return DirectionalScrollPhysics(
      canScrollDown: canScrollDown,
      canScrollUp: canScrollUp,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    // value < position.pixels means we are trying to scroll UP (to previous page)
    // value > position.pixels means we are trying to scroll DOWN (to next page)
    if (!canScrollUp && value < position.pixels) {
      return value - position.pixels;
    }
    if (!canScrollDown && value > position.pixels) {
      return value - position.pixels;
    }
    return super.applyBoundaryConditions(position, value);
  }
}

class ConceptReelsPage extends StatefulWidget {
  final String conceptId;
  final String conceptName;
  final bool isActive;

  const ConceptReelsPage({
    super.key,
    required this.conceptId,
    required this.conceptName,
    required this.isActive,
  });

  @override
  State<ConceptReelsPage> createState() => _ConceptReelsPageState();
}

class _ConceptReelsPageState extends State<ConceptReelsPage>
    with AutomaticKeepAliveClientMixin {
  List<ReelModel> _reels = [];
  bool _isLoading = true;
  late PageController _horizontalController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _horizontalController = PageController();
    _fetchReels();
  }

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  void _onBackFromGame() {
    if (_reels.length > 1 && _horizontalController.hasClients) {
      int nextReel = (_horizontalController.page?.round() ?? 0) + 1;
      if (nextReel >= _reels.length) nextReel = 0; // Loop back if at end

      _horizontalController.animateToPage(
        nextReel,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void didUpdateWidget(covariant ConceptReelsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If we just became active again, it might be because the user failed a game
    if (!oldWidget.isActive && widget.isActive) {
      _onBackFromGame();
    }
  }

  Future<void> _fetchReels() async {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final lang = auth.currentUser?.preferredLanguage ?? 'English';
    _reels = await provider.fetchReelsList(widget.conceptId, lang);
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_reels.isEmpty)
      return const Center(
        child: Text(
          "No videos available.",
          style: TextStyle(color: Colors.white),
        ),
      );

    return PageView.builder(
      controller: _horizontalController,
      scrollDirection: Axis.horizontal,
      itemCount: _reels.length,
      itemBuilder: (context, index) {
        return ReelItem(
          reel: _reels[index],
          conceptName: widget.conceptName,
          isActive: widget.isActive,
        );
      },
    );
  }
}

class ReelItem extends StatefulWidget {
  final ReelModel reel;
  final String conceptName;
  final bool isActive;

  const ReelItem({
    super.key,
    required this.reel,
    required this.conceptName,
    required this.isActive,
  });

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  // Common state
  bool _isYoutube = false;
  bool _isInitialized = false;
  bool _isFastForwarding = false;

  // VideoPlayer state
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  // Youtube state
  YoutubePlayerController? _youtubeController;

  // Creator Info
  String _creatorName = "Smart Learn";
  String? _creatorPhotoUrl;
  String _creatorAlgoAddress = "";

  // Interaction State
  bool _isLiked = false;
  int _likesCount = 0;
  int _sharesCount = 0;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _checkVideoType();
    _fetchCreatorInfo();
    _likesCount = widget.reel.likesCount;
    _sharesCount = widget.reel.sharesCount;
    _commentsCount = widget.reel.commentsCount;
  }

  Future<void> _fetchCreatorInfo() async {
    final creatorId = widget.reel.createdBy;
    if (creatorId.isEmpty || creatorId == 'unknown') {
      print('Creator ID is empty or unknown');
      return;
    }

    try {
      final snapshot = await FirebaseDatabase.instance
          .ref()
          .child(AppConstants.usersCollection)
          .child(creatorId)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        if (mounted) {
          setState(() {
            _creatorName = data['name'] ?? "Creator";
            _creatorPhotoUrl = data['photoUrl'];
            _creatorAlgoAddress = data['algoAddress'] ?? "";
          });
        }
      } else {
        print('User profile not found for ID: $creatorId');
      }
    } catch (e) {
      print("Error fetching creator info: $e");
    }
  }

  void _checkVideoType() {
    final youtubeId = YoutubePlayer.convertUrlToId(widget.reel.videoUrl);
    if (youtubeId != null) {
      _isYoutube = true;
      _initYoutube(youtubeId);
    } else {
      _isYoutube = false;
      _initPlayer();
    }
  }

  Future<void> _initYoutube(String videoId) async {
    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: YoutubePlayerFlags(
        autoPlay: widget.isActive,
        mute: false,
        loop: true,
        controlsVisibleAtStart: false,
        hideControls: true,
        disableDragSeek: true,
        enableCaption: false,
      ),
    );
    _isInitialized = true;
    if (mounted) setState(() {});
  }

  Future<void> _initPlayer() async {
    _videoController = VideoPlayerController.networkUrl(
      Uri.parse(widget.reel.videoUrl),
    );
    try {
      await _videoController!.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: widget.isActive,
        looping: true,
        showControls: false,
        aspectRatio: _videoController!.value.aspectRatio,
      );
      _isInitialized = true;
      if (widget.isActive && mounted) {
        _videoController!.play();
      }
    } catch (e) {
      print("Error initializing video player: $e");
    }
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      if (_isYoutube) {
        if (widget.isActive) {
          _youtubeController?.play();
        } else {
          _youtubeController?.pause();
        }
      } else {
        if (widget.isActive) {
          _videoController?.play();
        } else {
          _videoController?.pause();
        }
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  void _setPlaybackSpeed(double speed) {
    if (!_isInitialized) return;
    setState(() => _isFastForwarding = speed > 1.0);
    if (_isYoutube) {
      _youtubeController?.setPlaybackRate(speed);
    } else {
      _videoController?.setPlaybackSpeed(speed);
    }
  }

  void _navigateToProfile() {
    // Construct a temporary Creator object.
    // Balance is unknown here, so we pass 0.0. The profile screen fetches the latest.
    final creator = Creator(
      userId: widget
          .reel
          .createdBy, // passing ID as userId for now if name unavailable
      algoAddress: _creatorAlgoAddress,
      balance: 0.0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreatorProfileScreen(creator: creator)),
    );
  }

  void _handleLike() {
    setState(() {
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likesCount++;
      } else {
        _likesCount--;
      }
    });
    // TODO: Persist like to backend
  }

  void _handleShare() async {
    await Share.share(
      'Check out this cool concept "${widget.conceptName}" on Smart Learn! ${widget.reel.videoUrl}',
    );
    // Optimistically increment share count
    setState(() {
      _sharesCount++;
    });
    // TODO: Persist share count to backend
  }

  void _handleComment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Comments coming soon!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return GestureDetector(
      onLongPressStart: (_) => _setPlaybackSpeed(2.0),
      onLongPressEnd: (_) => _setPlaybackSpeed(1.0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full Screen Video
          SizedBox.expand(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _isYoutube
                    ? MediaQuery.of(context).size.width
                    : _videoController!.value.size.width,
                height: _isYoutube
                    ? MediaQuery.of(context).size.height
                    : _videoController!.value.size.height,
                child: _isYoutube
                    ? YoutubePlayer(
                        controller: _youtubeController!,
                        showVideoProgressIndicator: false,
                      )
                    : VideoPlayer(_videoController!),
              ),
            ),
          ),
          _buildSpeedIndicator(),
          _buildSpeedIndicator(),
          _buildInfoOverlay(),
          _buildRightActions(),
          _buildProgressBar(),
        ],
      ),
    );
  }

  Widget _buildSpeedIndicator() {
    if (!_isFastForwarding) return const SizedBox();
    return const Center(
      child: Icon(Icons.fast_forward, color: Colors.white, size: 50),
    );
  }

  Widget _buildProgressBar() {
    if (_isYoutube || _videoController == null) return const SizedBox();
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: VideoProgressIndicator(
        _videoController!,
        allowScrubbing: true,
        colors: const VideoProgressColors(playedColor: Colors.blueAccent),
      ),
    );
  }

  Widget _buildInfoOverlay() {
    return Positioned(
      bottom: 20, // Moved lower
      left: 16,
      right: 100, // Space for right actions
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Creator Info & Tip Button Row
          Row(
            children: [
              GestureDetector(
                onTap: _navigateToProfile,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.white,
                      backgroundImage: _creatorPhotoUrl != null
                          ? CachedNetworkImageProvider(_creatorPhotoUrl!)
                          : null,
                      child: _creatorPhotoUrl == null
                          ? Text(
                              _creatorName[0],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _creatorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Tip Button (Small, next to name)
              GestureDetector(
                onTap: () {
                  if (_creatorAlgoAddress.isNotEmpty) {
                    _showTipSheet();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'This creator has not set up a wallet yet.',
                        ),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _creatorAlgoAddress.isNotEmpty
                        ? Colors.pinkAccent
                        : Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "Tip",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Concept Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              "Start with ${widget.conceptName}",
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.reel.concept, // Display text
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              shadows: [Shadow(color: Colors.black, blurRadius: 4)],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildRightActions() {
    return Positioned(
      bottom: 40,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Like Button
          GestureDetector(
            onTap: _handleLike,
            child: Column(
              children: [
                Icon(
                  _isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _isLiked ? Colors.red : Colors.white,
                  size: 35,
                ),
                const SizedBox(height: 4),
                Text(
                  "$_likesCount",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Comment Button
          GestureDetector(
            onTap: _handleComment,
            child: _buildActionIcon(
              Icons.chat_bubble_outline,
              "$_commentsCount",
            ),
          ),
          const SizedBox(height: 20),

          // Share Button
          GestureDetector(
            onTap: _handleShare,
            child: _buildActionIcon(Icons.share, "$_sharesCount"),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
      ],
    );
  }

  void _showTipSheet() async {
    if (_creatorAlgoAddress.isEmpty) {
      await _fetchCreatorInfo();
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => TipBottomSheet(
        creatorId: widget.reel.createdBy,
        toAddress: _creatorAlgoAddress,
        creatorName: _creatorName,
      ),
    );
  }
}

class ConceptGamePage extends StatefulWidget {
  final String courseId;
  final String conceptId;
  final String conceptName;
  final VoidCallback onSuccess;
  final VoidCallback onFail;
  final bool isActive;

  const ConceptGamePage({
    super.key,
    required this.courseId,
    required this.conceptId,
    required this.conceptName,
    required this.onSuccess,
    required this.onFail,
    required this.isActive,
  });

  @override
  State<ConceptGamePage> createState() => _ConceptGamePageState();
}

class _ConceptGamePageState extends State<ConceptGamePage>
    with AutomaticKeepAliveClientMixin {
  GameModel? _game;
  bool _isLoading = true;
  bool _hasAwardedPoints = false; // Track if points were already awarded
  int _gameTypeIndex = 0; // 0: InlineQuiz, 1-6: New Games

  @override
  bool get wantKeepAlive => true; // Keep state to avoid reloading quiz

  @override
  void initState() {
    super.initState();
    _gameTypeIndex = Random().nextInt(5);
    _fetchGame();
  }

  Future<void> _fetchGame() async {
    final provider = Provider.of<ContentProvider>(context, listen: false);
    // Fetch easy game by default
    final games = await provider.fetchGamesList(widget.conceptId, 'easy');
    if (games.isNotEmpty) {
      _game = games.first; // Or random?
    }
    // Reset the flag when a new game is loaded
    _hasAwardedPoints = false;
    setState(() => _isLoading = false);
  }

  void _handleFinish(int score) async {
    print('DEBUG: _handleFinish called with score: $score');
    if (score == -1) {
      print('DEBUG: Score is -1, calling onFail');
      widget.onFail();
      return;
    }

    print(
      'DEBUG: Checking if score >= minPassingScore ($score >= ${AppConstants.minPassingScore})',
    );
    if (score >= AppConstants.minPassingScore) {
      // Save progress
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final contentProvider = Provider.of<ContentProvider>(
        context,
        listen: false,
      );
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final walletProvider = Provider.of<WalletProvider>(
        context,
        listen: false,
      );

      if (auth.currentUser != null && !_hasAwardedPoints) {
        final uid = auth.currentUser!.uid;
        print(
          'DEBUG: User authenticated, uid: $uid, hasAwardedPoints: $_hasAwardedPoints',
        );
        print(
          'DEBUG: About to award wallet points for concept: ${widget.conceptName}',
        );

        // 1. Save detailed attempt to analytics
        await contentProvider.saveTestAttempt(
          UserProgress(
            id: '',
            userId: uid,
            courseId: widget.courseId,
            conceptId: widget.conceptId,
            reelId: '',
            gameId: _game?.id ?? '',
            concept: widget.conceptName,
            gameCompleted: true,
            score: score,
            accuracy: score,
            timeTaken: 0,
            completedAt: DateTime.now(),
            conceptStatus: AppConstants.conceptLearned,
          ),
        );

        // 2. Update global concept status as learned
        await userProvider.updateConceptProgress(
          widget.conceptName,
          AppConstants.conceptLearned,
        );

        // 3. Award XP points
        int xpToAward = AppConstants.xpPerEasyGame;
        if (_game?.difficultyLevel == AppConstants.difficultyMedium) {
          xpToAward = AppConstants.xpPerMediumGame;
        }
        if (_game?.difficultyLevel == AppConstants.difficultyHard) {
          xpToAward = AppConstants.xpPerHardGame;
        }
        await userProvider.addXP(xpToAward);

        // 4. Award wallet points (one time only)
        // 4. Award wallet points (one time only)
        print('DEBUG: Calling awardLessonPoints...');
        final success = await walletProvider.awardLessonPoints(
          uid,
          widget.conceptName,
        );
        if (success) {
          print('DEBUG: awardLessonPoints success');
        } else {
          print(
            'DEBUG: awardLessonPoints FAILED. Error: ${walletProvider.errorMessage}',
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to add points: ${walletProvider.errorMessage}',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 5),
              ),
            );
          }
        }

        // Mark as awarded to prevent duplicate awards
        _hasAwardedPoints = true;
        print('DEBUG: Points awarded, calling onSuccess');
      } else {
        print(
          'DEBUG: Skipping point award - user: ${auth.currentUser != null}, hasAwarded: $_hasAwardedPoints',
        );
      }
      widget.onSuccess();
    } else {
      widget.onFail();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_game == null) {
      return Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "No quiz available for this concept.",
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: widget.onSuccess,
                child: const Text("Skip to Next"),
              ), // Allow skip if missing
            ],
          ),
        ),
      );
    }

    return Container(color: Colors.black87, child: _buildRandomGame());
  }

  Widget _buildRandomGame() {
    // Check if the current game content is compatible with mini-games (MCQ/True-False)
    final type = _game!.gameType;
    bool isSimpleQuiz =
        type == AppConstants.gameTypeQuestLearn ||
        type == AppConstants.gameTypeBrainBattle ||
        type == AppConstants.gameTypeTimeRush ||
        type == AppConstants.gameTypeMasteryBoss ||
        type == AppConstants.gameTypeMysteryMind ||
        type == AppConstants.gameTypeLevelUp;

    // Use random fancy game only for simple quiz types
    if (isSimpleQuiz && _gameTypeIndex != 0) {
      switch (_gameTypeIndex) {
        case 1:
          return SpaceBlasterGame(
            game: _game!,
            onFinished: _handleFinish,
            isActive: widget.isActive,
          );
        case 2:
          return MazeOfMindsGame(
            game: _game!,
            onFinished: _handleFinish,
            isActive: widget.isActive,
          );
        case 3:
          return SkyfallCircuitsGame(
            game: _game!,
            onFinished: _handleFinish,
            isActive: widget.isActive,
          );
        case 4:
          return DoorDecisionRunGame(
            game: _game!,
            onFinished: _handleFinish,
            isActive: widget.isActive,
          );
      }
    }

    // Default to InlineQuiz for complex game types (ordering, matching, word connect)
    // or if the random index picked the standard quiz.
    return InlineQuiz(
      game: _game!,
      onFinished: _handleFinish,
      isActive: widget.isActive,
    );
  }
}
