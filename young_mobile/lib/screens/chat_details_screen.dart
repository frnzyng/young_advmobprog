import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:young_advmobprog/services/chat_service.dart';
import 'package:young_advmobprog/services/user_service.dart';
import 'package:young_advmobprog/widgets/custom_text.dart';

final ChatService chatService = ChatService(); // This line likely belongs outside of any class or at the top level

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;
  bool _isSending = false;
  Timestamp? _sendingStartedAt;

  static const _postSendDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    final userData = await userService.value.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _sendingStartedAt = Timestamp.now();
    });

    try {
      await chatService.sendMessage(receiverId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }

      await Future.delayed(_postSendDelay);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingStartedAt = null;
        });
      }
    }
  }

  void _markMessagesAsSeen(String currentUserId, String otherUserId, List<QueryDocumentSnapshot> docs) {
    // Construct the chat room ID the same way ChatService does
    List<String> ids = [currentUserId, otherUserId];
    ids.sort();
    String chatRoomID = ids.join('_');

    // Find all messages sent by the 'otherUserID' that are NOT yet 'seen'
    final messagesToUpdate = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['senderId'] == otherUserId && data['status'] != 'seen';
    }).toList();

    if (messagesToUpdate.isEmpty) return;

    // Perform batched writes for efficiency
    final batch = chatService.firestoreInstance.batch(); // Assuming ChatService._firestore is accessible
    
    for (var doc in messagesToUpdate) {
      DocumentReference docRef = chatService.firestoreInstance
          .collection("chat_rooms")
          .doc(chatRoomID)
          .collection("messages")
          .doc(doc.id);
      
      batch.update(docRef, {'status': 'seen'});
    }

    // Commit the batch update to Firestore
    batch.commit().catchError((e) {
      print("Error updating message status: $e");
    });
  }


  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName = (widget.tappedUser['firstName'] ?? '').toString();

    print('Tapped user ID: $tappedUserId');

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            elevation: 1,
            centerTitle: true,
            title: CustomText(text: tappedUserName, fontSize: 25.sp),
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading messages: ${snapshot.error}'),
                      );
                    }

                    List<QueryDocumentSnapshot> docs =
                        snapshot.data?.docs ?? [];

                    // hide my just-sent messages until delay completes
                    if (_isSending && _sendingStartedAt != null) {
                      docs = docs.where((d) {
                        final data = d.data() as Map<String, dynamic>;
                        final senderId = (data['senderId'] ?? '').toString();
                        final ts = data['timestamp'];

                        if (senderId != currentUserId) return true;

                        if (ts is Timestamp) {
                          return ts.compareTo(_sendingStartedAt!) < 0;
                        }

                        return true;
                      }).toList();
                    }

                    if (docs.isEmpty) {
                      return const Center(child: Text('No messages yet'));
                    }

                    _markMessagesAsSeen(currentUserId, tappedUserId, docs);

                    return ListView.builder(
                      reverse: true,
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data =
                            docs[index].data() as Map<String, dynamic>;
                        final msgText = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;
                        final status = data['status'] ?? 'sent';


                        return Align(
                          alignment:
                              isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75,
                                ),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withOpacity(0.5)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12).copyWith(
                                    bottomLeft: isMe
                                        ? const Radius.circular(12)
                                        : Radius.zero,
                                    bottomRight: isMe
                                        ? Radius.zero
                                        : const Radius.circular(12),
                                  ),
                                ),
                          
                                child: CustomText(
                                  text: msgText.isNotEmpty ? msgText : "[empty]",
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.normal,
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              // Show status
                              if (isMe) 
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: CustomText(
                                    text: status == 'seen' ? 'seen' : 'sent',
                                  ),
                                ),
                            ]
                          ),
                        );
                      },
                    );
                  }, 
                ), 
              ), 
              
              // Message Input Field
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _msgCtrl,
                        focusNode: _msgFocus,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 10.h,
                          ),
                        ),
                        onSubmitted: (_) {

                          _send(currentUserId, tappedUserId); 
                        },
                      ),
                    ),
                    SizedBox(width: 8.w),

                      IconButton(
                        icon: (_isSending)
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                ),
                              )
                            : Icon(
                                Icons.send,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        onPressed: (_isSending) 
                            ? null 
                            : () => _send(currentUserId, tappedUserId), // Call _send function on tap
                      ),
                    
                  ],
                ),
              ),
              SizedBox(height: 20.h),
            ], 
          ), 
        ); 
      }, 
    );
  } 
} 