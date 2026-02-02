import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers.dart';
import '../core/design_system.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _msgCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final ws = ref.read(wsServiceProvider);
    final chatStream = ref.watch(wsServiceProvider).chatStream;

    return Scaffold(
      appBar: AppBar(title: const Text('Internal Chat')),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<Map<String, dynamic>>(
            stream: chatStream,
            builder: (context, snap) {
              final items = snap.hasData ? [snap.data!] : [];
              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: items.length,
                itemBuilder: (context, idx) {
                  final it = items[idx];
                  final fromMe = (it['from'] ?? '') == 'me';
                  return Align(
                    alignment: fromMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: fromMe ? DesignSystem.primaryBlue : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: DesignSystem.alpha(Colors.black, 0.03), blurRadius: 6, offset: const Offset(0, 4))],
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        if (!fromMe) Text(it['from'] ?? '', style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                        const SizedBox(height: 4),
                        Text(it['message'] ?? '', style: TextStyle(color: fromMe ? Colors.white : DesignSystem.darkText)),
                      ]),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: DesignSystem.alpha(Colors.black, 0.03), blurRadius: 6)]),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(controller: _msgCtrl, decoration: const InputDecoration(border: InputBorder.none, hintText: 'Type a message')),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(color: DesignSystem.primaryBlue, borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                color: Colors.white,
                onPressed: () {
                  final text = _msgCtrl.text.trim();
                  if (text.isNotEmpty) {
                    ws.sendChat('general', 'me', text);
                    _msgCtrl.clear();
                  }
                },
                icon: const Icon(Icons.send),
              ),
            )
          ]),
        )
      ]),
    );
  }
}
