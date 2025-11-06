import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../home/viewmodel.dart';
import '../now_playing/playing.dart';
import '../home/home.dart'; // ✅ để điều hướng về trang Home

class FavoritePage extends StatefulWidget {
  const FavoritePage({super.key});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  String searchQuery = "";
  String filterType = "Tất cả";

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SongViewModel>();
    final favorites = viewModel.favorites;

    final filteredSongs = favorites.where((song) {
      final query = searchQuery.toLowerCase();
      final matchesSearch = song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query) ||
          song.album.toLowerCase().contains(query) ||
          song.source.toLowerCase().contains(query);

      final isYouTube = song.source.contains("youtube.com") ||
          song.source.contains("youtu.be");
      final isMp3 = song.source.endsWith(".mp3");

      if (filterType == "YouTube" && !isYouTube) return false;
      if (filterType == "MP3" && !isMp3) return false;

      return matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF1E3AFF), // 🔵 Nền xanh đồng bộ Figma
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "❤️ Danh sách yêu thích",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          },
        ),
      ),

      // 📦 Nội dung chính
      body: Column(
        children: [
          // 🔍 Thanh tìm kiếm + lọc
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Tìm kiếm bài hát...",
                      hintStyle: const TextStyle(color: Colors.white70),
                      prefixIcon:
                          const Icon(Icons.search, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.white54, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Colors.white, width: 1.5),
                      ),
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white54),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: filterType,
                      dropdownColor: Colors.indigo[700],
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.white),
                      style: const TextStyle(color: Colors.white),
                      items: const [
                        DropdownMenuItem(
                            value: "Tất cả", child: Text("Tất cả")),
                        DropdownMenuItem(
                            value: "YouTube", child: Text("YouTube")),
                        DropdownMenuItem(value: "MP3", child: Text("MP3")),
                      ],
                      onChanged: (value) =>
                          setState(() => filterType = value ?? "Tất cả"),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🎵 Danh sách bài hát
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: filteredSongs.isEmpty
                  ? const Center(
                      child: Text(
                        "🎶 Không có bài hát yêu thích nào phù hợp",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredSongs.length,
                      itemBuilder: (context, index) {
                        final song = filteredSongs[index];
                        return Card(
                          color: Colors.white.withOpacity(0.15),
                          margin: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song.image.isNotEmpty
                                    ? song.image
                                    : "assets/itunes_256.png",
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/itunes_256.png',
                                    width: 60,
                                    height: 60),
                              ),
                            ),
                            title: Text(
                              song.title,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              song.artist.isNotEmpty
                                  ? song.artist
                                  : "Không rõ nghệ sĩ",
                              style: const TextStyle(color: Colors.white70),
                            ),
                            trailing: IconButton(
                              icon: const Icon(LucideIcons.heart,
                                  color: Colors.redAccent),
                              onPressed: () => viewModel.toggleFavorite(song),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NowPlaying(
                                    songs: filteredSongs,
                                    playingSong: song,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
