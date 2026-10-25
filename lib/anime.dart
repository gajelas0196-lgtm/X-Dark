import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- Global Constants for Theming ---
const Color kPrimaryColor = Color(0xFF00D4AA); // Biru (Untuk UI element)
const Color kMutedWhite = Color(0xFFD4D4D4); // Putih redup (Untuk tulisan & icon)
const Color kBackgroundColor = Color(0xFF090E14);
const Color kCardColor = Color(0xFF111820);
const Color kHighlightColor = Color(0xFF1A2535);

class HomeAnimePage extends StatefulWidget {
  const HomeAnimePage({super.key});

  @override
  State<HomeAnimePage> createState() => _HomeAnimePageState();
}

class _HomeAnimePageState extends State<HomeAnimePage> {
  Map<String, dynamic>? animeData;
  bool isLoading = true;
  bool isSearching = false;
  List<dynamic> searchResults = [];
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _watchHistory = [];
  bool _isHistoryLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAnimeData();
    _loadWatchHistory();
  }

  void refreshHistory() {
    _loadWatchHistory();
  }

  Future<void> _loadWatchHistory() async {
    setState(() => _isHistoryLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('watch_history') ?? [];
      setState(() {
        _watchHistory = historyJson.map((item) => Map<String, dynamic>.from(json.decode(item))).toList();
        _isHistoryLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading watch history: $e');
      setState(() => _isHistoryLoading = false);
    }
  }

  Future<void> fetchAnimeData() async {
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/home'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          animeData = jsonData['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed');
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> searchAnime(String query) async {
    if (query.isEmpty) {
      setState(() { isSearching = false; searchResults.clear(); });
      return;
    }
    setState(() => isSearching = true);
    try {
      final response = await http.get(Uri.parse('https://www.sankavollerei.com/anime/search/$query'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() => searchResults = jsonData['data']['animeList'] ?? []);
      } else {
        setState(() => searchResults = []);
      }
    } catch (e) {
      debugPrint('Search Error: $e');
      setState(() => searchResults = []);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() { isSearching = false; searchResults.clear(); });
    _searchFocusNode.unfocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        backgroundColor: kBackgroundColor,
        elevation: 0,
        title: const Text('Tempat Wibu', style: TextStyle(fontWeight: FontWeight.bold, color: kMutedWhite, fontFamily: "Rajdhani")),
        actions: [
          IconButton(icon: const Icon(Icons.account_circle, color: kMutedWhite), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              style: const TextStyle(color: Colors.white, fontFamily: "Rajdhani"),
              decoration: InputDecoration(
                hintText: "Search anime...",
                hintStyle: const TextStyle(color: Colors.grey, fontFamily: "Rajdhani"),
                prefixIcon: const Icon(Icons.search, color: kMutedWhite),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear, color: kMutedWhite), onPressed: _clearSearch)
                    : null,
                filled: true,
                fillColor: kCardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: const BorderSide(color: kPrimaryColor)),
              ),
              onChanged: (value) {
                if (value.isNotEmpty) { searchAnime(value); } 
                else { setState(() { isSearching = false; searchResults.clear(); }); }
              },
            ),
          ),
          Expanded(
            child: isLoading
                ? _buildLoadingShimmer()
                : isSearching
                    ? _buildSearchResults()
                    : animeData == null
                        ? Center(child: Text("Failed to load", style: TextStyle(color: Colors.grey, fontFamily: "Rajdhani")))
                        : _buildHomeContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: () async { await Future.wait([fetchAnimeData(), _loadWatchHistory()]); },
      color: kPrimaryColor,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.history, "Watch History"),
            const SizedBox(height: 12),
            if (_isHistoryLoading)
              const Center(child: CircularProgressIndicator(color: kPrimaryColor))
            else if (_watchHistory.isEmpty)
              Container(
                height: 100, alignment: Alignment.center,
                decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(8)),
                child: const Text("No history yet", style: TextStyle(color: Colors.grey, fontFamily: "Rajdhani")),
              )
            else
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _watchHistory.length,
                  itemBuilder: (context, index) {
                    final anime = _watchHistory[index];
                    return _buildHistoryCard(anime);
                  },
                ),
              ),
            _buildSectionHeader(Icons.dashboard, "Quick Access"),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildQuickAccessCard("Genre", Icons.category, () { Navigator.push(context, MaterialPageRoute(builder: (context) => const AnimeGenreListPage())).then((_) => refreshHistory()); })),
                const SizedBox(width: 12),
                Expanded(child: _buildQuickAccessCard("Schedule", Icons.schedule, () { Navigator.push(context, MaterialPageRoute(builder: (context) => const AnimeSchedulePage())).then((_) => refreshHistory()); })),
              ],
            ),
            const SizedBox(height: 24),
            _buildSectionHeader(Icons.live_tv, "Currently Airing"),
            const SizedBox(height: 12),
            _buildAnimeGrid(animeData!['ongoing']['animeList'] ?? []),
            const SizedBox(height: 24),
            _buildSectionHeader(Icons.check_circle, "Completed Series"),
            const SizedBox(height: 12),
            _buildAnimeGrid(animeData!['completed']['animeList'] ?? []),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(children: [
      Icon(icon, color: kMutedWhite, size: 24),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kMutedWhite, fontFamily: "Rajdhani")),
    ]);
  }

  Widget _buildHistoryCard(Map<String, dynamic> anime) {
    return GestureDetector(
      onTap: () {
         if (anime['last_watched_episode_slug'] != null) {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeEpisodePage(episodeSlug: anime['last_watched_episode_slug'], animeSlug: anime['slug'], animeTitle: anime['title'], animePoster: anime['poster'], onHistoryUpdate: refreshHistory))).then((_) => refreshHistory());
         } else {
            Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeDetailPage(slug: anime['slug'], onHistoryUpdate: refreshHistory))).then((_) => refreshHistory());
         }
      },
      child: Container(
        width: 120, margin: const EdgeInsets.only(right: 12),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(anime['poster'], height: 160, width: 120, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 160, width: 120, color: kCardColor, child: const Icon(Icons.image_not_supported, color: Colors.grey))),
            ),
            const SizedBox(height: 8),
            Text(anime['title'], style: const TextStyle(color: kMutedWhite, fontSize: 12, fontFamily: "Rajdhani"), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (searchResults.isEmpty) return Center(child: Text("No results", style: TextStyle(color: Colors.grey, fontFamily: "Rajdhani")));
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: searchResults.length,
      itemBuilder: (context, index) {
        final anime = searchResults[index];
        return Card(
          color: kCardColor,
          child: ListTile(
            leading: Image.network(anime['poster'], width: 50, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 50, color: kHighlightColor)),
            title: Text(anime['title'], style: const TextStyle(color: kMutedWhite, fontFamily: "Rajdhani")),
            onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeDetailPage(slug: anime['animeId'], onHistoryUpdate: refreshHistory))).then((_) => refreshHistory()); },
          ),
        );
      },
    );
  }

  Widget _buildAnimeGrid(List<dynamic> list) {
    return GridView.builder(
      itemCount: list.length, physics: const NeverScrollableScrollPhysics(), shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 260, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemBuilder: (context, index) {
        final anime = list[index];
        return GestureDetector(
          onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeDetailPage(slug: anime['animeId'], onHistoryUpdate: refreshHistory))).then((_) => refreshHistory()); },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(anime['poster'], height: 170, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 170, color: kCardColor)),
              ),
              Padding(padding: const EdgeInsets.all(4), child: Text(anime['title'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kMutedWhite, fontFamily: "Rajdhani"), maxLines: 2, overflow: TextOverflow.ellipsis)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingShimmer() {
    return GridView.builder(
      itemCount: 8, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisExtent: 260, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemBuilder: (_, __) => Shimmer.fromColors(baseColor: kCardColor, highlightColor: kHighlightColor, child: Container(decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(4)))),
    );
  }

  Widget _buildQuickAccessCard(String title, IconData icon, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: kCardColor, borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: kMutedWhite, size: 32),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: kMutedWhite, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: "Rajdhani")),
            ],
          ),
        ),
      ),
    );
  }
}

