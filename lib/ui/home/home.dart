import 'package:flutter/material.dart';
import 'package:music_app/ui/login/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../home/viewmodel.dart';
import '../../data/model/song.dart';
import '../now_playing/playing.dart';
import '../favorite/favorite.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = "";
  String filterType = "Tất cả";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<SongViewModel>().listenToSongs();
        context.read<SongViewModel>().listenToFavorites();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SongViewModel>();

    return Scaffold(
      backgroundColor: const Color(0xFF2A2AFF), // 🎨 Màu nền đồng bộ với Login
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(FontAwesomeIcons.music, color: Colors.white, size: 24),
            SizedBox(width: 8),
            Text(
              "Music Library",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: "Thêm bài hát mới",
            onPressed: () => _showAddSongDialog(context, viewModel),
          ),
          IconButton(
            icon: const Icon(Icons.favorite, color: Colors.pinkAccent),
            tooltip: "Danh sách yêu thích",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FavoritePage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: "Đăng xuất",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            // 🔍 Thanh tìm kiếm + bộ lọc
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Tìm kiếm bài hát, YouTube hoặc MP3...",
                        hintStyle: TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onChanged: (value) {
                        setState(() => searchQuery = value.toLowerCase());
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  dropdownColor: const Color(0xFF2A2AFF),
                  style: const TextStyle(color: Colors.white),
                  value: filterType,
                  items: const [
                    DropdownMenuItem(value: "Tất cả", child: Text("Tất cả")),
                    DropdownMenuItem(value: "YouTube", child: Text("YouTube")),
                    DropdownMenuItem(value: "MP3", child: Text("MP3")),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => filterType = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 📜 Danh sách bài hát
            Expanded(
              child: StreamBuilder<List<Song>>(
                stream: viewModel.songStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (snapshot.hasError) {
                    return Center(
                        child: Text("❌ Lỗi: ${snapshot.error}",
                            style: const TextStyle(color: Colors.white)));
                  }

                  final allSongs = snapshot.data ?? [];
                  final songs = allSongs.where((song) {
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

                  if (songs.isEmpty) {
                    return const Center(
                      child: Text("🎶 Không tìm thấy bài hát nào",
                          style: TextStyle(color: Colors.white70)),
                    );
                  }

                  return ListView.builder(
                    itemCount: songs.length,
                    itemBuilder: (context, index) {
                      final song = songs[index];
                      final isFav = viewModel.isFavorite(song.id);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              song.image.isNotEmpty
                                  ? song.image
                                  : "assets/itunes_256.png",
                              width: 55,
                              height: 55,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  Image.asset('assets/itunes_256.png'),
                            ),
                          ),
                          title: Text(song.title,
                              style: const TextStyle(
                                  color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text("${song.artist} • ${song.album}",
                              style: const TextStyle(color: Colors.white70)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.white70,
                                ),
                                onPressed: () {
                                  if (isFav) {
                                    viewModel.removeFromFavorites(song.id);
                                  } else {
                                    viewModel.addToFavorites(song);
                                  }
                                },
                              ),
                              PopupMenuButton<String>(
                                color: const Color(0xFF2A2AFF),
                                icon: const Icon(Icons.more_vert, color: Colors.white),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showAddSongDialog(context, viewModel, song: song);
                                  } else if (value == 'delete') {
                                    viewModel.deleteSong(song.id);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'edit', child: Text('✏️ Sửa', style: TextStyle(color: Colors.white))),
                                  PopupMenuItem(value: 'delete', child: Text('🗑️ Xóa', style: TextStyle(color: Colors.white))),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NowPlaying(
                                songs: songs,
                                playingSong: song,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🧱 Form thêm/sửa bài hát
  void _showAddSongDialog(BuildContext context, SongViewModel viewModel,
      {Song? song}) {
    final titleController = TextEditingController(text: song?.title ?? "");
    final albumController = TextEditingController(text: song?.album ?? "");
    final artistController = TextEditingController(text: song?.artist ?? "");
    final sourceController = TextEditingController(text: song?.source ?? "");
    final imageController = TextEditingController(text: song?.image ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2AFF),
        title: Text(
          song == null ? "➕ Thêm bài hát" : "✏️ Cập nhật bài hát",
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              _buildTextField("🎵 Tiêu đề", titleController),
              _buildTextField("💿 Album", albumController),
              _buildTextField("🎤 Nghệ sĩ", artistController),
              _buildTextField("🔗 Link nhạc (MP3 / YouTube)", sourceController),
              _buildTextField("🖼️ Ảnh (tùy chọn)", imageController),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white),
            onPressed: () async {
              if (titleController.text.trim().isEmpty ||
                  sourceController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("⚠️ Vui lòng nhập tiêu đề và link nhạc!")),
                );
                return;
              }

              await viewModel.addOrUpdateSong(
                id: song?.id,
                title: titleController.text.trim(),
                album: albumController.text.trim(),
                artist: artistController.text.trim(),
                source: sourceController.text.trim(),
                image: imageController.text.trim(),
              );

              if (context.mounted) Navigator.pop(context);
            },
            child: Text(song == null ? "Thêm" : "Cập nhật",
                style: const TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
          focusedBorder:
              const OutlineInputBorder(borderSide: BorderSide(color: Colors.white)),
        ),
      ),
    );
  }
}
