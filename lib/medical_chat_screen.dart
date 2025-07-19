import 'package:flutter/material.dart';
import 'gaza_medical_service.dart';
import 'package:cactus/cactus.dart';
import 'screens/document_upload_screen.dart';

class MedicalChatScreen extends StatefulWidget {
  final GazaMedicalService medicalService;

  const MedicalChatScreen({super.key, required this.medicalService});

  @override
  State<MedicalChatScreen> createState() => _MedicalChatScreenState();
}

class _MedicalChatScreenState extends State<MedicalChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showQuickQueries = true;

  @override
  void initState() {
    super.initState();
    widget.medicalService.messages.addListener(_scrollToBottom);
  }

  @override
  void dispose() {
    widget.medicalService.messages.removeListener(_scrollToBottom);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? predefinedText]) {
    final text = predefinedText ?? _controller.text.trim();
    if (text.isEmpty) return;

    widget.medicalService.sendMedicalQuery(text);
    _controller.clear();
    setState(() => _showQuickQueries = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.medical_services, color: Colors.red),
            SizedBox(width: 8),
            Text('Gaza Medical Assistant'),
          ],
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DocumentUploadScreen()),
              );
            },
            tooltip: 'Upload Medical Documents',
          ),

          ValueListenableBuilder<List<ChatMessage>>(
            valueListenable: widget.medicalService.messages,
            builder: (context, messages, _) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed:
                    messages.length <= 1
                        ? null
                        : () {
                          widget.medicalService.clearConversation();
                          setState(() => _showQuickQueries = true);
                        },
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<String?>(
        valueListenable: widget.medicalService.error,
        builder: (context, error, _) {
          if (error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Medical Assistant Error',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => widget.medicalService.initialize(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ValueListenableBuilder<bool>(
            valueListenable: widget.medicalService.isLoading,
            builder: (context, isLoading, _) {
              return ValueListenableBuilder<List<ChatMessage>>(
                valueListenable: widget.medicalService.messages,
                builder: (context, messages, _) {
                  if (isLoading && messages.isEmpty) {
                    return ValueListenableBuilder<String>(
                      valueListenable: widget.medicalService.status,
                      builder: (context, status, _) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.green,
                              ),
                              const SizedBox(height: 16),
                              const Icon(
                                Icons.medical_services,
                                size: 48,
                                color: Colors.green,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                status,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(8),
                          itemCount:
                              messages.length + (_showQuickQueries ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_showQuickQueries && index == messages.length) {
                              return _buildQuickQueries();
                            }
                            return _buildMessageBubble(messages[index]);
                          },
                        ),
                      ),
                      _buildInputArea(isLoading),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: ValueListenableBuilder<String?>(
        valueListenable: widget.medicalService.error,
        builder: (context, error, _) {
          return ValueListenableBuilder<bool>(
            valueListenable: widget.medicalService.isLoading,
            builder: (context, isLoading, _) {
              return ValueListenableBuilder<List<ChatMessage>>(
                valueListenable: widget.medicalService.messages,
                builder: (context, messages, _) {
                  // Hide FAB during initial loading or error states
                  if (error != null || (isLoading && messages.isEmpty)) {
                    return const SizedBox.shrink();
                  }

                  return FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DocumentUploadScreen(),
                        ),
                      );
                    },
                    backgroundColor: Colors.blue,
                    tooltip: 'Upload Medical Documents',
                    child: const Icon(Icons.add_circle, color: Colors.white),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.green[100] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: isUser ? null : Border.all(color: Colors.red[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser)
              Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    size: 16,
                    color: Colors.red[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Medical Assistant',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            if (!isUser) const SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.green[800] : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickQueries() {
    final queries = widget.medicalService.getQuickMedicalQueries();

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue[600]),
              const SizedBox(width: 8),
              Text(
                'Common Medical Questions',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...queries.map(
            (query) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: InkWell(
                onTap: () => _sendMessage(query),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[300]!),
                  ),
                  child: Text(query, style: TextStyle(color: Colors.blue[700])),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Describe your medical concern...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => isLoading ? null : _sendMessage(),
              enabled: !isLoading,
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.green[600],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon:
                  isLoading
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.send, color: Colors.white),
              onPressed: isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
