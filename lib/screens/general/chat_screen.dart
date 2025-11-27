import 'package:flutter/material.dart';
import 'package:campusmate/widgets/general/chatscr_top_bar.dart';
import 'package:campusmate/widgets/general/chatscr_textbar.dart';
import 'package:campusmate/widgets/general/chatscr_usrtextbbl.dart';
import 'package:campusmate/widgets/general/chatscr_opptextbbl.dart';
import 'package:campusmate/db_helpers/db_chat.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  const ChatScreen({super.key, required this.chatId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
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
                            Flexible(child: UsrTextBubble(displayedText: text))
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
          ),
        ],
      ),
    );
  }
}
