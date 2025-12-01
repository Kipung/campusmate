import 'package:flutter/material.dart';
import 'package:campusmate/widgets/general/chatscr_top_bar.dart';
import 'package:campusmate/widgets/general/chatscr_textbar.dart';
import 'package:campusmate/widgets/general/chatscr_usrtextbbl.dart';
import 'package:campusmate/widgets/general/chatscr_opptextbbl.dart';
import 'package:campusmate/db_helpers/db_chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  // Add name cache
  final Map<String, String> _nameCache = {};

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ChatscrTopBar(),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: DbChat.listenMessages(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 8,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final text = (data['text'] as String?) ?? '';
                    final imageUrl = (data['image_url'] as String?) ?? '';
                    final fileUrl = (data['file_url'] as String?) ?? '';
                    final fileName = (data['file_name'] as String?) ?? '';
                    final fileSize = (data['file_size'] as int?) ?? 0;

                    // Determine message alignment and bubble type
                    final senderId = data['sender_id'] as String?;
                    final currentUid = DbChat.currentUid;
                    final isMine =
                        senderId != null &&
                        currentUid != null &&
                        senderId == currentUid;

                    String name = senderId ?? '';
                    // Fetch and cache sender's name
                    if (senderId != null &&
                        !isMine &&
                        !_nameCache.containsKey(senderId)) {
                      // If not cached
                      FirebaseFirestore
                          .instance // Fetch from Firestore
                          .collection('user_profiles')
                          .doc(senderId)
                          .get()
                          .then((snap) {
                            // Snap contains user data
                            final profile = snap.data();
                            // First name and last name extraction
                            final firstName =
                                (profile != null &&
                                    profile['first_name'] != null)
                                ? profile['first_name'] as String
                                : 'Unknown';
                            final lastName =
                                (profile != null &&
                                    profile['last_name'] != null)
                                ? profile['last_name'] as String
                                : '';
                            // Combine to full name
                            final fullName = '$firstName $lastName'.trim();
                            // If full name is empty, fallback to display name or senderId
                            final fetched = fullName.isNotEmpty
                                ? fullName
                                : (profile?['display_name'] as String?) ??
                                      senderId;
                            if (mounted) {
                              setState(() {
                                _nameCache[senderId] = fetched;
                              });
                            }
                          });
                    }
                    name = _nameCache[senderId] ?? name;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        mainAxisAlignment: isMine
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // If sender is the current user, show UsrTextBubble
                          if (isMine)
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (imageUrl.isNotEmpty)
                                    _ImageBubble(
                                      url: imageUrl,
                                      isMine: true,
                                    ),
                                  if (fileUrl.isNotEmpty)
                                    _FileBubble(
                                      url: fileUrl,
                                      name: fileName,
                                      sizeBytes: fileSize,
                                      isMine: true,
                                    ),
                                  if (text.isNotEmpty)
                                    UsrTextBubble(displayedText: text),
                                ],
                              ),
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                if (imageUrl.isNotEmpty)
                                  _ImageBubble(url: imageUrl, isMine: false),
                                if (fileUrl.isNotEmpty)
                                  _FileBubble(
                                    url: fileUrl,
                                    name: fileName,
                                    sizeBytes: fileSize,
                                    isMine: false,
                                  ),
                                if (text.isNotEmpty)
                                  OppTextBubble(displayedText: text),
                              ],
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ChatscrTextbar(
            onSend: (msg) async {
              final text = msg.trim();
              if (text.isEmpty) return;
              try {
                await DbChat.sendMessageText(widget.chatId, text);
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
              }
            },
            onPickImage: () async {
              try {
                final picked = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 75,
                  maxWidth: 1600,
                );
                if (picked == null) return;
                await DbChat.sendMessageImage(widget.chatId, picked);
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(content: Text('Failed to send image: $e')),
                );
              }
            },
            onPickFile: () async {
              try {
                final result = await FilePicker.platform.pickFiles(
                  allowMultiple: false,
                  withData: true, // ensures bytes available on web/desktop
                );
                if (result == null || result.files.isEmpty) return;
                await DbChat.sendMessageFile(widget.chatId, result.files.single);
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(
                  SnackBar(content: Text('Failed to send file: $e')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ImageBubble extends StatelessWidget {
  final String url;
  final bool isMine;

  const _ImageBubble({required this.url, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(10);
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.6,
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isMine ? const Color(0xFF2D2F22) : const Color(0xFFD5C7AD),
        borderRadius: borderRadius,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: 150,
              child: Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stack) => SizedBox(
            height: 150,
            child: Center(
              child: Icon(
                Icons.broken_image,
                color: isMine ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FileBubble extends StatelessWidget {
  final String url;
  final String name;
  final int sizeBytes;
  final bool isMine;

  const _FileBubble({
    required this.url,
    required this.name,
    required this.sizeBytes,
    required this.isMine,
  });

  String _formatSize(int bytes) {
    if (bytes <= 0) return '';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int unitIndex = 0;
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    return '${size.toStringAsFixed(size < 10 && unitIndex > 0 ? 1 : 0)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(10);
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.7,
      ),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isMine ? const Color(0xFF2D2F22) : const Color(0xFFD5C7AD),
        borderRadius: borderRadius,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: url));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Download link copied')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insert_drive_file,
                  color: isMine ? Colors.white70 : Colors.black87,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isNotEmpty ? name : 'Attachment',
                        style: TextStyle(
                          color: isMine ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (sizeBytes > 0)
                        Text(
                          _formatSize(sizeBytes),
                          style: TextStyle(
                            color: isMine ? Colors.white70 : Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.download,
                  color: isMine ? Colors.white70 : Colors.black54,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