// Detail Page (Simple & Clean)
class AnimeDetailPage extends StatefulWidget {
  final String slug;
  final Function()? onHistoryUpdate;
  const AnimeDetailPage({super.key, required this.slug, this.onHistoryUpdate});
  @override
  State<AnimeDetailPage> createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  Map<String, dynamic>? data;
  bool isLoading = true;
  
  @override void initState() { super.initState(); fetch(); }
  
  Future<void> fetch() async {
    try {
      final res = await http.get(Uri.parse('https://www.sankavollerei.com/anime/anime/${widget.slug}'));
      if(res.statusCode == 200) {
        setState(() { data = json.decode(res.body)['data']; isLoading = false; });
      } else { setState(() => isLoading = false); }
    } catch(e) { setState(() => isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(backgroundColor: kBackgroundColor, iconTheme: const IconThemeData(color: kMutedWhite), title: Text(data?['title'] ?? "Details", style: TextStyle(color: kMutedWhite, fontFamily: "Rajdhani"))),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
        : data == null 
          ? const Center(child: Text("Error", style: TextStyle(color: Colors.grey, fontFamily: "Rajdhani")))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(data!['poster'], height: 200, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(height: 200, color: kCardColor)),
                  const SizedBox(height: 16),
                  Text(data!['title'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kMutedWhite, fontFamily: "Rajdhani")),
                  const SizedBox(height: 10),
                  Text(data!['synopsis']?['paragraphs']?.join('\n\n') ?? 'No synopsis.', style: const TextStyle(color: Colors.white70, fontFamily: "Rajdhani")),
                  const SizedBox(height: 20),
                  const Text("Episodes", style: TextStyle(color: kMutedWhite, fontWeight: FontWeight.bold, fontFamily: "Rajdhani")),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                    itemCount: (data!['episodeList'] as List?)?.length ?? 0,
                    itemBuilder: (context, index) {
                      final eps = data!['episodeList'][index];
                      return Card(
                        color: kCardColor,
                        child: ListTile(
                          title: Text(eps['title'], style: const TextStyle(color: Colors.white, fontFamily: "Rajdhani")),
                          trailing: const Icon(Icons.play_arrow, color: kMutedWhite),
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => AnimeEpisodePage(
                              episodeSlug: eps['episodeId'], 
                              animeSlug: widget.slug, 
                              animeTitle: data!['title'], 
                              animePoster: data!['poster'],
                              episodes: data!['episodeList'],
                              onHistoryUpdate: widget.onHistoryUpdate
                            ))).then((_) { if(widget.onHistoryUpdate != null) widget.onHistoryUpdate!(); });
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}

// Episode Page (WebView)
class AnimeEpisodePage extends StatefulWidget {
  final String episodeSlug;
  final String? animeSlug;
  final String? animeTitle;
  final String? animePoster;
  final List<dynamic>? episodes;
  final Function()? onHistoryUpdate;

  const AnimeEpisodePage({super.key, required this.episodeSlug, this.animeSlug, this.animeTitle, this.animePoster, this.episodes, this.onHistoryUpdate});
  @override
  State<AnimeEpisodePage> createState() => _AnimeEpisodePageState();
}

class _AnimeEpisodePageState extends State<AnimeEpisodePage> {
  late WebViewController _controller;
  String? streamUrl;
  bool isLoading = true;
  
  @override void initState() { super.initState(); load(); _saveHistory(); }
  
  Future<void> load() async {
    try {
      final res = await http.get(Uri.parse('https://www.sankavollerei.com/anime/episode/${widget.episodeSlug}'));
      if(res.statusCode == 200) {
        final json = jsonDecode(res.body);
        final serverId = json['data']['server']['qualities'][0]['serverList'][0]['serverId'];
        final streamRes = await http.get(Uri.parse('https://www.sankavollerei.com/anime/server/$serverId'));
        if(streamRes.statusCode == 200) {
           setState(() { 
             streamUrl = jsonDecode(streamRes.body)['data']['url']; 
             isLoading = false; 
           });
           _initWeb();
        }
      }
    } catch(e) { setState(() => isLoading = false); }
  }
  
  void _initWeb() {
    if(streamUrl == null) return;
    _controller = WebViewController()..loadRequest(Uri.parse(streamUrl!));
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('watch_history') ?? [];
      final item = jsonEncode({
        'slug': widget.animeSlug, 'title': widget.animeTitle, 'poster': widget.animePoster, 
        'last_watched_episode_slug': widget.episodeSlug, 'last_watched_episode': 'Last watched',
        'timestamp': DateTime.now().millisecondsSinceEpoch
      });
      list.insert(0, item);
      await prefs.setStringList('watch_history', list);
      if(widget.onHistoryUpdate != null) widget.onHistoryUpdate!();
    } catch(e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(backgroundColor: kBackgroundColor, iconTheme: const IconThemeData(color: kMutedWhite), title: Text("Player", style: TextStyle(color: kMutedWhite, fontFamily: "Rajdhani"))),
      body: isLoading 
        ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
        : streamUrl == null 
          ? const Center(child: Text("Failed", style: TextStyle(color: Colors.grey, fontFamily: "Rajdhani")))
          : WebViewWidget(controller: _controller),
    );
  }
}

// Simple Placeholders for Genre/Schedule
class AnimeGenreListPage extends StatelessWidget {
  const AnimeGenreListPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: kBackgroundColor, appBar: AppBar(backgroundColor: kBackgroundColor, iconTheme: const IconThemeData(color: kMutedWhite), title: const Text("Genres", style: TextStyle(color: kMutedWhite, fontFamily: "Rajdhani"))), body: const Center(child: Text("Genre List", style: TextStyle(color: Colors.grey, fontFamily: "Rajdhani"))));
}

class AnimeSchedulePage extends StatelessWidget {
  const AnimeSchedulePage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: kBackgroundColor, appBar: AppBar(backgroundColor: kBackgroundColor, iconTheme: const IconThemeData(color: kMutedWhite), title: const Text("Schedule", style: TextStyle(color: kMutedWhite, fontFamily: "Rajdhani"))), body: const Center(child: Text("Schedule", style: TextStyle(color: Colors.grey, fontFamily: "Rajdhani"))));
}

class AnimeGenrePage extends StatelessWidget {
  final String genreSlug;
  final String genreName;
  const AnimeGenrePage({super.key, required this.genreSlug, required this.genreName});
  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: kBackgroundColor, appBar: AppBar(backgroundColor: kBackgroundColor, iconTheme: const IconThemeData(color: kMutedWhite), title: Text(genreName, style: TextStyle(color: kMutedWhite, fontFamily: "Rajdhani"))), body: Center(child: Text(genreName, style: TextStyle(color: Colors.grey, fontFamily: "Rajdhani"))));
}